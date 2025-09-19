//
//  UVSenseApp.swift
//  UV Sense
//
//  Created by Samuel Bultez on 18/9/2025.
//

import SwiftUI
import SwiftData

@main
struct UVSenseApp: App {
    @StateObject private var postHogManager = PostHogManager.shared
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            UVData.self,
            HourlyUVData.self,
            SkinProfile.self,
            SunscreenApplication.self,
            LocationData.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init() {
        // Initialize PostHog early
        _ = PostHogManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(postHogManager)
                .task {
                    // Track app launch
                    postHogManager.capture(PostHogEvents.App.launched)
                    
                    // Check if widget was viewed
                    if UserDefaults.standard.bool(forKey: "widget_viewed") {
                        postHogManager.capture(PostHogEvents.Widget.viewed)
                        UserDefaults.standard.removeObject(forKey: "widget_viewed")
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    // Track app foregrounded
                    postHogManager.capture(PostHogEvents.App.foregrounded)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    // Track app backgrounded
                    postHogManager.capture(PostHogEvents.App.backgrounded)
                    postHogManager.flush()
                }
                .onOpenURL { url in
                    // Handle widget URL
                    if url.scheme == "uvsense" && url.host == "widget" {
                        postHogManager.capture(PostHogEvents.Widget.tapped)
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
