import SwiftUI
import Charts

struct TrendChartView: View {
    let dailyScores: [DailyScore]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("FOCUS TREND")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
                .tracking(1.0)
            
            if dailyScores.isEmpty {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.1))
                    .frame(height: 180)
                    .overlay(
                        Text("No historical data available")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.secondary)
                    )
            } else {
                Chart {
                    ForEach(dailyScores) { score in
                        LineMark(
                            x: .value("Date", score.date, unit: .day),
                            y: .value("Score", score.averageScore)
                        )
                        .foregroundStyle(Color.blue.gradient)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        
                        PointMark(
                            x: .value("Date", score.date, unit: .day),
                            y: .value("Score", score.averageScore)
                        )
                        .foregroundStyle(Color.blue)
                    }
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(values: [0, 25, 50, 75, 100])
                }
                .frame(height: 180)
            }
        }
    }
}
