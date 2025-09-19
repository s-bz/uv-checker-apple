import SwiftUI
import SwiftData
import CoreLocation
import UserNotifications

// Helper function for burn time warning colors
private func burnTimeWarningColor(_ level: BurnTimeCalculator.BurnTimeResult.WarningLevel) -> Color {
    switch level {
    case .safe: return .green
    case .caution: return .yellow
    case .warning: return .orange
    case .danger: return .red
    }
}

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var weatherService = WeatherKitService.shared
    @StateObject private var locationService = LocationService.shared
    
    @Query(sort: \SkinProfile.createdAt, order: .reverse) private var skinProfiles: [SkinProfile]
    @Query(sort: \SunscreenApplication.appliedAt, order: .reverse) private var sunscreenApplications: [SunscreenApplication]
    
    @State private var showingSunscreenSheet = false
    @State private var showingProfileSetup = false
    @State private var showingSkinProfileWizard = false
    @State private var isRefreshing = false
    @State private var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    @State private var showingLocationUpgradeAlert = false
    @State private var showLocationToast = false
    @State private var toastMessage = ""
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    private var currentSkinProfile: SkinProfile? {
        skinProfiles.first
    }
    
    private var currentSunscreen: SunscreenApplication? {
        sunscreenApplications.first { !$0.needsReapplication }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 16) {
                        // Space for warning banner if needed
                        if locationService.currentLocationData?.locationType != .precise {
                            Color.clear.frame(height: 140)
                        }
                        
                        // Location Header
                        LocationHeaderView(
                            locationData: locationService.currentLocationData,
                            currentUV: weatherService.currentUVData,
                            isStale: weatherService.currentUVData?.isStale ?? false,
                            onRefresh: refreshData
                        )
                        .padding(.horizontal)
                    
                    // Current Conditions Card (with integrated sunscreen)
                    CurrentConditionsCard(
                        uvData: weatherService.currentUVData,
                        burnTime: currentBurnTime,
                        sunscreenWindow: weatherService.calculateSunscreenWindow(),
                        currentSunscreen: currentSunscreen,
                        onApplySunscreen: { showingSunscreenSheet = true },
                        onRemoveSunscreen: removeSunscreen
                    )
                    .padding(.horizontal)
                    
                    // UV Timeline
                    if !weatherService.hourlyForecast.isEmpty {
                        UVTimelineView(
                            hourlyData: weatherService.hourlyForecast,
                            sunscreenWindow: weatherService.calculateSunscreenWindow()
                        )
                        .padding(.horizontal)
                    }
                    
                    // Quick Actions
                    QuickActionsSection(
                        hasProfile: currentSkinProfile != nil,
                        notificationStatus: notificationPermissionStatus,
                        hasAlwaysLocation: locationService.hasAlwaysPermission(),
                        onSetupProfile: { showingSkinProfileWizard = true },
                        onEnableNotifications: enableNotifications
                    )
                    .padding(.horizontal)
                    }
                    .padding(.vertical, 16)
                }
                
                // Location Warning Banner (overlaid at top)
                VStack {
                    LocationWarningBanner(
                        locationData: locationService.currentLocationData,
                        onEnablePreciseLocation: handleEnablePreciseLocation,
                        onDismiss: {}
                    )
                    Spacer()
                }
            }
            .navigationTitle("UV Checker")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingProfileSetup = true }) {
                        Image(systemName: "person.circle")
                    }
                }
            }
            .refreshable {
                await refreshData()
            }
            .sheet(isPresented: $showingSunscreenSheet) {
                SunscreenApplicationSheet(
                    onApply: applySunscreen
                )
            }
            .sheet(isPresented: $showingProfileSetup) {
                OnboardingContainerView()
                    .onDisappear {
                        // After onboarding, load weather data if we have permission
                        Task {
                            if locationService.authorizationStatus == .authorizedWhenInUse || 
                               locationService.authorizationStatus == .authorizedAlways {
                                locationService.requestLocation()
                                
                                try? await Task.sleep(nanoseconds: 500_000_000)
                                
                                if let location = locationService.currentLocation,
                                   let locationData = locationService.currentLocationData {
                                    await weatherService.fetchWeatherData(
                                        for: location,
                                        locationName: locationData.displayName,
                                        modelContext: modelContext
                                    )
                                }
                            }
                        }
                    }
            }
            .sheet(isPresented: $showingSkinProfileWizard) {
                SkinProfileWizard()
            }
            .alert("Location Permission Needed", isPresented: $showingLocationUpgradeAlert) {
                Button("Open Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                switch locationService.authorizationStatus {
                case .denied:
                    Text("Location access is denied.\n\nPlease go to Settings and enable location access for UV Checker to receive leave-home reminders.")
                case .restricted:
                    Text("Location access is restricted.\n\nPlease check your device settings to enable location services.")
                default:
                    Text("UV Checker needs proper location permissions:\n\n• 'While Using App' - For UV updates when the app is open\n• 'Always Allow' - For reminders when you leave home\n\nYou currently have 'Allow Once' permission. Please go to Settings and change to 'While Using App', then return here to enable leave-home reminders.")
                }
            }
            .task {
                await initialLoad()
                await checkNotificationPermission()
            }
            .onReceive(NotificationCenter.default.publisher(for: .locationUpdatedViaIP)) { notification in
                Task {
                    // Show brief loading indicator
                    isRefreshing = true
                    
                    let isVPN = notification.userInfo?["isVPN"] as? Bool ?? false
                    
                    if let location = notification.object as? CLLocation,
                       let locationData = locationService.currentLocationData {
                        // Fetch weather for new location
                        await weatherService.fetchWeatherData(
                            for: location,
                            locationName: locationData.displayName,
                            modelContext: modelContext
                        )
                        
                        // Show toast notification
                        if isVPN {
                            toastMessage = "VPN detected - Using \(locationData.shortDisplayName)"
                        } else {
                            toastMessage = "Location updated to \(locationData.shortDisplayName)"
                        }
                        showLocationToast = true
                        
                        // Hide toast after delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            showLocationToast = false
                        }
                    }
                    
                    isRefreshing = false
                }
            }
            .overlay(alignment: .bottom) {
                if showLocationToast {
                    ToastView(message: toastMessage, icon: "location.fill")
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.easeInOut, value: showLocationToast)
                }
            }
            .onChange(of: locationService.authorizationStatus) { oldStatus, newStatus in
                // When permission is newly granted, fetch location and weather
                if oldStatus != .authorizedWhenInUse && oldStatus != .authorizedAlways &&
                   (newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways) {
                    Task {
                        locationService.requestLocation()
                        
                        // Wait for location to be obtained
                        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                        
                        if let location = locationService.currentLocation,
                           let locationData = locationService.currentLocationData {
                            await weatherService.fetchWeatherData(
                                for: location,
                                locationName: locationData.displayName,
                                modelContext: modelContext
                            )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var currentBurnTime: BurnTimeCalculator.BurnTimeResult? {
        guard let uvData = weatherService.currentUVData else { return nil }
        
        return BurnTimeCalculator.calculateBurnTime(
            skinProfile: currentSkinProfile,
            uvIndex: uvData.uvIndex,
            sunscreen: currentSunscreen,
            cloudCover: uvData.cloudCover
        )
    }
    
    private func calculateBurnTimeForHour(_ hourData: HourlyUVData) -> BurnTimeCalculator.BurnTimeResult {
        return BurnTimeCalculator.calculateBurnTime(
            skinProfile: currentSkinProfile,
            uvIndex: hourData.uvIndex,
            sunscreen: currentSunscreen,
            cloudCover: hourData.cloudCover
        )
    }
    
    // MARK: - Actions
    
    private func initialLoad() async {
        locationService.setModelContext(modelContext)
        
        // Check authorization status
        if locationService.authorizationStatus == .authorizedAlways || 
           locationService.authorizationStatus == .authorizedWhenInUse {
            // Request current GPS location
            locationService.requestLocation()
            
            // Wait a moment for location to be obtained
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            if let location = locationService.currentLocation,
               let locationData = locationService.currentLocationData {
                await weatherService.fetchWeatherData(
                    for: location,
                    locationName: locationData.displayName,
                    modelContext: modelContext
                )
            }
        } else if locationService.authorizationStatus == .denied || 
                  locationService.authorizationStatus == .restricted {
            // Use IP-based location as fallback
            // The LocationService will automatically fetch IP location
            // Wait for it to complete
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            if let location = locationService.currentLocation,
               let locationData = locationService.currentLocationData {
                await weatherService.fetchWeatherData(
                    for: location,
                    locationName: locationData.displayName,
                    modelContext: modelContext
                )
            }
        }
        
        // Show onboarding if not completed
        if !hasCompletedOnboarding {
            showingProfileSetup = true
        }
    }
    
    private func refreshData() async {
        isRefreshing = true
        
        locationService.requestLocation()
        
        if let location = try? await locationService.getCurrentLocation(),
           let locationData = locationService.currentLocationData {
            await weatherService.fetchWeatherData(
                for: location,
                locationName: locationData.displayName,
                modelContext: modelContext
            )
        }
        
        isRefreshing = false
    }
    
    private func applySunscreen(spf: Int, quantity: ApplicationQuantity) {
        let application = SunscreenApplication(
            spfValue: spf,
            quantity: quantity,
            appliedAt: Date(),
            activityLevel: .normal
        )
        
        modelContext.insert(application)
        try? modelContext.save()
        
        // Update widget data
        updateWidgetData()
        
        showingSunscreenSheet = false
    }
    
    private func removeSunscreen() {
        if let current = currentSunscreen {
            modelContext.delete(current)
            try? modelContext.save()
            
            // Update widget data
            updateWidgetData()
        }
    }
    
    private func updateWidgetData() {
        // Trigger widget data update
        WidgetDataManager.shared.updateWidgetData(
            uvData: weatherService.currentUVData,
            skinProfile: currentSkinProfile,
            sunscreenApplication: currentSunscreen,
            hourlyForecast: weatherService.hourlyForecast,
            locationData: locationService.currentLocationData
        )
    }
    
    private func enableNotifications() {
        Task {
            // First request notification permission
            let notificationService = NotificationService.shared
            _ = await notificationService.requestNotificationPermission()
            await checkNotificationPermission()
            
            // Then handle location permissions
            if !locationService.hasAlwaysPermission() {
                // Check current authorization status
                switch locationService.authorizationStatus {
                case .notDetermined:
                    // First time - request While Using permission
                    locationService.requestLocationPermission()
                case .authorizedWhenInUse:
                    // Can upgrade from While Using to Always
                    locationService.requestAlwaysAuthorization()
                    // Set current location as home if we have it
                    if let currentLocation = locationService.currentLocation {
                        locationService.setHomeLocation(currentLocation)
                    }
                case .denied, .restricted:
                    // Denied or restricted - must go to settings
                    showingLocationUpgradeAlert = true
                default:
                    // "Allow Once" or other temporary permission - need to go to settings
                    showingLocationUpgradeAlert = true
                }
            } else {
                // Already have Always permission, just set home location
                if let currentLocation = locationService.currentLocation {
                    locationService.setHomeLocation(currentLocation)
                }
            }
        }
    }
    
    private func checkNotificationPermission() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        await MainActor.run {
            notificationPermissionStatus = settings.authorizationStatus
        }
    }
    
    private func handleEnablePreciseLocation() {
        // Check current authorization and handle accordingly
        switch locationService.authorizationStatus {
        case .notDetermined:
            // Request permission directly
            locationService.requestLocationPermission()
        case .denied, .restricted:
            // Must go to settings
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        case .authorizedWhenInUse, .authorizedAlways:
            // Already have permission, refresh location
            locationService.requestLocation()
        @unknown default:
            break
        }
    }
}

// MARK: - Subviews

struct LocationHeaderView: View {
    let locationData: LocationData?
    let currentUV: UVData?
    let isStale: Bool
    let onRefresh: () async -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let location = locationData {
                    Text(location.shortDisplayName)
                        .font(.headline)
                    
                    HStack(spacing: 4) {
                        Image(systemName: location.locationIcon)
                            .font(.caption2)
                            .foregroundColor(location.isVPN ? .orange : .secondary)
                        
                        Text(locationStatusText(location))
                            .font(.caption)
                        
                        Text("•")
                            .font(.caption)
                        
                        Text("Updated \(formattedTime(location.lastUpdated))")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                } else {
                    Text("Location unavailable")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if isStale {
                Button(action: { Task { await onRefresh() } }) {
                    Label("Update", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            if let temp = currentUV?.temperature {
                HStack(spacing: 4) {
                    Image(systemName: weatherIcon(for: currentUV?.weatherCondition))
                        .font(.title2)
                    Text("\(Int(temp))°")
                        .font(.title3)
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func weatherIcon(for condition: String?) -> String {
        // Simple mapping - can be expanded
        guard let condition = condition?.lowercased() else { return "sun.max" }
        
        if condition.contains("cloud") { return "cloud.sun" }
        if condition.contains("rain") { return "cloud.rain" }
        if condition.contains("clear") || condition.contains("sun") { return "sun.max" }
        return "sun.max"
    }
    
    private func locationStatusText(_ location: LocationData) -> String {
        switch location.locationType {
        case .precise:
            return "Using your location"
        case .approximate:
            return "IP-based location"
        case .vpn:
            return "VPN location"
        case .manual:
            return "Manual location"
        }
    }
}

struct CurrentConditionsCard: View {
    let uvData: UVData?
    let burnTime: BurnTimeCalculator.BurnTimeResult?
    let sunscreenWindow: (start: Date?, end: Date?)
    let currentSunscreen: SunscreenApplication?
    let onApplySunscreen: () -> Void
    let onRemoveSunscreen: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // UV Index Display
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current UV Index")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let uv = uvData {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("\(Int(uv.uvIndex))")
                                .font(.system(size: 64, weight: .semibold))
                            
                            VStack(alignment: .leading) {
                                Text(uv.uvLevel.description)
                                    .font(.headline)
                                Text(uv.uvLevel.recommendation)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        Text("--")
                            .font(.system(size: 64, weight: .semibold))
                    }
                }
                
                Spacer()
            }
            
            // Burn Time - only show if UV > 0
            if let burnTime = burnTime,
               let uvData = uvData,
               uvData.uvIndex > 0 {
                HStack {
                    Label("Sunburn within", systemImage: "timer")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(burnTime.displayText)
                        .font(.headline)
                        .foregroundColor(burnTimeWarningColor(burnTime.warningLevel))
                }
                .padding()
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(8)
            }
            
            // Sunscreen Status Section
            Divider()
            
            VStack(spacing: 12) {
                if let sunscreen = currentSunscreen {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("SPF \(sunscreen.spfValue) • \(sunscreen.quantity.displayName)")
                                .font(.headline)
                            
                            Text("Applied \(formattedTime(sunscreen.appliedAt))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(sunscreen.statusDescription)
                                .font(.caption)
                                .foregroundColor(sunscreen.needsReapplication ? .orange : .secondary)
                            
                            Button(action: onRemoveSunscreen) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Always show Apply Sunscreen button
                Button(action: onApplySunscreen) {
                    Label(currentSunscreen != nil ? "Reapply Sunscreen" : "Apply Sunscreen", 
                          systemImage: "sun.max.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}



struct QuickActionsSection: View {
    let hasProfile: Bool
    let notificationStatus: UNAuthorizationStatus
    let hasAlwaysLocation: Bool
    let onSetupProfile: () -> Void
    let onEnableNotifications: () -> Void
    
    var buttonTitle: String {
        if notificationStatus != .authorized && !hasAlwaysLocation {
            return "Enable Leave-Home Reminders"
        } else if notificationStatus != .authorized {
            return "Enable Notifications"
        } else if !hasAlwaysLocation {
            return "Enable Background Location"
        } else {
            return "Enable Leave-Home Reminders"
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            if !hasProfile {
                Button(action: onSetupProfile) {
                    Label("Customize for my skin", systemImage: "person.crop.circle.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            
            // Show button if either notification or Always location not granted
            if notificationStatus != .authorized || !hasAlwaysLocation {
                Button(action: onEnableNotifications) {
                    Label(buttonTitle, systemImage: "bell.badge")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
    }
}