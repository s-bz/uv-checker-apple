import SwiftUI

struct AnalyticsInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .font(.largeTitle)
                                .foregroundColor(.purple)
                            Spacer()
                        }
                        Text("Analytics Information")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("How we use anonymous data to improve UV Sense")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // What we collect
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What We Collect")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            AnalyticsDataPoint(
                                icon: "hand.tap",
                                title: "App Usage",
                                description: "Which features you use and how often"
                            )
                            
                            AnalyticsDataPoint(
                                icon: "sun.max",
                                title: "UV Interactions",
                                description: "How you interact with UV data and timeline"
                            )
                            
                            AnalyticsDataPoint(
                                icon: "drop.circle",
                                title: "Sunscreen Usage",
                                description: "Anonymous sunscreen application patterns"
                            )
                            
                            AnalyticsDataPoint(
                                icon: "location.circle",
                                title: "Location Settings",
                                description: "Permission status (not your actual location)"
                            )
                            
                            AnalyticsDataPoint(
                                icon: "exclamationmark.triangle",
                                title: "Error Reports",
                                description: "Crashes and technical issues to fix bugs"
                            )
                        }
                    }
                    
                    // What we don't collect
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What We DON'T Collect")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            AnalyticsDataPoint(
                                icon: "location.slash",
                                title: "Your Location",
                                description: "We never collect your actual GPS coordinates",
                                isPositive: false
                            )
                            
                            AnalyticsDataPoint(
                                icon: "person.crop.circle.badge.xmark",
                                title: "Personal Information",
                                description: "No names, emails, or identifying information",
                                isPositive: false
                            )
                            
                            AnalyticsDataPoint(
                                icon: "eye.slash",
                                title: "Screen Content",
                                description: "We don't record or capture your screen",
                                isPositive: false
                            )
                            
                            AnalyticsDataPoint(
                                icon: "mic.slash",
                                title: "Audio or Camera",
                                description: "No access to microphone or camera data",
                                isPositive: false
                            )
                        }
                    }
                    
                    // Privacy commitment
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Our Privacy Commitment")
                            .font(.headline)
                        
                        Text("All data is completely anonymous and cannot be traced back to you. We use this information solely to:")
                            .font(.body)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .top) {
                                Text("•")
                                Text("Understand which features are most useful")
                            }
                            HStack(alignment: .top) {
                                Text("•")
                                Text("Identify and fix bugs or crashes")
                            }
                            HStack(alignment: .top) {
                                Text("•")
                                Text("Improve app performance and user experience")
                            }
                            HStack(alignment: .top) {
                                Text("•")
                                Text("Make informed decisions about new features")
                            }
                        }
                        .font(.body)
                        .padding(.leading)
                    }
                    
                    // Control section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Control")
                            .font(.headline)
                        
                        Text("You can disable analytics at any time in Settings → Privacy → Analytics. This will:")
                            .font(.body)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .top) {
                                Text("•")
                                Text("Stop all data collection immediately")
                            }
                            HStack(alignment: .top) {
                                Text("•")
                                Text("Not affect any app functionality")
                            }
                            HStack(alignment: .top) {
                                Text("•")
                                Text("Remain disabled until you choose to re-enable it")
                            }
                        }
                        .font(.body)
                        .padding(.leading)
                    }
                    
                    Spacer(minLength: 24)
                }
                .padding()
            }
            .navigationTitle("Analytics")
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

struct AnalyticsDataPoint: View {
    let icon: String
    let title: String
    let description: String
    var isPositive: Bool = true
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isPositive ? .blue : .green)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AnalyticsInfoView()
}