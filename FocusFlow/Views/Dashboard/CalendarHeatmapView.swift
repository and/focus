import SwiftUI

struct CalendarHeatmapView: View {
    let dailyScores: [DailyScore]
    
    private let rows = Array(repeating: GridItem(.fixed(12), spacing: 3), count: 7)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ACTIVITY HEATMAP")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
                .tracking(1.0)
            
            let daysData = calculateDaysData()
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: rows, spacing: 3) {
                    ForEach(daysData, id: \.date) { item in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(colorForScore(item.score))
                            .frame(width: 12, height: 12)
                            .help("\(formatDate(item.date)): Score \(item.score ?? 0)")
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    struct HeatmapDay: Hashable {
        let date: Date
        let score: Int?
    }
    
    private func calculateDaysData() -> [HeatmapDay] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var days: [HeatmapDay] = []
        
        let scoreMap = Dictionary(uniqueKeysWithValues: dailyScores.map {
            (calendar.startOfDay(for: $0.date), $0.averageScore)
        })
        
        let totalDays = 150
        guard let startDate = calendar.date(byAdding: .day, value: -totalDays, to: today) else {
            return []
        }
        
        let weekday = calendar.component(.weekday, from: startDate)
        let daysToSubtract = weekday - 1
        
        guard let alignedStartDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: startDate) else {
            return []
        }
        
        var currentDate = alignedStartDate
        while currentDate <= today {
            let score = scoreMap[currentDate]
            days.append(HeatmapDay(date: currentDate, score: score))
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }
        
        return days
    }
    
    private func colorForScore(_ score: Int?) -> Color {
        guard let score = score else {
            return Color.secondary.opacity(0.1)
        }
        
        if score >= 80 {
            return Color.green.opacity(0.9)
        } else if score >= 60 {
            return Color.green.opacity(0.6)
        } else if score >= 40 {
            return Color.green.opacity(0.4)
        } else if score >= 20 {
            return Color.green.opacity(0.2)
        } else {
            return Color.red.opacity(0.2)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
