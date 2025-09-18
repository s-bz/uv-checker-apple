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
        switch widgetFamily {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
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
}

// Small Widget
struct SmallWidgetView: View {
    let entry: UVWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: entry.uvLevel.icon)
                    .font(.title2)
                    .foregroundColor(entry.uvLevel.color)
                Spacer()
                if entry.isDataStale {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            // UV Index
            VStack(alignment: .leading, spacing: 4) {
                Text("\(Int(entry.uvIndex))")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(entry.uvLevel.color)
                
                Text(entry.uvLevel.rawValue)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Bottom info
            VStack(alignment: .leading, spacing: 2) {
                if entry.configuration.showBurnTime, let burnTime = entry.burnTime {
                    Label("\(burnTime) min", systemImage: "timer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Label(entry.location, systemImage: "location.fill")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding()
    }
}

// Medium Widget
struct MediumWidgetView: View {
    let entry: UVWidgetEntry
    
    var body: some View {
        HStack(spacing: 16) {
            // Left side - UV Info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: entry.uvLevel.icon)
                        .font(.title2)
                        .foregroundColor(entry.uvLevel.color)
                    
                    if let temp = entry.temperature {
                        Text("\(Int(temp))°")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int(entry.uvIndex))")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(entry.uvLevel.color)
                    
                    Text(entry.uvLevel.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                Label(entry.location, systemImage: "location.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Divider()
            
            // Right side - Recommendations
            VStack(alignment: .leading, spacing: 12) {
                Text(entry.uvLevel.recommendation)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if entry.configuration.showBurnTime, let burnTime = entry.burnTime {
                    HStack {
                        Image(systemName: "timer")
                            .font(.caption)
                        Text("Burn: \(burnTime) min")
                            .font(.caption)
                    }
                    .foregroundColor(burnTime < 30 ? .orange : .secondary)
                }
                
                if entry.configuration.showSunscreenStatus {
                    HStack {
                        Image(systemName: entry.sunscreenActive ? "checkmark.shield.fill" : "shield.slash")
                            .font(.caption)
                        if entry.sunscreenActive, let spf = entry.sunscreenSPF {
                            Text("SPF \(spf)")
                        } else {
                            Text("No sunscreen")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(entry.sunscreenActive ? .green : .orange)
                }
                
                Spacer()
                
                if let nextHigh = entry.nextHighUVTime {
                    Text("High UV at \(nextHigh, style: .time)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

// Large Widget
struct LargeWidgetView: View {
    let entry: UVWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("UV Index")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Label(entry.location, systemImage: "location.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if entry.isDataStale {
                    Label("Update needed", systemImage: "arrow.clockwise")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            // Main UV Display
            HStack(alignment: .top, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(Int(entry.uvIndex))")
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundColor(entry.uvLevel.color)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.uvLevel.rawValue.uppercased())
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            if let temp = entry.temperature {
                                Text("\(Int(temp))°")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    
                    Image(systemName: entry.uvLevel.icon)
                        .font(.title)
                        .foregroundColor(entry.uvLevel.color)
                }
                
                Spacer()
            }
            
            // Recommendation
            Text(entry.uvLevel.recommendation)
                .font(.headline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(entry.uvLevel.color.opacity(0.15))
                .cornerRadius(8)
            
            // Status Grid
            HStack(spacing: 16) {
                if entry.configuration.showBurnTime {
                    StatusCard(
                        icon: "timer",
                        title: "Burn Time",
                        value: entry.burnTime.map { "\($0) min" } ?? "N/A",
                        color: entry.burnTime ?? 60 < 30 ? .orange : .secondary
                    )
                }
                
                if entry.configuration.showSunscreenStatus {
                    StatusCard(
                        icon: entry.sunscreenActive ? "checkmark.shield.fill" : "shield.slash",
                        title: "Sunscreen",
                        value: entry.sunscreenActive && entry.sunscreenSPF != nil ? "SPF \(entry.sunscreenSPF!)" : "Not applied",
                        color: entry.sunscreenActive ? .green : .orange
                    )
                }
            }
            
            Spacer()
            
            // Footer
            HStack {
                Text("Updated \(entry.date, style: .time)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let nextHigh = entry.nextHighUVTime {
                    Label("High UV at \(nextHigh, style: .time)", systemImage: "sun.max.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
}

struct StatusCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
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
                if let burnTime = entry.burnTime {
                    Text("\(burnTime)m")
                        .font(.caption.bold())
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
            .systemLarge,
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