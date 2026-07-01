import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var isTracking: Bool = true
    @Published var isIdle: Bool = false
    @Published var activeAppName: String = "None"
    @Published var activeBundleID: String = "None"
    @Published var activeWindowTitle: String = ""
    @Published var focusScore: Int = 100
    @Published var focusLevel: String = "Focused"
    @Published var sessionDurationMinutes: Int = 0
    @Published var switchesCount: Int = 0
    @Published var isAccessibilityGranted: Bool = false
    
    private var activityTracker: ActivityTracker?
    
    init() {
        checkAccessibilityPermission()
    }
    
    func checkAccessibilityPermission() {
        let granted = PermissionsManager.shared.checkAccessibilityPermission()
        if granted != isAccessibilityGranted {
            isAccessibilityGranted = granted
        }
    }
    
    func toggleTracking() {
        isTracking.toggle()
        if isTracking {
            activityTracker?.start()
        } else {
            activityTracker?.stop()
            activeAppName = "Paused"
            activeBundleID = ""
            activeWindowTitle = ""
        }
    }
    
    func setupTracker(_ tracker: ActivityTracker) {
        self.activityTracker = tracker
    }
}
