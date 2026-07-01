import SwiftUI

struct ScoreGaugeView: View {
    let score: Int
    let level: FocusLevel
    
    @State private var animatedScore: Double = 0
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background track
                Circle()
                    .stroke(Color.secondary.opacity(0.15), style: StrokeStyle(lineWidth: 18, lineCap: .round))
                    .frame(width: 160, height: 160)
                
                // Animated gauge path
                Circle()
                    .trim(from: 0.0, to: CGFloat(animatedScore / 100.0))
                    .stroke(
                        AngularGradient(
                            colors: [level.color.opacity(0.6), level.color],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 160, height: 160)
                    .animation(.spring(response: 1.0, dampingFraction: 0.7, blendDuration: 0.5), value: animatedScore)
                
                // Label
                VStack(spacing: 2) {
                    Text("\(Int(animatedScore))")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(level.color)
                    
                    Text("Focus Score")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            .onAppear {
                animatedScore = Double(score)
            }
            .onChange(of: score) { newScore in
                withAnimation {
                    animatedScore = Double(newScore)
                }
            }
        }
    }
}
