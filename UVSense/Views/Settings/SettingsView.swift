import SwiftUI
import UserNotifications
import CoreLocation

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var notificationService: NotificationService
    
    @State private var remindersEnabled = false
    @State private var showingLocationUpgradeAlert = false
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var showingSkinProfile = false
    @State private var showingReleaseNotes = false
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("hasProfile") private var hasProfile = false
    
    // App info
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    var body: some View {
        NavigationView {
            List {
                // Notifications Section
                Section {
                    Toggle(isOn: $remindersEnabled) {
                        HStack {
                            Image(systemName: "bell.badge")
                                .foregroundColor(.blue)
                                .frame(width: 28)
                            VStack(alignment: .leading) {
                                Text("Leave-Home Reminders")
                                    .font(.body)
                                Text("Get notified when UV is high")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onChange(of: remindersEnabled) { oldValue, newValue in
                        if newValue {
                            enableReminders()
                        } else {
                            disableReminders()
                        }
                    }
                } header: {
                    Text("Notifications")
                }
                
                // Personalization Section
                Section {
                    Button(action: { showingSkinProfile = true }) {
                        HStack {
                            Image(systemName: "person.crop.circle")
                                .foregroundColor(.orange)
                                .frame(width: 28)
                            VStack(alignment: .leading) {
                                Text("Skin Profile")
                                    .foregroundColor(.primary)
                                if hasProfile {
                                    Text("Customize burn time calculations")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Set up your skin type")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Personalization")
                }
                
                // App Settings Section
                Section {
                    Button(action: openAppSettings) {
                        HStack {
                            Image(systemName: "gear")
                                .foregroundColor(.gray)
                                .frame(width: 28)
                            Text("App Permissions")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.forward.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("System")
                }
                
                // About Section
                Section {
                    Link(destination: URL(string: "http://uvsense.infuse.hk/privacy-policy")!) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(.blue)
                                .frame(width: 28)
                            Text("Privacy Policy")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.forward.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "http://uvsense.infuse.hk/terms")!) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.green)
                                .frame(width: 28)
                            Text("Terms of Service")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.forward.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: { showingReleaseNotes = true }) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.purple)
                                .frame(width: 28)
                            Text("What's New")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "mailto:uvsense@infuse.hk")!) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.indigo)
                                .frame(width: 28)
                            Text("Support")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.forward.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("About")
                } footer: {
                    VStack(spacing: 8) {
                        Text("UV Sense")
                            .font(.caption)
                        Text("Version \(appVersion) (\(buildNumber))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingSkinProfile) {
                SkinProfileWizard()
            }
            .sheet(isPresented: $showingReleaseNotes) {
                ReleaseNotesView()
            }
            .alert("Enable Location Access", isPresented: $showingLocationUpgradeAlert) {
                Button("Open Settings") {
                    openAppSettings()
                }
                Button("Cancel", role: .cancel) {
                    remindersEnabled = false
                }
            } message: {
                // Check if the issue is precision
                if locationService.locationAccuracyAuthorization == .reducedAccuracy {
                    Text("Leave-home reminders require precise location to accurately detect when you leave home.\n\nPlease tap 'Open Settings' and enable 'Precise Location'.")
                } else {
                    switch locationService.authorizationStatus {
                    case .denied:
                        Text("Location access is denied.\n\nPlease enable 'Always' location access with 'Precise Location' to receive leave-home reminders.")
                    case .restricted:
                        Text("Location access is restricted.\n\nPlease check your device settings to enable location services.")
                    case .authorizedWhenInUse:
                        Text("To receive leave-home reminders, UV Sense needs:\n\n1. 'Always Allow' location permission\n2. 'Precise Location' enabled\n\nPlease tap 'Open Settings' and update your location settings.")
                    default:
                        Text("UV Sense needs 'Always Allow' location permission with 'Precise Location' to send leave-home reminders.\n\nPlease tap 'Open Settings' and enable location access.")
                    }
                }
            }
        }
        .task {
            await checkPermissions()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task {
                await checkPermissions()
            }
        }
    }
    
    private func checkPermissions() async {
        // Check notification permission
        let notificationSettings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            notificationStatus = notificationSettings.authorizationStatus
            
            // Update reminders toggle based on all three requirements:
            // 1. Notifications authorized
            // 2. Always location permission
            // 3. Precise location enabled
            let hasNotifications = notificationStatus == .authorized
            let hasAlwaysLocation = locationService.authorizationStatus == .authorizedAlways
            let hasPreciseLocation = locationService.locationAccuracyAuthorization == .fullAccuracy
            
            remindersEnabled = hasNotifications && hasAlwaysLocation && hasPreciseLocation
        }
    }
    
    private func enableReminders() {
        Task {
            // First check location permission
            switch locationService.authorizationStatus {
            case .notDetermined:
                // Request location permission
                locationService.requestLocationPermission()
                // Wait a bit for the permission to be granted
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                // Check again after requesting
                if locationService.authorizationStatus != .authorizedAlways || 
                   locationService.locationAccuracyAuthorization != .fullAccuracy {
                    await MainActor.run {
                        remindersEnabled = false
                        if locationService.authorizationStatus != .notDetermined {
                            showingLocationUpgradeAlert = true
                        }
                    }
                    return
                }
                
            case .authorizedAlways:
                // Check if we also have precise location
                if locationService.locationAccuracyAuthorization != .fullAccuracy {
                    await MainActor.run {
                        remindersEnabled = false
                        showingLocationUpgradeAlert = true
                    }
                    return
                }
                // Have both always and precise, proceed to notifications
                break
                
            case .authorizedWhenInUse, .denied, .restricted:
                // Need to upgrade or can't proceed
                await MainActor.run {
                    remindersEnabled = false
                    showingLocationUpgradeAlert = true
                }
                return
                
            @unknown default:
                await MainActor.run {
                    remindersEnabled = false
                }
                return
            }
            
            // Now request notification permission if needed
            let notificationSettings = await UNUserNotificationCenter.current().notificationSettings()
            
            if notificationSettings.authorizationStatus == .notDetermined {
                let granted = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
                if granted != true {
                    await MainActor.run {
                        remindersEnabled = false
                    }
                }
            } else if notificationSettings.authorizationStatus != .authorized {
                // Notifications denied, need to go to settings
                await MainActor.run {
                    remindersEnabled = false
                    showingLocationUpgradeAlert = true
                }
            }
            
            // Final check - update the toggle state
            await checkPermissions()
        }
    }
    
    private func disableReminders() {
        // User turned off reminders - we don't revoke permissions, just stop using them
        // The actual reminder logic should check this toggle state
    }
    
    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}