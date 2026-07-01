# FocusFlow

FocusFlow is a macOS menu bar app that quietly tracks your computer activity and turns it into a **focus score** — a live 0–100 measure of how well you're sustaining attention, right now.

It watches which app you're in, how long you stay there, how often you switch, and whether you're spending time on productive vs. distracting apps, then scores you against that. The goal isn't surveillance — everything stays on your machine — it's helping you notice your own focus patterns and improve them over time.

## What it does

- **Live score in the menu bar** — your focus score sits right next to the clock, no need to open anything.
- **Dashboard** — a "Today" view (score gauge, day timeline, per-app time breakdown) and a "History" view (score trend over time, a GitHub-style focus heatmap).
- **App categorization** — apps are bucketed into productive / communication / reference / neutral / distracting, with sensible defaults and full user overrides. Browser tabs are recategorized by page title (e.g. GitHub → productive, YouTube → distracting).
- **Nudges** — a notification when your focus drops, when you're switching apps too rapidly, or when you've been on a distracting app for too long.
- **Daily summary** — an end-of-day notification recapping your focus score, focused time, and best streak.
- **Local-first** — all data is stored in a local SQLite database. No network requests, no analytics, no telemetry.

## How the score works

Every 30 seconds (and after every app switch), FocusFlow recalculates your score from four weighted signals:

1. **Sustained attention (40%)** — how long you stay on one app before switching.
2. **Switch frequency (25%)** — how often you're bouncing between apps.
3. **Productive app ratio (20%)** — time on productive/reference apps vs. distracting ones.
4. **Context continuity (15%)** — whether your switches are between related apps (IDE → Terminal → Docs) or scattered (IDE → Twitter → YouTube).

See `FocusFlow-Architecture.md` for the full spec, including data model, UI layout, and implementation status.

## Requirements

- macOS 14 (Sonoma) or later
- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Building

```sh
xcodegen generate
xcodebuild -project FocusFlow.xcodeproj -scheme FocusFlow -destination 'platform=macOS' build
```

The app requires the Accessibility permission (to read the active window title and browser tab names) and Notification permission (for nudges and the daily summary), both requested during onboarding on first launch.

## Testing

```sh
xcodebuild -project FocusFlow.xcodeproj -scheme FocusFlow -destination 'platform=macOS' test
```

## Privacy

FocusFlow only ever captures the active app's bundle ID, localized name, and window/tab title — never keystrokes, screen contents, or screenshots. All data stays local in `~/Library/Application Support/FocusFlow/` in a SQLite database. There are no network requests, no accounts, no analytics, and no telemetry anywhere in the codebase.

Because this app watches your activity, that claim shouldn't require trust — it's visible throughout the app itself:

- The menu bar dropdown always shows a "🔒 All data stays on this Mac" footer.
- Onboarding calls it out up front, before you grant any permissions.
- Settings has a **"Show Data Folder in Finder"** button so you can go look at the actual database file yourself.

You can pause tracking or delete all data at any time from Settings.
