import SwiftUI

struct TimelineView: View {
    let events: [ActivityEvent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TODAY'S TIMELINE")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
                .tracking(1.0)
            
            if events.isEmpty {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.1))
                    .frame(height: 36)
                    .overlay(
                        Text("No activity recorded yet today")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.secondary)
                    )
            } else {
                GeometryReader { geo in
                    let totalSeconds = events.compactMap { $0.durationSeconds }.reduce(0, +)
                    
                    HStack(spacing: 0) {
                        if totalSeconds > 0 {
                            ForEach(Array(events.prefix(150).enumerated()), id: \.offset) { _, event in
                                let duration = event.durationSeconds ?? 0
                                let width = CGFloat(duration / totalSeconds) * geo.size.width
                                
                                if width > 0.5 {
                                    Rectangle()
                                        .fill(event.category.color)
                                        .frame(width: width, height: 36)
                                        .help("\(event.appName) (\(event.category.displayName)): \(formatDuration(duration))")
                                }
                            }
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                        }
                    }
                    .cornerRadius(8)
                    .clipped()
                }
                .frame(height: 36)
                
                // Legend
                HStack(spacing: 12) {
                    ForEach(AppCategory.allCases, id: \.self) { category in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(category.color)
                                .frame(width: 8, height: 8)
                            Text(category.displayName)
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: seconds) ?? ""
    }
}
