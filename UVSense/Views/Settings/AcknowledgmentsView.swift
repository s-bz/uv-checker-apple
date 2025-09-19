import SwiftUI

struct AcknowledgmentsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .font(.largeTitle)
                                .foregroundColor(.red)
                            Spacer()
                        }
                        Text("Acknowledgments")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Libraries, tools, and services that make UV Sense possible")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Open Source Libraries
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Open Source Libraries")
                            .font(.headline)
                        
                        AcknowledgmentCard(
                            name: "PostHog",
                            description: "Privacy-focused product analytics platform for understanding user behavior and improving app experience.",
                            url: "https://posthog.com",
                            license: "MIT License"
                        )
                        
                        AcknowledgmentCard(
                            name: "SwiftUI",
                            description: "Apple's declarative UI framework that powers the beautiful and responsive user interface.",
                            url: "https://developer.apple.com/swiftui/",
                            license: "Apple Developer License"
                        )
                        
                        AcknowledgmentCard(
                            name: "WeatherKit",
                            description: "Apple's weather service providing accurate UV index data and forecasts worldwide.",
                            url: "https://developer.apple.com/weatherkit/",
                            license: "Apple Developer License"
                        )
                        
                        AcknowledgmentCard(
                            name: "CoreLocation",
                            description: "Apple's location services framework for precise and privacy-aware location detection.",
                            url: "https://developer.apple.com/documentation/corelocation",
                            license: "Apple Developer License"
                        )
                        
                        AcknowledgmentCard(
                            name: "WidgetKit",
                            description: "Apple's framework for creating beautiful and informative home screen widgets.",
                            url: "https://developer.apple.com/documentation/widgetkit",
                            license: "Apple Developer License"
                        )
                        
                        AcknowledgmentCard(
                            name: "SwiftData",
                            description: "Apple's modern data persistence framework for storing user preferences and UV data.",
                            url: "https://developer.apple.com/documentation/swiftdata",
                            license: "Apple Developer License"
                        )
                    }
                    
                    // Data Sources
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Data Sources")
                            .font(.headline)
                        
                        AcknowledgmentCard(
                            name: "Apple Weather Services",
                            description: "Providing accurate, real-time UV index data and weather forecasts through WeatherKit.",
                            url: "https://weather.apple.com",
                            license: "Commercial License"
                        )
                        
                        AcknowledgmentCard(
                            name: "IP Geolocation API",
                            description: "Fallback location service for users with restricted location permissions.",
                            url: "https://ip-api.com",
                            license: "Commercial License"
                        )
                    }
                    
                    
                    // Scientific Resources
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Scientific Resources")
                            .font(.headline)
                        
                        AcknowledgmentCard(
                            name: "World Health Organization",
                            description: "UV protection guidelines and skin type classifications used in burn time calculations.",
                            url: "https://www.who.int/news-room/q-a-detail/radiation-ultraviolet-(uv)",
                            license: "Public Domain"
                        )
                        
                        AcknowledgmentCard(
                            name: "Fitzpatrick Scale",
                            description: "Scientific classification system for skin types and UV sensitivity used in the app.",
                            url: "https://en.wikipedia.org/wiki/Fitzpatrick_scale",
                            license: "Scientific Literature"
                        )
                    }
                    
                    // Special Thanks
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Special Thanks")
                            .font(.headline)
                        
                        Text("To everyone who believes in the importance of sun protection and helped make this app a reality. Your feedback, testing, and support have been invaluable in creating a tool that helps people stay safe under the sun.")
                            .font(.body)
                        
                        Text("UV Sense is committed to privacy, accuracy, and helping you enjoy the sun safely. Thank you for trusting us with your sun protection needs.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer(minLength: 24)
                }
                .padding()
            }
            .navigationTitle("Acknowledgments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AcknowledgmentCard: View {
    let name: String
    let description: String
    let url: String
    let license: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text(license)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let validURL = URL(string: url) {
                Link(destination: validURL) {
                    HStack {
                        Text(url)
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "arrow.up.forward.square")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
    }
}

#Preview {
    AcknowledgmentsView()
}