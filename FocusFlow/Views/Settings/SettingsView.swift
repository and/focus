import SwiftUI
import LaunchAtLogin
import UniformTypeIdentifiers

struct SettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("trackingStartHour") private var trackingStartHour = 9
    @AppStorage("trackingEndHour") private var trackingEndHour = 18
    @AppStorage("dailyFocusGoalMinutes") private var dailyFocusGoalMinutes = 120
    @AppStorage("dailyFocusGoalScore") private var dailyFocusGoalScore = 70
    @AppStorage("idleThresholdSeconds") private var idleThresholdSeconds = 120
    
    @State private var bundleIDInput = ""
    @State private var selectedCategory = AppCategory.productive
    @State private var customMappingsList: [(bundleID: String, category: AppCategory)] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // General Preferences
            VStack(alignment: .leading, spacing: 12) {
                Text("GENERAL PREFERENCES")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                    .tracking(1.0)
                
                Toggle("Launch FocusFlow at Login", isOn: $launchAtLogin)
                    .toggleStyle(.checkbox)
                    .onChange(of: launchAtLogin) { newValue in
                        LaunchAtLogin.isEnabled = newValue
                    }
                
                HStack {
                    Text("Tracking Hours:")
                    Spacer()
                    Picker("", selection: $trackingStartHour) {
                        ForEach(0...23, id: \.self) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                    .frame(width: 90)
                    Text("to")
                    Picker("", selection: $trackingEndHour) {
                        ForEach(0...23, id: \.self) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                    .frame(width: 90)
                }
                
                HStack {
                    Text("Idle Detection Timeout:")
                    Spacer()
                    Picker("", selection: $idleThresholdSeconds) {
                        Text("30 seconds").tag(30)
                        Text("1 minute").tag(60)
                        Text("2 minutes").tag(120)
                        Text("5 minutes").tag(300)
                        Text("10 minutes").tag(600)
                    }
                    .frame(width: 150)
                }
            }
            .padding(.horizontal)
            .padding(.top)

            Divider()

            // Data Management
            VStack(alignment: .leading, spacing: 12) {
                Text("DATA MANAGEMENT")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                    .tracking(1.0)

                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.green)
                    Text("Everything below lives only in a local SQLite database on this Mac. FocusFlow makes no network requests and sends nothing anywhere.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(Color.green.opacity(0.08))
                .cornerRadius(6)

                HStack(spacing: 16) {
                    Button(action: exportToCSV) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export Activity to CSV")
                        }
                    }
                    .buttonStyle(.bordered)

                    Button(action: revealDataInFinder) {
                        HStack {
                            Image(systemName: "folder")
                            Text("Show Data Folder in Finder")
                        }
                    }
                    .buttonStyle(.bordered)

                    Button(action: clearAllData) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear All Database History")
                        }
                        .foregroundColor(.red)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal)

            Divider()

            // Goals
            VStack(alignment: .leading, spacing: 12) {
                Text("DAILY FOCUS GOALS")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                    .tracking(1.0)
                
                HStack {
                    Text("Focus Score Target:")
                    Spacer()
                    Slider(value: Binding(get: {
                        Double(dailyFocusGoalScore)
                    }, set: {
                        dailyFocusGoalScore = Int($0)
                    }), in: 0...100, step: 5)
                    .frame(width: 160)
                    Text("\(dailyFocusGoalScore)")
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.bold)
                }
                
                HStack {
                    Text("Focused Time Target:")
                    Spacer()
                    Picker("", selection: $dailyFocusGoalMinutes) {
                        Text("30 mins").tag(30)
                        Text("1 hour").tag(60)
                        Text("2 hours").tag(120)
                        Text("4 hours").tag(240)
                        Text("6 hours").tag(360)
                    }
                    .frame(width: 100)
                }
            }
            .padding(.horizontal)
            
            Divider()
            
            // App Categories Editor
            VStack(alignment: .leading, spacing: 12) {
                Text("APP CATEGORIES OVERRIDES")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                    .tracking(1.0)
                
                HStack {
                    TextField("Enter bundle ID (e.g. com.spotify.client)", text: $bundleIDInput)
                        .textFieldStyle(.roundedBorder)
                    
                    Picker("", selection: $selectedCategory) {
                        ForEach(AppCategory.allCases, id: \.self) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }
                    .frame(width: 120)
                    
                    Button("Add Override") {
                        addOverride()
                    }
                }
                
                // Override List
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(customMappingsList, id: \.bundleID) { mapping in
                            HStack {
                                Text(mapping.bundleID)
                                    .font(.system(.subheadline, design: .monospaced))
                                Spacer()
                                Text(mapping.category.displayName)
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(mapping.category.color)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(mapping.category.color.opacity(0.1))
                                    .cornerRadius(4)
                                
                                Button(action: {
                                    removeOverride(bundleID: mapping.bundleID)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 4)
                            Divider()
                        }
                    }
                }
                .frame(height: 120)
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .onAppear {
            loadOverrides()
        }
    }
    
    private func addOverride() {
        guard !bundleIDInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        AppCategorizer.shared.setCategory(for: bundleIDInput, category: selectedCategory)
        bundleIDInput = ""
        loadOverrides()
    }
    
    private func removeOverride(bundleID: String) {
        AppCategorizer.shared.removeCategoryOverride(for: bundleID)
        loadOverrides()
    }
    
    private func loadOverrides() {
        let mappings = AppCategorizer.shared.getCustomMappings()
        customMappingsList = mappings.map { (bundleID: $0.key, category: $0.value) }
            .sorted { $0.bundleID < $1.bundleID }
    }
    
    private func exportToCSV() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType.commaSeparatedText]
        savePanel.nameFieldStringValue = "focus_flow_activity_export.csv"
        
        savePanel.begin { result in
            guard result == .OK, let url = savePanel.url else { return }
            
            do {
                let startOfHistory = Date.distantPast
                let events = try EventStore.shared.fetchEvents(since: startOfHistory)
                
                var csvString = "Timestamp,BundleID,AppName,WindowTitle,Category,DurationSeconds\n"
                for event in events {
                    let timestampStr = ISO8601DateFormatter().string(from: event.timestamp)
                    let cleanApp = event.appName.replacingOccurrences(of: "\"", with: "\"\"")
                    let cleanTitle = (event.windowTitle ?? "").replacingOccurrences(of: "\"", with: "\"\"")
                    csvString += "\(timestampStr),\"\(event.bundleID)\",\"\(cleanApp)\",\"\(cleanTitle)\",\(event.category.rawValue),\(event.durationSeconds ?? 0)\n"
                }
                
                try csvString.write(to: url, atomically: true, encoding: .utf8)
                print("Exported CSV successfully to \(url.path)")
            } catch {
                print("Failed to export CSV: \(error)")
            }
        }
    }
    
    private func revealDataInFinder() {
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let focusFlowURL = appSupportURL.appendingPathComponent("FocusFlow", isDirectory: true)
        NSWorkspace.shared.activateFileViewerSelecting([focusFlowURL])
    }

    private func clearAllData() {
        let alert = NSAlert()
        alert.messageText = "Clear All Data?"
        alert.informativeText = "This will permanently delete all activity events, sessions, and daily score history. This action cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Delete Everything")
        
        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            do {
                try DatabaseManager.shared.dbQueue.write { db in
                    _ = try db.execute(sql: "DELETE FROM activityEvents")
                    _ = try db.execute(sql: "DELETE FROM focusSessions")
                    _ = try db.execute(sql: "DELETE FROM dailyScores")
                }
                print("Database cleared successfully.")
                loadOverrides()
            } catch {
                print("Failed to clear database: \(error)")
            }
        }
    }
    
    private func formatHour(_ hour: Int) -> String {
        if hour == 0 {
            return "12 AM"
        } else if hour < 12 {
            return "\(hour) AM"
        } else if hour == 12 {
            return "12 PM"
        } else {
            return "\(hour - 12) PM"
        }
    }
}
