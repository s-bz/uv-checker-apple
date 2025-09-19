//
//  Widget.swift
//  Widget
//
//  Created by Samuel Bultez on 19/9/2025.
//

import WidgetKit
import SwiftUI
import CoreLocation

struct UVProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> UVWidgetEntry {
        UVWidgetEntry(
            date: Date(),
            configuration: ConfigurationAppIntent(),
            uvIndex: 5.0,
            uvLevel: .moderate,
            location: "San Francisco",
            temperature: 72,
            burnTime: 30,
            sunscreenActive: false,
            sunscreenSPF: nil,
            nextHighUVTime: nil,
            isDataStale: false
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> UVWidgetEntry {
        // For preview and quick look
        return UVWidgetEntry(
            date: Date(),
            configuration: configuration,
            uvIndex: 7.0,
            uvLevel: .high,
            location: "Current Location",
            temperature: 75,
            burnTime: 20,
            sunscreenActive: true,
            sunscreenSPF: 30,
            nextHighUVTime: Calendar.current.date(byAdding: .hour, value: 2, to: Date()),
            isDataStale: false
        )
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<UVWidgetEntry> {
        var entries: [UVWidgetEntry] = []
        
        // Get current UV data from shared container/app group
        let currentData = await fetchCurrentUVData()
        
        // Generate timeline entries for next 4 hours
        let currentDate = Date()
        for hourOffset in 0..<4 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            
            // Create entry with fetched or mock data
            let entry = UVWidgetEntry(
                date: entryDate,
                configuration: configuration,
                uvIndex: currentData?.uvIndex ?? 0,
                uvLevel: UVWidgetLevel(fromIndex: currentData?.uvIndex ?? 0),
                location: currentData?.location ?? "Unknown",
                temperature: currentData?.temperature,
                burnTime: currentData?.burnTime,
                sunscreenActive: currentData?.sunscreenActive ?? false,
                sunscreenSPF: currentData?.sunscreenSPF,
                nextHighUVTime: currentData?.nextHighUVTime,
                isDataStale: hourOffset > 0 // Mark as stale after first hour
            )
            entries.append(entry)
        }
        
        // Refresh every hour
        let refreshDate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        return Timeline(entries: entries, policy: .after(refreshDate))
    }
    
    private func fetchCurrentUVData() async -> (uvIndex: Double, location: String, temperature: Double?, burnTime: Int?, sunscreenActive: Bool, sunscreenSPF: Int?, nextHighUVTime: Date?)? {
        // Fetch actual data from shared container
        guard let sharedData = WidgetDataManager.shared.getSharedData() else {
            // Return placeholder data if no real data available
            return (
                uvIndex: 0,
                location: "No Data",
                temperature: nil,
                burnTime: nil,
                sunscreenActive: false,
                sunscreenSPF: nil,
                nextHighUVTime: nil
            )
        }
        
        return (
            uvIndex: sharedData.uvIndex,
            location: sharedData.location,
            temperature: sharedData.temperature,
            burnTime: sharedData.burnTime,
            sunscreenActive: sharedData.sunscreenActive,
            sunscreenSPF: sharedData.sunscreenSPF,
            nextHighUVTime: sharedData.nextHighUVTime
        )
    }
}

// MARK: - Widget Views

struct UVWidgetEntryView : View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: UVProvider.Entry

    var body: some View {
        Group {
            switch widgetFamily {
            case .systemSmall:
                SmallWidgetView(entry: entry)
            case .systemMedium:
                MediumWidgetView(entry: entry)
            case .accessoryRectangular:
                AccessoryRectangularView(entry: entry)
            case .accessoryCircular:
                AccessoryCircularView(entry: entry)
            case .accessoryInline:
                AccessoryInlineView(entry: entry)
            default:
                SmallWidgetView(entry: entry)
            }
        }
        .onAppear {
            // Track widget view
            UserDefaults.standard.set(true, forKey: "widget_viewed")
        }
        .widgetURL(URL(string: "uvsense://widget")!)
    }
}

// Small Widget
struct SmallWidgetView: View {
    let entry: UVWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Header row with location and temp - like Apple Weather
            HStack {
                Text(entry.location.components(separatedBy: ",").first ?? entry.location)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Spacer()
                
                if let temp = entry.temperature {
                    Text("\(Int(temp))°")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            // UV Index and Level on same line
            HStack(alignment: .bottom, spacing: 8) {
                Text("\(Int(entry.uvIndex))")
                    .font(.system(size: 48, weight: .light, design: .rounded))
                    .foregroundColor(entry.uvLevel.color)
                    .minimumScaleFactor(0.7)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(entry.uvLevel.rawValue)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(entry.uvLevel.color)
                        .lineLimit(1)
                    Text("UV")
                        .font(.system(size: 17, weight: .medium))  // Same style as "Low"
                        .foregroundColor(entry.uvLevel.color)
                }
                .padding(.bottom, 6) // Better alignment with number baseline
                
                Spacer()
            }
            
            Spacer(minLength: 0)
            
            // Bottom info - with multiline support
            VStack(alignment: .leading, spacing: 3) {
                // Protection status - larger font and multiline
                if entry.configuration.showBurnTime, let burnTimeText = entry.formattedBurnTime() {
                    if entry.sunscreenActive, let spf = entry.sunscreenSPF {
                        // Show sunscreen protection with expiry time
                        if let burnTime = entry.burnTime {
                            let protectedUntil = Date().addingTimeInterval(TimeInterval(burnTime * 60))
                            Text("Protected by SPF\(spf) until \(protectedUntil, style: .time)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.green)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            Text("Protected by SPF\(spf)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.green)
                        }
                    } else if burnTimeText == "Safe without sunscreen" {
                        Text("Protected")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.green)
                    } else {
                        // Show when sunscreen is needed
                        if entry.uvIndex >= 3, let burnTime = entry.burnTime {
                            let needsSunscreenUntil = Date().addingTimeInterval(TimeInterval(burnTime * 60))
                            Text("Sunscreen needed until \(needsSunscreenUntil, style: .time)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.orange)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            HStack(spacing: 2) {
                                Image(systemName: "timer")
                                    .font(.system(size: 10))
                                Text(burnTimeText.replacingOccurrences(of: " min", with: "m"))
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(entry.burnTime ?? 60 < 30 ? .orange : .secondary)
                        }
                    }
                }
                
                // Last updated
                Text("Updated \(entry.date, style: .time)")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary.opacity(0.7))
            }
        }
        .padding(6) // Minimal padding like Apple Weather widget
    }
}

// Medium Widget
struct MediumWidgetView: View {
    let entry: UVWidgetEntry
    
    var body: some View {
        HStack(spacing: 12) {
            // Left side - UV Info
            VStack(alignment: .leading, spacing: 4) {
                // Location and temp header
                HStack {
                    Text(entry.location.components(separatedBy: ",").first ?? entry.location)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if let temp = entry.temperature {
                        Text("\(Int(temp))°")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                // UV Index and Level with bottom alignment
                HStack(alignment: .bottom, spacing: 6) {
                    Text("\(Int(entry.uvIndex))")
                        .font(.system(size: 42, weight: .light, design: .rounded))
                        .foregroundColor(entry.uvLevel.color)
                        .minimumScaleFactor(0.8)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text(entry.uvLevel.rawValue)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(entry.uvLevel.color)
                            .lineLimit(1)
                        Text("UV")
                            .font(.system(size: 15, weight: .medium))  // Same style as level text
                            .foregroundColor(entry.uvLevel.color)
                    }
                    .padding(.bottom, 5) // Better alignment with number baseline
                }
                
                Spacer(minLength: 2)
                
                Text("Updated \(entry.date, style: .time)")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            
            Divider()
                .padding(.vertical, 4)
            
            // Right side - Recommendations
            VStack(alignment: .leading, spacing: 6) {
                // Show recommendation based on burn time and sunscreen status
                if entry.configuration.showBurnTime, let burnTimeText = entry.formattedBurnTime() {
                    if entry.sunscreenActive, let spf = entry.sunscreenSPF {
                        // Show sunscreen protection with expiry time
                        Text("Protected by SPF\(spf)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        if let burnTime = entry.burnTime {
                            let protectedUntil = Date().addingTimeInterval(TimeInterval(burnTime * 60))
                            HStack(spacing: 3) {
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.system(size: 10))
                                Text("Until \(protectedUntil, style: .time)")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(.green)
                        } else {
                            HStack(spacing: 3) {
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.system(size: 10))
                                Text("Active")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(.green)
                        }
                    } else if burnTimeText == "Safe without sunscreen" {
                        Text("No protection needed")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 10))
                            Text("Safe")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.green)
                    } else {
                        // Show when sunscreen is needed
                        if entry.uvIndex >= 3, let burnTime = entry.burnTime {
                            let needsSunscreenUntil = Date().addingTimeInterval(TimeInterval(burnTime * 60))
                            
                            Text("Sunscreen needed")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            HStack(spacing: 3) {
                                Image(systemName: "sun.max.trianglebadge.exclamationmark")
                                    .font(.system(size: 10))
                                Text("Until \(needsSunscreenUntil, style: .time)")
                                    .font(.system(size: 11))
                            }
                            .foregroundColor(.orange)
                        } else {
                            Text(entry.uvLevel.recommendation)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.primary)
                                .lineLimit(2)
                            
                            HStack(spacing: 3) {
                                Image(systemName: "timer")
                                    .font(.system(size: 10))
                                Text(burnTimeText)
                                    .font(.system(size: 11))
                            }
                            .foregroundColor(entry.burnTime ?? 60 < 30 ? .orange : .secondary)
                        }
                    }
                } else {
                    Text(entry.uvLevel.recommendation)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }
                
                if entry.configuration.showSunscreenStatus {
                    HStack(spacing: 3) {
                        Image(systemName: entry.sunscreenActive ? "checkmark.shield.fill" : "shield.slash")
                            .font(.system(size: 10))
                        if entry.sunscreenActive, let spf = entry.sunscreenSPF {
                            Text("SPF \(spf)")
                                .font(.system(size: 11))
                        } else {
                            Text("No sunscreen")
                                .font(.system(size: 11))
                        }
                    }
                    .foregroundColor(entry.sunscreenActive ? .green : .orange)
                }
                
                Spacer()
                
                if let nextHigh = entry.nextHighUVTime {
                    Text("High UV at \(nextHigh, style: .time)")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        }
        .padding(6) // Minimal padding like Apple Weather widget
    }
}

// Accessory Widgets
struct AccessoryRectangularView: View {
    let entry: UVWidgetEntry
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("UV")
                    .font(.caption2)
                HStack(spacing: 4) {
                    Text("\(Int(entry.uvIndex))")
                        .font(.title2.bold())
                    Image(systemName: entry.uvLevel.icon)
                        .font(.caption)
                }
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(entry.uvLevel.rawValue)
                    .font(.caption2)
                if let burnTimeText = entry.formattedBurnTime() {
                    // For accessory widget, show abbreviated version
                    if burnTimeText == "Safe without sunscreen" {
                        Text("Safe")
                            .font(.caption.bold())
                    } else {
                        Text(burnTimeText.replacingOccurrences(of: " min", with: "m"))
                            .font(.caption.bold())
                    }
                }
            }
        }
    }
}

struct AccessoryCircularView: View {
    let entry: UVWidgetEntry
    
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Image(systemName: entry.uvLevel.icon)
                    .font(.caption)
                Text("\(Int(entry.uvIndex))")
                    .font(.title3.bold())
                Text(entry.uvLevel.rawValue)
                    .font(.system(size: 8))
            }
        }
    }
}

struct AccessoryInlineView: View {
    let entry: UVWidgetEntry
    
    var body: some View {
        Label("UV \(Int(entry.uvIndex)) • \(entry.uvLevel.rawValue)", systemImage: entry.uvLevel.icon)
    }
}

// Main Widget Configuration
struct UVWidget: Widget {
    let kind: String = "UVWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: UVProvider()
        ) { entry in
            UVWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("UV Index")
        .description("Monitor current UV levels and sun protection recommendations")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// Preview
#Preview(as: .systemSmall) {
    UVWidget()
} timeline: {
    UVWidgetEntry(
        date: .now,
        configuration: ConfigurationAppIntent(),
        uvIndex: 3.0,
        uvLevel: .moderate,
        location: "San Francisco",
        temperature: 68,
        burnTime: 45,
        sunscreenActive: false,
        sunscreenSPF: nil,
        nextHighUVTime: nil,
        isDataStale: false
    )
    UVWidgetEntry(
        date: .now,
        configuration: ConfigurationAppIntent(),
        uvIndex: 8.0,
        uvLevel: .veryHigh,
        location: "Miami Beach",
        temperature: 85,
        burnTime: 15,
        sunscreenActive: true,
        sunscreenSPF: 50,
        nextHighUVTime: Date(),
        isDataStale: false
    )
}

// MARK: - Helper Functions

extension UVWidgetEntry {
    /// Formats burn time in a human-readable format matching the main app
    func formattedBurnTime() -> String? {
        guard let burnTime = burnTime else { return nil }
        
        if burnTime >= 240 {
            return "Safe without sunscreen"
        } else if burnTime >= 60 {
            let hours = burnTime / 60
            let minutes = burnTime % 60
            
            // Round up to nearest half hour
            let roundedMinutes: Int
            if minutes == 0 {
                roundedMinutes = 0
            } else if minutes <= 30 {
                roundedMinutes = 30
            } else {
                // Round up to next hour
                return "\(hours + 1)h"
            }
            
            if roundedMinutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(roundedMinutes)m"
            }
        } else {
            return "\(burnTime) min"
        }
    }
}