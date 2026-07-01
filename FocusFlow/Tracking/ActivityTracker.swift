import Foundation
import AppKit

class ActivityTracker: IdleDetectorDelegate {
    private let appState: AppState
    private let idleDetector = IdleDetector()
    private var activeAppObserver: NSObjectProtocol?
    
    init(appState: AppState) {
        self.appState = appState
        self.idleDetector.delegate = self
        self.appState.setupTracker(self)
    }
    
    func start() {
        idleDetector.start()
        setupAppSwitchObserver()
        trackCurrentActiveApp()
        print("ActivityTracker: Started tracking activity")
    }
    
    func stop() {
        idleDetector.stop()
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
            updateActiveApp(frontApp)
        }
    }
    
    private func handleAppSwitch(_ notification: Notification) {
        guard appState.isTracking else { return }
        if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
            updateActiveApp(app)
        }
    }
    
    private func updateActiveApp(_ app: NSRunningApplication) {
        let appName = app.localizedName ?? "Unknown"
        let bundleID = app.bundleIdentifier ?? "Unknown"
        
        let windowTitle = getActiveWindowTitle(for: app) ?? ""
        
        appState.activeAppName = appName
        appState.activeBundleID = bundleID
        appState.activeWindowTitle = windowTitle
        
        // Log to console for Phase 1
        print("ActivityTracker: Active App Changed -> Name: \(appName), Bundle ID: \(bundleID), Title: '\(windowTitle)'")
        
        // For Phase 1: increment switch count
        appState.switchesCount += 1
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
        appState.isIdle = isIdle
        print("ActivityTracker: Idle State Changed -> isIdle: \(isIdle)")
    }
}
