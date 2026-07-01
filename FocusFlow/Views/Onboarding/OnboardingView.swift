import SwiftUI
import UserNotifications

struct OnboardingView: View {
    @Binding var isPresented: Bool
    
    @State private var currentStep = 0
    @State private var isAccessibilityGranted = false
    @State private var isNotificationsGranted = false
    
    @AppStorage("trackingStartHour") private var trackingStartHour = 9
    @AppStorage("trackingEndHour") private var trackingEndHour = 18
    @AppStorage("dailyFocusGoalMinutes") private var dailyFocusGoalMinutes = 120
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Text("FocusFlow Setup")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                Spacer()
                Text("Step \(currentStep + 1) of 4")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 8)
            
            // Content
            Group {
                switch currentStep {
                case 0:
                    welcomeView
                case 1:
                    permissionsView
                case 2:
                    customizeView
                default:
                    readyView
                }
            }
            .frame(maxHeight: .infinity)
            
            // Footer Navigation
            HStack {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation { currentStep -= 1 }
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                if currentStep < 3 {
                    Button("Next") {
                        withAnimation { currentStep += 1 }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(currentStep == 1 && !isAccessibilityGranted)
                } else {
                    Button("Get Started") {
                        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                        isPresented = false
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(24)
        .frame(width: 480, height: 380)
        .onAppear {
            checkPermissions()
        }
    }
    
    private var welcomeView: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 64))
                .foregroundColor(.green)
                .padding()
                .background(Color.green.opacity(0.1))
                .clipShape(Circle())
            
            Text("Welcome to FocusFlow")
                .font(.system(.title, design: .rounded))
                .fontWeight(.bold)
            
            Text("FocusFlow runs quietly in your menu bar to track your computer activity and calculate a real-time focus score from 0 to 100.")
                .font(.system(.body, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            HStack(spacing: 6) {
                Image(systemName: "lock.fill")
                Text("100% local — your activity data never leaves this Mac. No cloud, no accounts, no analytics.")
            }
            .font(.system(.caption, design: .rounded))
            .fontWeight(.medium)
            .foregroundColor(.green)
            .multilineTextAlignment(.center)
            .padding(10)
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)
        }
    }

    private var permissionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Grant Permissions")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.semibold)
            
            Text("FocusFlow needs Accessibility permissions to monitor active app window titles and page tabs to distinguish productive vs distracting time. Your data never leaves your computer.")
                .font(.system(.body, design: .rounded))
                .foregroundColor(.secondary)
                .lineSpacing(3)
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: isAccessibilityGranted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundColor(isAccessibilityGranted ? .green : .orange)
                    Text("Accessibility Control")
                        .fontWeight(.medium)
                    Spacer()
                    Button(isAccessibilityGranted ? "Granted" : "Grant Access") {
                        PermissionsManager.shared.requestAccessibilityPermission()
                    }
                    .disabled(isAccessibilityGranted)
                }
                .padding(10)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
                
                HStack {
                    Image(systemName: isNotificationsGranted ? "checkmark.circle.fill" : "bell.fill")
                        .foregroundColor(isNotificationsGranted ? .green : .blue)
                    Text("Notifications (Optional)")
                        .fontWeight(.medium)
                    Spacer()
                    Button(isNotificationsGranted ? "Granted" : "Enable") {
                        FocusAlertManager.shared.requestNotificationPermission()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            checkPermissions()
                        }
                    }
                    .disabled(isNotificationsGranted)
                }
                .padding(10)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
            }
            
            Button("Check Permissions Again") {
                checkPermissions()
            }
            .buttonStyle(.link)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
    
    private var customizeView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Customize Tracking Settings")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.semibold)
            
            VStack(spacing: 14) {
                HStack {
                    Text("Daily Focus Time Target:")
                    Spacer()
                    Picker("", selection: $dailyFocusGoalMinutes) {
                        Text("30 mins").tag(30)
                        Text("1 hour").tag(60)
                        Text("2 hours").tag(120)
                        Text("4 hours").tag(240)
                    }
                    .frame(width: 120)
                }
                
                HStack {
                    Text("Active Tracking Window:")
                    Spacer()
                    Picker("", selection: $trackingStartHour) {
                        ForEach(0...23, id: \.self) { h in
                            Text("\(h):00").tag(h)
                        }
                    }
                    .frame(width: 80)
                    Text("to")
                    Picker("", selection: $trackingEndHour) {
                        ForEach(0...23, id: \.self) { h in
                            Text("\(h):00").tag(h)
                        }
                    }
                    .frame(width: 80)
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(10)
        }
    }
    
    private var readyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)
                .padding()
            
            Text("You're All Set!")
                .font(.system(.title, design: .rounded))
                .fontWeight(.bold)
            
            Text("FocusFlow will run quietly in the top right menu bar. Click the icon at any time to check your current focus score or click 'Open Dashboard' to review details.")
                .font(.system(.body, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }
    
    private func checkPermissions() {
        isAccessibilityGranted = PermissionsManager.shared.checkAccessibilityPermission()
        
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isNotificationsGranted = settings.authorizationStatus == .authorized
            }
        }
    }
}
