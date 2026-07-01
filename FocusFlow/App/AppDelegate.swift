import Cocoa
import SwiftUI
import Combine
import KeyboardShortcuts
import Sparkle

extension KeyboardShortcuts.Name {
    static let toggleDashboard = Self("toggleDashboard", default: .init(.d, modifiers: [.command]))
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var appState: AppState?
    var activityTracker: ActivityTracker?
    var updaterController: SPUStandardUpdaterController?

    private var dashboardWindow: NSWindow?
    private var onboardingWindow: NSWindow?
    private var statusItemCancellable: AnyCancellable?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize AppState
        let state = AppState()
        self.appState = state
        
        // Initialize ActivityTracker
        let tracker = ActivityTracker(appState: state)
        self.activityTracker = tracker
        tracker.start()
        
        // Initialize Sparkle Auto-Updater
        self.updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        
        // Setup popover
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 360)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: MenuBarView(appState: state))
        self.popover = popover
        
        // Setup status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            let image = NSImage(systemSymbolName: "brain.head.profile", accessibilityDescription: "FocusFlow")
            image?.isTemplate = true
            button.image = image
            button.imagePosition = .imageLeading
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
        updateStatusItem(score: state.focusScore, level: state.focusLevel)

        // Keep the menu bar icon + score in sync with live tracking
        statusItemCancellable = state.$focusScore
            .combineLatest(state.$focusLevel)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] score, level in
                self?.updateStatusItem(score: score, level: level)
            }
        
        // Register Global Keyboard Shortcut (Cmd+D to toggle dashboard)
        KeyboardShortcuts.onKeyUp(for: .toggleDashboard) { [weak self] in
            self?.openDashboardWindow()
        }
        
        // Run daily database cleanup in background
        DispatchQueue.global(qos: .background).async {
            do {
                try EventStore.shared.deleteEventsOlderThan(days: 30)
                try SessionStore.shared.deleteSessionsOlderThan(days: 365)
                print("AppDelegate: Database cleanup completed successfully")
            } catch {
                print("AppDelegate: Failed to run database cleanup: \(error)")
            }
        }
        
        // Schedule/Update Daily Summary Notification
        DailySummaryNotifier.shared.scheduleDailySummaryNotification()
        
        // Check Onboarding
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        if !hasCompletedOnboarding {
            openOnboardingWindow()
        }
        
        // Periodically check accessibility permission to update UI state
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            state.checkAccessibilityPermission()
        }
    }
    
    private func updateStatusItem(score: Int, level: String) {
        guard let button = statusItem?.button else { return }
        // Leave tint/color untouched so the icon and title follow the system's
        // menu bar rendering (light/dark/translucent-over-wallpaper), same as
        // every other menu bar item.
        button.contentTintColor = nil
        button.attributedTitle = NSAttributedString(
            string: " \(score)",
            attributes: [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .semibold),
                .baselineOffset: 1
            ]
        )
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem?.button, let popover = popover else { return }
        
        if popover.isShown {
            popover.close()
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
    
    @objc func openDashboardWindow() {
        if let window = dashboardWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        guard let state = appState else { return }
        
        let contentView = DashboardView(appState: state)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 550, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "FocusFlow Dashboard"
        window.contentView = NSHostingView(rootView: contentView)
        window.isReleasedWhenClosed = false
        
        self.dashboardWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func openOnboardingWindow() {
        if let window = onboardingWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let isPresentedBinding = Binding<Bool>(
            get: { true },
            set: { _ in
                self.onboardingWindow?.close()
                self.onboardingWindow = nil
            }
        )
        
        let contentView = OnboardingView(isPresented: isPresentedBinding)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 380),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "FocusFlow Onboarding"
        window.contentView = NSHostingView(rootView: contentView)
        window.isReleasedWhenClosed = false
        
        self.onboardingWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
