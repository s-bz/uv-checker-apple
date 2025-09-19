import Foundation
import UserNotifications
import Combine

@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        checkAuthorizationStatus()
        setupNotificationObservers()
    }
    
    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { settings in
            Task { @MainActor in
                self.authorizationStatus = settings.authorizationStatus
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            
            await MainActor.run {
                self.isAuthorized = granted
                self.authorizationStatus = granted ? .authorized : .denied
            }
            
            return granted
        } catch {
            print("Error requesting notification permission: \(error)")
            return false
        }
    }
    
    private func setupNotificationObservers() {
        // Listen for leave-home events from LocationService
        NotificationCenter.default.publisher(for: Notification.Name("UserLeftHome"))
            .sink { [weak self] _ in
                Task {
                    await self?.scheduleLeaveHomeReminder()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Notification Scheduling
    
    func scheduleLeaveHomeReminder() async {
        guard isAuthorized else { return }
        
        // Check current UV level
        let weatherService = WeatherKitService.shared
        guard let currentUV = weatherService.currentUVData else { return }
        
        // Only notify if UV is 3 or higher
        if currentUV.uvIndex >= 3 {
            let content = UNMutableNotificationContent()
            content.title = "UV Protection Reminder"
            content.body = "UV index is \(Int(currentUV.uvIndex)). Don't forget sunscreen before going outside!"
            content.sound = .default
            content.categoryIdentifier = "UV_REMINDER"
            
            // Add action buttons
            content.userInfo = ["type": "leave_home", "uvIndex": currentUV.uvIndex]
            
            let request = UNNotificationRequest(
                identifier: "leave-home-\(Date().timeIntervalSince1970)",
                content: content,
                trigger: nil // Immediate delivery
            )
            
            do {
                try await notificationCenter.add(request)
            } catch {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func scheduleSunscreenReapplication(at date: Date, spf: Int) async {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Time to Reapply Sunscreen"
        content.body = "Your SPF \(spf) sunscreen needs to be reapplied for continued protection"
        content.sound = .default
        content.categoryIdentifier = "SUNSCREEN_REAPPLY"
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: date.timeIntervalSinceNow,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "sunscreen-reapply-\(date.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
        } catch {
            print("Error scheduling reapplication reminder: \(error)")
        }
    }
    
    func cancelSunscreenReminders() {
        notificationCenter.getDeliveredNotifications { [weak self] delivered in
            guard let self else { return }
            let sunscreenIds = delivered
                .filter { $0.request.content.categoryIdentifier == "SUNSCREEN_REAPPLY" }
                .map { $0.request.identifier }
            
            Task { @MainActor in
                self.notificationCenter.removeDeliveredNotifications(withIdentifiers: sunscreenIds)
            }
        }
        
        notificationCenter.getPendingNotificationRequests { [weak self] pending in
            guard let self else { return }
            let sunscreenIds = pending
                .filter { $0.content.categoryIdentifier == "SUNSCREEN_REAPPLY" }
                .map { $0.identifier }
            
            Task { @MainActor in
                self.notificationCenter.removePendingNotificationRequests(withIdentifiers: sunscreenIds)
            }
        }
    }
    
    func setupNotificationCategories() {
        let appliedAction = UNNotificationAction(
            identifier: "APPLIED_SUNSCREEN",
            title: "Applied Sunscreen",
            options: [.foreground]
        )
        
        let remindLaterAction = UNNotificationAction(
            identifier: "REMIND_LATER",
            title: "Remind in 30 min",
            options: []
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Dismiss",
            options: [.destructive]
        )
        
        let uvReminderCategory = UNNotificationCategory(
            identifier: "UV_REMINDER",
            actions: [appliedAction, remindLaterAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        let sunscreenCategory = UNNotificationCategory(
            identifier: "SUNSCREEN_REAPPLY",
            actions: [appliedAction, remindLaterAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([uvReminderCategory, sunscreenCategory])
    }
}