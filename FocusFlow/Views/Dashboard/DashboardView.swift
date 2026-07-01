import SwiftUI

struct DashboardView: View {
    @ObservedObject var appState: AppState
    
    @State private var selectedTab = 0
    @State private var todayEvents: [ActivityEvent] = []
    @State private var dailyScores: [DailyScore] = []
    
    // Stats
    @State private var totalFocusMinutes: Double = 0
    @State private var averageScore: Int = 100
    @State private var switchesToday: Int = 0
    @State private var longestStreakMinutes: Int = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Header/Selector
            Picker("", selection: $selectedTab) {
                Text("Today").tag(0)
                Text("History").tag(1)
                Text("Settings").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()
            
            Divider()
            
            // Tab Contents
            ScrollView {
                switch selectedTab {
                case 0:
                    todayTabView
                case 1:
                    historyTabView
                default:
                    SettingsView()
                }
            }
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 550, minHeight: 600)
        .onAppear {
            loadDashboardData()
        }
    }
    
    private var todayTabView: some View {
        VStack(spacing: 24) {
            // Top Section: Score Gauge & Stats Row
            HStack(spacing: 40) {
                ScoreGaugeView(score: appState.focusScore, level: FocusLevel.from(score: appState.focusScore))
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Today's Overview")
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.bold)
                    
                    HStack(spacing: 16) {
                        statCard(title: "Focus Time", value: formatMinutes(totalFocusMinutes), systemImage: "clock.fill", color: .green)
                        statCard(title: "Avg Score", value: "\(averageScore)", systemImage: "percent", color: .blue)
                    }
                    
                    HStack(spacing: 16) {
                        statCard(title: "Switches", value: "\(switchesToday)", systemImage: "arrow.left.arrow.right", color: .orange)
                        statCard(title: "Streak", value: "\(longestStreakMinutes)m", systemImage: "bolt.fill", color: .yellow)
                    }
                }
            }
            .padding(.top)
            
            Divider()
            
            // Timeline view
            TimelineView(events: todayEvents)
                .padding(.horizontal)
            
            Divider()
            
            // App Breakdown View
            AppBreakdownView(events: todayEvents)
                .padding(.horizontal)
                .padding(.bottom)
        }
    }
    
    private var historyTabView: some View {
        VStack(spacing: 24) {
            TrendChartView(dailyScores: dailyScores)
                .padding(.horizontal)
                .padding(.top)
            
            Divider()
            
            CalendarHeatmapView(dailyScores: dailyScores)
                .padding(.horizontal)
                .padding(.bottom)
        }
    }
    
    private func statCard(title: String, value: String, systemImage: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.bold)
            }
        }
        .frame(width: 140, alignment: .leading)
        .padding(10)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
    
    private func loadDashboardData() {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        
        do {
            // Load today's events
            let events = try EventStore.shared.fetchEvents(since: startOfToday)
            self.todayEvents = events
            
            // Load history
            let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: Date())!
            self.dailyScores = try SessionStore.shared.fetchDailyScores(since: oneMonthAgo)
            
            // Calculate today stats
            calculateStats(events: events)
        } catch {
            print("Dashboard: Failed to load data: \(error)")
        }
    }
    
    private func calculateStats(events: [ActivityEvent]) {
        self.switchesToday = max(events.count - 1, 0)
        
        let totalActiveSeconds = events.compactMap { $0.durationSeconds }.reduce(0, +)
        
        // Sum productive and reference times
        let productiveSeconds = events.filter { $0.category == .productive || $0.category == .reference }
            .compactMap { $0.durationSeconds }.reduce(0, +)
        self.totalFocusMinutes = productiveSeconds / 60.0
        
        // Calculate average focus score (mocked for today based on active events)
        let scoringResult = FocusScoreEngine.shared.calculateScore(events: events)
        self.averageScore = scoringResult.score
        
        // Calculate longest streak
        var longestStreak: Double = 0
        var currentStreak: Double = 0
        for event in events {
            let duration = event.durationSeconds ?? 0
            if event.category == .productive || event.category == .reference || event.category == .neutral {
                currentStreak += duration
                if currentStreak > longestStreak {
                    longestStreak = currentStreak
                }
            } else if event.category == .distracting {
                currentStreak = 0
            }
        }
        self.longestStreakMinutes = Int(round(longestStreak / 60.0))
    }
    
    private func formatMinutes(_ minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins)m"
        }
    }
}
