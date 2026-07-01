import Foundation
import AppKit

class ActivityTracker: IdleDetectorDelegate {
    private let appState: AppState
    private let idleDetector = IdleDetector()
    private var activeAppObserver: NSObjectProtocol?
    private var scoringTimer: Timer?
    private var currentActiveApp: NSRunningApplication?
    
    init(appState: AppState) {
        self.appState = appState
        self.idleDetector.delegate = self
        self.appState.setupTracker(self)
    }
    
    func start() {
        idleDetector.start()
        setupAppSwitchObserver()
        trackCurrentActiveApp()
        
        // Setup periodic focus score recalculation every 30 seconds
        scoringTimer?.invalidate()
        scoringTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.recalculateFocusScore()
        }
        
        // Run initial calculation
        recalculateFocusScore()
        
        print("ActivityTracker: Started tracking activity")
    }
    
    func stop() {
        idleDetector.stop()
        scoringTimer?.invalidate()
        scoringTimer = nil
        
        if let observer = activeAppObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            activeAppObserver = nil
        }
        print("ActivityTracker: Stopped tracking activity")
    }
    
    private func setupAppSwitchObserver() {
        activeAppObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAppSwitch(notification)
        }
    }
    
    private func trackCurrentActiveApp() {
        if let frontApp = NSWorkspace.shared.frontmostApplication {
            currentActiveApp = frontApp
            updateActiveApp(frontApp)
        }
    }
    
    private func handleAppSwitch(_ notification: Notification) {
        guard appState.isTracking else { return }
        if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
            currentActiveApp = app
            // Only update active app if we are not idle
            if !appState.isIdle {
                updateActiveApp(app)
            }
        }
    }
    
    private func updateActiveApp(_ app: NSRunningApplication) {
        let appName = app.localizedName ?? "Unknown"
        let bundleID = app.bundleIdentifier ?? "Unknown"
        var windowTitle = getActiveWindowTitle(for: app) ?? ""
        
        // Clean browser title
        if AppCategorizer.shared.isBrowser(bundleID: bundleID) {
            windowTitle = BrowserTitleObserver.shared.cleanBrowserTitle(bundleID: bundleID, windowTitle: windowTitle)
        }
        
        // Categorize app
        let category = AppCategorizer.shared.categorize(bundleID: bundleID, windowTitle: windowTitle)
        
        DispatchQueue.main.async {
            self.appState.activeAppName = appName
            self.appState.activeBundleID = bundleID
            self.appState.activeWindowTitle = windowTitle
            self.appState.switchesCount += 1
        }
        
        // Persist activity event in database
        do {
            _ = try EventStore.shared.recordEvent(
                bundleID: bundleID,
                appName: appName,
                windowTitle: windowTitle,
                category: category
            )
            print("ActivityTracker: Recorded App Switch -> Name: \(appName), Bundle ID: \(bundleID), Category: \(category.rawValue)")
        } catch {
            print("ActivityTracker: Failed to record event: \(error)")
        }
        
        // Recalculate score immediately on switch
        recalculateFocusScore()
    }
    
    private func recordIdleState(isIdle: Bool) {
        if isIdle {
            // Record Idle event in DB
            do {
                _ = try EventStore.shared.recordEvent(
                    bundleID: "com.apple.System.Idle",
                    appName: "Idle",
                    windowTitle: nil,
                    category: .neutral
                )
                print("ActivityTracker: Recorded Idle event")
            } catch {
                print("ActivityTracker: Failed to record idle event: \(error)")
            }
            
            DispatchQueue.main.async {
                self.appState.activeAppName = "Idle"
                self.appState.activeBundleID = "com.apple.System.Idle"
                self.appState.activeWindowTitle = ""
            }
        } else {
            // Resumed - record current active app event in DB
            if let activeApp = currentActiveApp ?? NSWorkspace.shared.frontmostApplication {
                updateActiveApp(activeApp)
            }
        }
    }
    
    func recalculateFocusScore() {
        guard appState.isTracking else { return }
        
        let thirtyMinutesAgo = Date().addingTimeInterval(-30 * 60)
        do {
            let events = try EventStore.shared.fetchEvents(since: thirtyMinutesAgo)
            let result = FocusScoreEngine.shared.calculateScore(events: events)
            
            DispatchQueue.main.async {
                self.appState.focusScore = result.score
                self.appState.focusLevel = result.level.rawValue
            }
        } catch {
            print("ActivityTracker: Failed to recalculate focus score: \(error)")
        }
    }
    
    private func getActiveWindowTitle(for app: NSRunningApplication) -> String? {
        let pid = app.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)
        
        var focusedWindow: AnyObject?
        let result = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindow)
        
        guard result == .success, let windowElement = focusedWindow as! AXUIElement? else {
            return nil
        }
        
        var title: AnyObject?
        let titleResult = AXUIElementCopyAttributeValue(windowElement, kAXTitleAttribute as CFString, &title)
        
        if titleResult == .success, let titleString = title as? String {
            return titleString
        }
        
        return nil
    }
    
    // MARK: - IdleDetectorDelegate
    func idleDetector(_ detector: IdleDetector, didChangeIdleState isIdle: Bool) {
        DispatchQueue.main.async {
            self.appState.isIdle = isIdle
        }
        recordIdleState(isIdle: isIdle)
    }
}
