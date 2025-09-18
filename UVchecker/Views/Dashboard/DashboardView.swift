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
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    private var currentSkinProfile: SkinProfile? {
        skinProfiles.first
    }
    
    private var currentSunscreen: SunscreenApplication? {
        sunscreenApplications.first { !$0.needsReapplication }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Location Header
                    LocationHeaderView(
                        locationData: locationService.currentLocationData,
                        currentUV: weatherService.currentUVData,
                        isStale: weatherService.currentUVData?.isStale ?? false,
                        onRefresh: refreshData
                    )
                    
                    // Current Conditions Card (with integrated sunscreen)
                    CurrentConditionsCard(
                        uvData: weatherService.currentUVData,
                        burnTime: currentBurnTime,
                        sunscreenWindow: weatherService.calculateSunscreenWindow(),
                        currentSunscreen: currentSunscreen,
                        onApplySunscreen: { showingSunscreenSheet = true },
                        onRemoveSunscreen: removeSunscreen
                    )
                    
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
                        onSetupProfile: { showingSkinProfileWizard = true },
                        onEnableNotifications: enableNotifications
                    )
                }
                .padding(.bottom, 20)
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
            .task {
                await initialLoad()
                await checkNotificationPermission()
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
        
        // If we already have permission, request location and load weather data
        if locationService.authorizationStatus == .authorizedAlways || 
           locationService.authorizationStatus == .authorizedWhenInUse {
            // Request current location
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
            let notificationService = NotificationService.shared
            _ = await notificationService.requestNotificationPermission()
            await checkNotificationPermission()
        }
    }
    
    private func checkNotificationPermission() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        await MainActor.run {
            notificationPermissionStatus = settings.authorizationStatus
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
                        Image(systemName: "location.fill")
                            .font(.caption2)
                        
                        Text(location.isManuallySet ? "Manual location" : "Using your location")
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
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
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
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
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
    let onSetupProfile: () -> Void
    let onEnableNotifications: () -> Void
    
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
            
            // Only show notification button if permission not granted
            if notificationStatus != .authorized {
                Button(action: onEnableNotifications) {
                    Label("Enable Leave-Home Reminders", systemImage: "bell.badge")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .padding(.horizontal)
    }
}