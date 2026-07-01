import SwiftUI

struct AppBreakdownItem: Identifiable {
    let id = UUID()
    let appName: String
    let category: AppCategory
    let duration: TimeInterval
}

struct AppBreakdownView: View {
    let events: [ActivityEvent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("APP BREAKDOWN")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
                .tracking(1.0)
            
            let items = calculateBreakdown()
            let totalDuration = items.reduce(0) { $0 + $1.duration }
            
            if items.isEmpty {
                Text("No app breakdown data available")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 10) {
                    ForEach(items.prefix(5)) { item in
                        let percentage = totalDuration > 0 ? (item.duration / totalDuration) : 0
                        
                        VStack(spacing: 4) {
                            HStack {
                                Text(item.appName)
                                    .font(.system(.body, design: .rounded))
                                    .fontWeight(.medium)
                                Spacer()
                                Text(formatDuration(item.duration))
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            
                            // Progress bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.secondary.opacity(0.1))
                                        .frame(height: 6)
                                    
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(item.category.color)
                                        .frame(width: geo.size.width * CGFloat(percentage), height: 6)
                                }
                            }
                            .frame(height: 6)
                        }
                    }
                }
            }
        }
    }
    
    private func calculateBreakdown() -> [AppBreakdownItem] {
        var appDurations: [String: (category: AppCategory, duration: TimeInterval)] = [:]
        
        for event in events {
            let duration = event.durationSeconds ?? 0
            if duration > 0 {
                let current = appDurations[event.appName] ?? (event.category, 0)
                appDurations[event.appName] = (event.category, current.duration + duration)
            }
        }
        
        return appDurations.map { AppBreakdownItem(appName: $0.key, category: $0.value.category, duration: $0.value.duration) }
            .sorted { $0.duration > $1.duration }
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
