import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var appState: AppState?
    var activityTracker: ActivityTracker?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize AppState
        let state = AppState()
        self.appState = state
        
        // Initialize ActivityTracker
        let tracker = ActivityTracker(appState: state)
        self.activityTracker = tracker
        tracker.start()
        
        // Setup popover
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 360)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: MenuBarView(appState: state))
        self.popover = popover
        
        // Setup status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "brain.head.profile", accessibilityDescription: "FocusFlow")
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
        
        // Periodically check accessibility permission to update UI state
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            state.checkAccessibilityPermission()
        }
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
}
