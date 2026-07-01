# FocusFlow — Mac App Architecture & Specification

## Overview

FocusFlow is a macOS desktop app that tracks your computer activity and produces a **focus score** — a real-time measure of how well you're sustaining attention. The goal is to help people become conscious of their focus patterns and improve over time.

**Platform:** macOS 14+ (Sonoma and later)
**Language:** Swift 5.9+
**UI Framework:** SwiftUI
**Distribution:** Direct distribution (outside App Store) — this avoids App Sandbox restrictions that block accessibility APIs
**Architecture:** MVVM with a background tracking service

---

## Project Structure

```
FocusFlow/
├── FocusFlow.xcodeproj
├── FocusFlow/
│   ├── App/
│   │   ├── FocusFlowApp.swift              # App entry point, menu bar + window
│   │   ├── AppDelegate.swift               # NSApplicationDelegate for lifecycle
│   │   └── AppState.swift                  # Global app state (ObservableObject)
│   │
│   ├── Tracking/
│   │   ├── ActivityTracker.swift           # Core tracking engine (NSWorkspace, accessibility)
│   │   ├── AppSwitchDetector.swift         # Monitors active app changes
│   │   ├── IdleDetector.swift              # Detects user idle time (CGEventSource)
│   │   ├── BrowserTitleObserver.swift      # Reads browser tab titles via accessibility
│   │   └── PermissionsManager.swift        # Checks & requests accessibility permissions
│   │
│   ├── Scoring/
│   │   ├── FocusScoreEngine.swift          # Computes focus score from raw events
│   │   ├── AppCategorizer.swift            # Maps bundle IDs to categories
│   │   └── ScoringModels.swift             # Score data structures and enums
│   │
│   ├── Storage/
│   │   ├── DatabaseManager.swift           # SQLite (via GRDB.swift or SwiftData)
│   │   ├── SessionStore.swift              # CRUD for focus sessions
│   │   ├── EventStore.swift                # CRUD for raw activity events
│   │   └── Models/
│   │       ├── FocusSession.swift          # Session model
│   │       ├── ActivityEvent.swift         # Single app-switch or activity event
│   │       └── DailyScore.swift            # Aggregated daily score
│   │
│   ├── Views/
│   │   ├── MenuBar/
│   │   │   ├── MenuBarView.swift           # Menu bar icon + dropdown
│   │   │   └── MiniScoreView.swift         # Compact score display in menu bar
│   │   ├── Dashboard/
│   │   │   ├── DashboardView.swift         # Main window — today's overview
│   │   │   ├── ScoreGaugeView.swift        # Circular gauge showing current score
│   │   │   ├── TimelineView.swift          # Horizontal timeline of the day
│   │   │   └── AppBreakdownView.swift      # Time per app/category chart
│   │   ├── History/
│   │   │   ├── HistoryView.swift           # Past days/weeks/months
│   │   │   ├── TrendChartView.swift        # Score trend over time (line chart)
│   │   │   └── CalendarHeatmapView.swift   # GitHub-style focus heatmap
│   │   ├── Settings/
│   │   │   ├── SettingsView.swift          # Preferences window
│   │   │   ├── CategoryEditorView.swift    # Custom app → category mapping
│   │   │   └── GoalsView.swift             # Set daily focus goals
│   │   └── Onboarding/
│   │       ├── OnboardingView.swift        # First-launch walkthrough
│   │       └── PermissionRequestView.swift # Explains & requests permissions
│   │
│   ├── Notifications/
│   │   ├── FocusAlertManager.swift         # Nudges when focus drops
│   │   └── DailySummaryNotifier.swift      # End-of-day summary notification
│   │
│   └── Resources/
│       ├── Assets.xcassets                 # App icon, SF Symbols
│       └── DefaultCategories.json          # Default app → category mapping
│
├── FocusFlowTests/
│   ├── ScoringTests.swift
│   ├── CategorizerTests.swift
│   └── TrackerTests.swift
│
└── README.md
```

---

## Core Components — Detailed Specifications

### 1. Activity Tracking (`Tracking/`)

This is the heart of the app. It runs as a background service while the user works.

#### ActivityTracker.swift

The central coordinator that starts/stops tracking and emits `ActivityEvent` objects.

```
Responsibilities:
- Start/stop the tracking loop
- Coordinate AppSwitchDetector, IdleDetector, BrowserTitleObserver
- Emit ActivityEvent objects to EventStore
- Respect user preferences (tracking hours, paused state)
```

**Key APIs to use:**

- `NSWorkspace.shared.notificationCenter` — observe `didActivateApplicationNotification` for app switches
- `NSWorkspace.shared.frontmostApplication` — get the currently active app
- `CGEventSource.secondsSinceLastEventType(.combinedSessionState, .any)` — detect idle time

#### AppSwitchDetector.swift

```
Inputs:  NSWorkspace notifications
Outputs: Stream of (bundleID, appName, windowTitle, timestamp) tuples

Logic:
1. Subscribe to NSWorkspace.didActivateApplicationNotification
2. On each notification, capture:
   - bundleID (e.g., "com.apple.Safari")
   - localized app name
   - Window title via AXUIElement (accessibility API)
   - Timestamp
3. Emit as ActivityEvent
```

#### IdleDetector.swift

```
Poll interval: every 5 seconds
Idle threshold: 120 seconds (configurable)

Logic:
1. Every 5s, check CGEventSource.secondsSinceLastEventType
2. If idle time > threshold:
   - Mark current session segment as "idle"
   - Pause focus scoring
3. When activity resumes:
   - Record idle period duration
   - Resume scoring
```

#### BrowserTitleObserver.swift

```
Purpose: Extract the active tab's page title from browsers (Safari, Chrome, Arc, Firefox)

Approach:
1. When AppSwitchDetector reports a browser is frontmost, use AXUIElement API
2. Get the focused window → get the title attribute
3. Browser window titles typically follow "Page Title — BrowserName" format
4. Parse out the page title
5. This lets the scoring engine distinguish YouTube vs Google Docs in the same browser

Supported browsers (by bundle ID):
- com.apple.Safari
- com.google.Chrome
- company.thebrowser.Browser (Arc)
- org.mozilla.firefox
```

#### PermissionsManager.swift

```
Required permissions:
1. Accessibility (required for window titles and browser tab detection)
   - Check: AXIsProcessTrusted()
   - Request: Open System Settings → Privacy → Accessibility
2. Notifications (for focus alerts and daily summaries)
   - Check/Request: UNUserNotificationCenter

Flow:
1. On first launch, show onboarding explaining WHY each permission is needed
2. Check permissions status
3. If not granted, show step-by-step instructions with a deep link to System Settings
4. Provide a "Check Again" button
5. Gracefully degrade if accessibility is denied (track apps but not window titles)
```

---

### 2. Focus Scoring Engine (`Scoring/`)

#### FocusScoreEngine.swift

Produces a score from 0–100 based on activity patterns.

```
Inputs:
- Stream of ActivityEvent objects from the last N minutes (scoring window)
- App categories from AppCategorizer

Output:
- FocusScore (0–100)
- FocusLevel enum: .deepFocus (80–100), .focused (60–79), .moderate (40–59), .scattered (20–39), .distracted (0–19)

Scoring factors (weighted):

1. SUSTAINED ATTENTION (weight: 0.40)
   - Measures: How long you stay on a single app/task before switching
   - Longer continuous stretches = higher score
   - Formula: average_session_length / target_session_length (capped at 1.0)
   - target_session_length default: 15 minutes

2. SWITCH FREQUENCY (weight: 0.25)
   - Measures: How often you switch between apps
   - Fewer switches per hour = higher score
   - Formula: 1.0 - (switches_per_hour / max_switches_threshold)
   - max_switches_threshold default: 30 switches/hour

3. PRODUCTIVE APP RATIO (weight: 0.20)
   - Measures: Time on productive vs. distracting apps
   - Formula: productive_time / total_active_time
   - Categories: productive, neutral, distracting (user-configurable)

4. CONTEXT CONTINUITY (weight: 0.15)
   - Measures: Whether switches are between related apps (e.g., IDE → Terminal → Docs)
   - vs. unrelated switches (e.g., IDE → Twitter → YouTube → IDE)
   - Uses app category groups to determine relatedness
   - Formula: related_switches / total_switches

Scoring window: rolling 30 minutes (configurable)
Update frequency: recalculate every 30 seconds
```

#### AppCategorizer.swift

```
Purpose: Map app bundle IDs to productivity categories

Categories (enum):
- .productive      — IDE, terminal, office apps, design tools
- .communication   — Slack, email, Teams (productive but interruptive)
- .reference       — browsers on docs/Stack Overflow (contextual)
- .neutral         — system utilities, Finder, Settings
- .distracting     — social media, news, entertainment, games

Default mappings loaded from DefaultCategories.json
User can override any mapping in Settings

Browser handling:
- Default category: .neutral
- If BrowserTitleObserver is active, use title keywords to re-categorize:
  - "GitHub", "Stack Overflow", "docs" → .productive
  - "YouTube", "Reddit", "Twitter" → .distracting
  - User can add custom URL/title keyword rules
```

#### DefaultCategories.json

```json
{
  "productive": [
    "com.apple.dt.Xcode",
    "com.microsoft.VSCode",
    "com.sublimetext.*",
    "com.jetbrains.*",
    "com.apple.iWork.*",
    "com.microsoft.Word",
    "com.microsoft.Excel",
    "com.microsoft.PowerPoint",
    "com.figma.Desktop",
    "com.linear",
    "com.notion.id",
    "com.obsidian"
  ],
  "communication": [
    "com.tinyspeck.slackmacgap",
    "com.apple.mail",
    "com.microsoft.Outlook",
    "us.zoom.xos",
    "com.microsoft.teams*"
  ],
  "distracting": [
    "com.twitter.*",
    "com.facebook.*",
    "com.reddit.*",
    "com.spotify.client",
    "com.apple.Music",
    "tv.twitch.studio"
  ],
  "neutral": [
    "com.apple.finder",
    "com.apple.systempreferences",
    "com.apple.calculator",
    "com.apple.Preview"
  ]
}
```

---

### 3. Data Storage (`Storage/`)

#### Database: SQLite via GRDB.swift

Why GRDB.swift over SwiftData: lighter weight, no CloudKit dependency, full SQL control, battle-tested for this kind of time-series data.

#### Data Models

```swift
// ActivityEvent — raw tracking data
struct ActivityEvent: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var timestamp: Date
    var bundleID: String
    var appName: String
    var windowTitle: String?
    var category: AppCategory
    var durationSeconds: Double?     // filled in when the next event arrives
}

// FocusSession — a scored block of focused work
struct FocusSession: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var startTime: Date
    var endTime: Date?
    var score: Int                   // 0–100
    var level: FocusLevel
    var dominantApp: String          // app used most during this session
    var switchCount: Int
    var idleSeconds: Double
}

// DailyScore — aggregated daily summary
struct DailyScore: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var date: Date                   // calendar date (no time)
    var averageScore: Int
    var peakScore: Int
    var totalFocusedMinutes: Double  // time in .focused or .deepFocus
    var totalActiveMinutes: Double
    var totalSwitches: Int
    var topApps: [String]            // JSON-encoded top 5 apps by time
}
```

#### Data Retention

```
- Raw ActivityEvents: keep 30 days, then delete
- FocusSessions: keep 1 year
- DailyScores: keep indefinitely
- Run cleanup daily on app launch
```

---

### 4. User Interface (`Views/`)

#### Menu Bar (Primary Interface)

The app lives in the macOS menu bar. Clicking the icon shows a dropdown.

```
Menu Bar Icon: SF Symbol "brain.head.profile" or custom icon that changes color based on focus level
  - Deep Focus: green
  - Focused: blue
  - Moderate: yellow
  - Scattered: orange
  - Distracted: red

Dropdown contents:
  ┌──────────────────────────────┐
  │  Focus Score: 78  ●●●●○      │
  │  Level: Focused              │
  │  ─────────────────────────── │
  │  Session: 42 min             │
  │  Switches: 6 this hour       │
  │  ─────────────────────────── │
  │  ▸ Open Dashboard            │
  │  ▸ Pause Tracking            │
  │  ▸ Settings                  │
  │  ▸ Quit FocusFlow            │
  └──────────────────────────────┘
```

#### Dashboard Window

Opened from menu bar or Cmd+D hotkey.

```
Layout (single window, tabbed):

Tab 1: TODAY
├── Score Gauge (large circular gauge, 0–100, colored by level)
├── Timeline (horizontal bar showing the day, colored by focus level over time)
├── App Breakdown (horizontal bar chart: time per app, colored by category)
└── Stats Row: total focus time | avg score | switches | longest streak

Tab 2: HISTORY
├── Period Picker: Day / Week / Month
├── Trend Chart (line chart of daily average score over time)
├── Calendar Heatmap (GitHub-contribution-style grid, past 12 months)
└── Best/Worst Days summary

Tab 3: SETTINGS
├── General: launch at login, tracking hours (e.g., 9am–6pm), idle threshold
├── Categories: app → category editor with search
├── Goals: daily focus score target, daily focus time target
├── Notifications: enable/disable nudges, quiet hours
└── Data: export CSV, clear data
```

#### Design System

```
Colors:
  - Deep Focus:  #22C55E (green)
  - Focused:     #3B82F6 (blue)
  - Moderate:    #EAB308 (yellow)
  - Scattered:   #F97316 (orange)
  - Distracted:  #EF4444 (red)

Typography:
  - Score display: SF Pro Rounded, 48pt bold
  - Headings: SF Pro, 18pt semibold
  - Body: SF Pro, 14pt regular
  - Stats: SF Mono, 13pt

Style:
  - Clean, minimal macOS-native look
  - Use .windowToolbarStyle(.unified) for window
  - Subtle background blur effects
  - Smooth animations on score changes (withAnimation(.spring))
```

---

### 5. Notifications (`Notifications/`)

#### FocusAlertManager.swift

```
Nudge triggers:
1. Score drops below 30 for more than 5 minutes
   → "Your focus has dipped. Consider closing some tabs and returning to [dominant app]."
2. Rapid switching detected (>10 switches in 3 minutes)
   → "Lots of app switching detected. Try staying on one task for the next 15 minutes."
3. Extended distracting app use (>15 min on distracting category)
   → "You've been on [app] for a while. Ready to get back to work?"

Rules:
- Max 1 nudge per 20 minutes
- Respect Do Not Disturb / Focus Mode
- User can disable any nudge type individually
```

#### DailySummaryNotifier.swift

```
Trigger: fires at user-configured time (default: 6pm) or when tracking hours end

Content:
  "Today's Focus Score: 72 (Focused)
   4h 23m of focused work · 156 app switches
   Best streak: 47 minutes in Xcode"

Includes a "View Dashboard" action button
```

---

### 6. Onboarding Flow (`Views/Onboarding/`)

```
Step 1: Welcome
  - "FocusFlow helps you understand and improve your ability to focus."
  - Brief animation showing score concept

Step 2: Permissions
  - Explain what Accessibility permission does and why it's needed
  - "FocusFlow reads which app is active and its window title. It never reads your keystrokes, screen content, or personal data."
  - Button to open System Settings → Privacy → Accessibility
  - "Check Permission" button that verifies via AXIsProcessTrusted()

Step 3: Customize
  - Quick category review — show the default productive/distracting lists
  - Let user move apps between categories
  - Set tracking hours

Step 4: Ready
  - "You're all set. FocusFlow is now tracking in your menu bar."
  - Animate the menu bar icon appearance
```

---

## Technical Dependencies

```
Package.swift / SPM dependencies:
- GRDB.swift (SQLite wrapper)          — https://github.com/groue/GRDB.swift
- Charts (if not using SwiftUI Charts) — native in macOS 14+, use SwiftUI Charts
- LaunchAtLogin                        — https://github.com/sindresorhus/LaunchAtLogin-Modern
- KeyboardShortcuts                    — https://github.com/sindresorhus/KeyboardShortcuts
- Sparkle (for auto-updates)           — https://github.com/sparkle-project/Sparkle

System frameworks:
- ApplicationServices (AXUIElement)
- AppKit (NSWorkspace, NSStatusBar)
- SwiftUI + Charts
- UserNotifications
```

---

## Build & Distribution

```
Signing:
- Developer ID certificate (for direct distribution)
- Notarize with Apple before distributing
- Hardened runtime enabled
- Entitlements: com.apple.security.automation.apple-events (not sandboxed)

Distribution:
- DMG with drag-to-Applications installer
- Sparkle for auto-updates hosted on GitHub Releases or a static site
- No App Store (sandbox restrictions block accessibility API access)
```

---

## Implementation Order (Suggested for Claude Code)

Build in this sequence — each phase produces a working, testable app:

### Phase 1: Skeleton + Tracking (Days 1–3)
1. Create Xcode project with SwiftUI lifecycle
2. Set up menu bar app (NSStatusBar + SwiftUI popover)
3. Implement PermissionsManager — check/request Accessibility
4. Implement AppSwitchDetector using NSWorkspace notifications
5. Implement IdleDetector
6. Log events to console to verify tracking works

### Phase 2: Storage + Basic Scoring (Days 4–6)
1. Add GRDB.swift, create database schema
2. Implement EventStore — persist ActivityEvent records
3. Implement AppCategorizer with DefaultCategories.json
4. Implement FocusScoreEngine with all 4 scoring factors
5. Wire scoring to live tracking — compute score every 30 seconds
6. Show live score in menu bar popover

### Phase 3: Dashboard UI (Days 7–10)
1. Build DashboardView with Today tab
2. Implement ScoreGaugeView (circular gauge with animation)
3. Implement TimelineView (day timeline with colored segments)
4. Implement AppBreakdownView (horizontal bar chart)
5. Build History tab with TrendChartView using SwiftUI Charts
6. Build CalendarHeatmapView

### Phase 4: Browser Detection + Polish (Days 11–14)
1. Implement BrowserTitleObserver using AXUIElement
2. Add browser title → category keyword matching
3. Build Settings views (categories editor, goals, preferences)
4. Implement FocusAlertManager notifications
5. Implement DailySummaryNotifier
6. Build Onboarding flow

### Phase 5: Production Readiness (Days 15–18)
1. Add LaunchAtLogin support
2. Implement data retention cleanup
3. Add CSV export
4. Add Sparkle for auto-updates
5. Code-sign with Developer ID
6. Notarize the build
7. Create DMG installer
8. Write tests for scoring engine and categorizer

---

## Privacy Principles

```
- ALL data stays local on the user's machine (SQLite in ~/Library/Application Support/FocusFlow/)
- No network requests except update checks (Sparkle)
- No analytics or telemetry
- No keylogging — only app name, bundle ID, and window title are captured
- No screen recording or screenshots
- User can pause/stop tracking at any time
- User can delete all data from Settings
- Clear privacy explanation during onboarding
```

---

## Future Enhancements (v2+)

- Focus goals and streaks with gamification
- Weekly email digest (opt-in)
- Focus music/ambient sound integration
- Team/shared dashboards (opt-in, server-based)
- Pomodoro timer integration
- Machine learning on personal patterns to predict best focus times
- iOS companion app showing daily scores synced via iCloud
- Keyboard/mouse activity intensity as an additional scoring signal
