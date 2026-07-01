import SwiftUI

struct MenuBarView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 16) {
            // Header: Score & Level
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Focus Score")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(appState.focusScore)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(scoreColor)
                        
                        Text("/ 100")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Status Indicator Badge
                VStack(alignment: .trailing, spacing: 6) {
                    Text(appState.focusLevel)
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(scoreColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(scoreColor.opacity(0.15))
                        .cornerRadius(8)
                    
                    if appState.isIdle {
                        Text("Idle")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15))
                            .cornerRadius(4)
                    } else {
                        Text("Active")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.15))
                            .cornerRadius(4)
                    }
                }
            }
            
            Divider()
            
            // Current Activity Info
            VStack(alignment: .leading, spacing: 8) {
                Text("CURRENT ACTIVITY")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                    .tracking(1.0)
                
                HStack(spacing: 8) {
                    Image(systemName: "square.dashed.inset.filled")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(appState.activeAppName)
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.medium)
                            .lineLimit(1)
                        if !appState.activeWindowTitle.isEmpty {
                            Text(appState.activeWindowTitle)
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
            
            // Statistics
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SESSION")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                    Text("\(appState.sessionDurationMinutes) min")
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("SWITCHES")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                    Text("\(appState.switchesCount)")
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.semibold)
                }
            }
            
            Divider()
            
            // Accessibility Alert if not granted
            if !appState.isAccessibilityGranted {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Accessibility Required")
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.semibold)
                    }
                    Text("Needed to track window titles and browser tabs.")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        PermissionsManager.shared.requestAccessibilityPermission()
                    }) {
                        Text("Grant Permission")
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
                .padding(10)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Action Buttons
            VStack(spacing: 6) {
                Button(action: {
                    if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                        appDelegate.openDashboardWindow()
                    }
                }) {
                    HStack {
                        Image(systemName: "macwindow")
                        Text("Open Dashboard")
                        Spacer()
                        Text("⌘D").font(.caption).foregroundColor(.secondary)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(MenuButtonStyle())
                
                Button(action: {
                    appState.toggleTracking()
                }) {
                    HStack {
                        Image(systemName: appState.isTracking ? "pause.fill" : "play.fill")
                        Text(appState.isTracking ? "Pause Tracking" : "Resume Tracking")
                        Spacer()
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(MenuButtonStyle())
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    HStack {
                        Image(systemName: "power")
                        Text("Quit FocusFlow")
                        Spacer()
                        Text("⌘Q").font(.caption).foregroundColor(.secondary)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(MenuButtonStyle())
            }
        }
        .padding(16)
        .frame(width: 280)
    }
    
    private var scoreColor: Color {
        if appState.focusScore >= 80 { return Color.green }
        else if appState.focusScore >= 60 { return Color.blue }
        else if appState.focusScore >= 40 { return Color.yellow }
        else if appState.focusScore >= 20 { return Color.orange }
        else { return Color.red }
    }
}

struct MenuButtonStyle: ButtonStyle {
    @State private var isHovering = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .rounded))
            .foregroundColor(configuration.isPressed ? .secondary : .primary)
            .background(isHovering ? Color.primary.opacity(0.08) : Color.clear)
            .cornerRadius(6)
            .onHover { hovering in
                isHovering = hovering
            }
    }
}
