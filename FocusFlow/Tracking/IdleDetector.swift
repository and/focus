import Foundation
import CoreGraphics

protocol IdleDetectorDelegate: AnyObject {
    func idleDetector(_ detector: IdleDetector, didChangeIdleState isIdle: Bool)
}

class IdleDetector {
    weak var delegate: IdleDetectorDelegate?
    private var timer: Timer?
    private var isCurrentlyIdle = false
    
    var idleThreshold: TimeInterval = 120 // 2 minutes default
    
    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkIdleTime()
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkIdleTime() {
        let idleTime = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: CGEventType(rawValue: ~0)!)
        let isIdle = idleTime >= idleThreshold
        
        if isIdle != isCurrentlyIdle {
            isCurrentlyIdle = isIdle
            delegate?.idleDetector(self, didChangeIdleState: isIdle)
        }
    }
}
