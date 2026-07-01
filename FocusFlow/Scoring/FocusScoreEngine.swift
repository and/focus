import Foundation

class FocusScoreEngine {
    static let shared = FocusScoreEngine()
    
    var scoringWindowMinutes: TimeInterval = 30
    var targetSessionLengthMinutes: Double = 15
    var maxSwitchesThresholdPerHour: Double = 30
    
    private init() {}
    
    func calculateScore(events: [ActivityEvent]) -> (score: Int, level: FocusLevel) {
        guard !events.isEmpty else {
            return (100, .deepFocus)
        }
        
        // We filter out events with nil duration except the last one, which we treat as active up to now.
        // Let's copy events and make sure durations are set.
        var processedEvents = events
        if !processedEvents.isEmpty && processedEvents[processedEvents.count - 1].durationSeconds == nil {
            let lastEventIndex = processedEvents.count - 1
            let timeElapsed = Date().timeIntervalSince(processedEvents[lastEventIndex].timestamp)
            processedEvents[lastEventIndex].durationSeconds = min(timeElapsed, 300) // cap unrecorded active event to 5 mins max
        }
        
        let totalDuration = processedEvents.compactMap { $0.durationSeconds }.reduce(0, +)
        guard totalDuration > 0 else {
            return (100, .deepFocus)
        }
        
        // 1. SUSTAINED ATTENTION (weight: 0.40)
        var appSessions: [Double] = []
        var currentApp = ""
        var currentAppDuration: Double = 0
        
        for event in processedEvents {
            let duration = event.durationSeconds ?? 0
            if event.bundleID == currentApp {
                currentAppDuration += duration
            } else {
                if currentAppDuration > 0 {
                    appSessions.append(currentAppDuration)
                }
                currentApp = event.bundleID
                currentAppDuration = duration
            }
        }
        if currentAppDuration > 0 {
            appSessions.append(currentAppDuration)
        }
        
        let avgSessionLength = appSessions.isEmpty ? 0 : appSessions.reduce(0, +) / Double(appSessions.count)
        let targetSessionLengthSeconds = targetSessionLengthMinutes * 60.0
        let sustainedAttentionScore = min(avgSessionLength / targetSessionLengthSeconds, 1.0)
        
        // 2. SWITCH FREQUENCY (weight: 0.25)
        let totalHours = totalDuration / 3600.0
        let switchCount = max(processedEvents.count - 1, 0)
        let switchesPerHour = totalHours > 0 ? Double(switchCount) / totalHours : 0
        let switchFrequencyScore = max(1.0 - (switchesPerHour / maxSwitchesThresholdPerHour), 0.0)
        
        // 3. PRODUCTIVE APP RATIO (weight: 0.20)
        var weightedProductiveDuration: Double = 0
        for event in processedEvents {
            let duration = event.durationSeconds ?? 0
            switch event.category {
            case .productive, .reference:
                weightedProductiveDuration += duration * 1.0
            case .communication:
                weightedProductiveDuration += duration * 0.5
            case .neutral:
                weightedProductiveDuration += duration * 0.3
            case .distracting:
                weightedProductiveDuration += duration * 0.0
            }
        }
        let productiveRatioScore = weightedProductiveDuration / totalDuration
        
        // 4. CONTEXT CONTINUITY (weight: 0.15)
        var relatedSwitches = 0
        if processedEvents.count > 1 {
            for i in 0..<(processedEvents.count - 1) {
                let cat1 = processedEvents[i].category
                let cat2 = processedEvents[i+1].category
                
                if cat1 == cat2 {
                    relatedSwitches += 1
                } else if (cat1 == .productive || cat1 == .reference || cat1 == .neutral) &&
                            (cat2 == .productive || cat2 == .reference || cat2 == .neutral) {
                    relatedSwitches += 1
                }
            }
        }
        let contextContinuityScore = switchCount > 0 ? Double(relatedSwitches) / Double(switchCount) : 1.0
        
        // Combine scores
        let finalScoreDouble = (sustainedAttentionScore * 0.40 +
                                switchFrequencyScore * 0.25 +
                                productiveRatioScore * 0.20 +
                                contextContinuityScore * 0.15) * 100.0
        
        let finalScore = min(max(Int(round(finalScoreDouble)), 0), 100)
        let level = FocusLevel.from(score: finalScore)
        
        return (finalScore, level)
    }
}
