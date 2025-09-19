import SwiftUI

struct TomorrowWeatherView: View {
    let hourlyData: [HourlyUVData]
    
    private var maxUV: Double {
        hourlyData.map { $0.uvIndex }.max() ?? 0
    }
    
    private var minTemp: Double? {
        hourlyData.compactMap { $0.temperature }.min()
    }
    
    private var maxTemp: Double? {
        hourlyData.compactMap { $0.temperature }.max()
    }
    
    private var averageCloudCover: Double {
        let cloudValues = hourlyData.compactMap { $0.cloudCover }
        guard !cloudValues.isEmpty else { return 0 }
        return cloudValues.reduce(0, +) / Double(cloudValues.count)
    }
    
    private var weatherCondition: String {
        if averageCloudCover < 0.25 {
            return "Clear"
        } else if averageCloudCover < 0.5 {
            return "Partly Cloudy"
        } else if averageCloudCover < 0.75 {
            return "Mostly Cloudy"
        } else {
            return "Cloudy"
        }
    }
    
    private var weatherIcon: String {
        if averageCloudCover < 0.25 {
            return "sun.max"
        } else if averageCloudCover < 0.5 {
            return "cloud.sun"
        } else {
            return "cloud"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("Tomorrow's Weather")
                .font(.headline)
            
            if hourlyData.isEmpty {
                Text("Tomorrow's forecast not available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 12) {
                    // Combined weather info in one row
                    HStack(spacing: 16) {
                        // Weather condition
                        HStack(spacing: 4) {
                            Image(systemName: weatherIcon)
                                .font(.caption)
                                .foregroundColor(.blue)
                            Text(weatherCondition)
                                .font(.subheadline)
                        }
                        
                        // Temperature range
                        if let minT = minTemp, let maxT = maxTemp {
                            HStack(spacing: 4) {
                                Image(systemName: "thermometer")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(Int(minT))°-\(Int(maxT))°")
                                    .font(.subheadline)
                            }
                        }
                        
                        // Max UV
                        HStack(spacing: 4) {
                            Image(systemName: "sun.max.fill")
                                .font(.caption)
                                .foregroundColor(uvColor(for: maxUV))
                            Text("UV \(Int(maxUV))")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                    }
                    
                    // Sunblock needed window
                    if let sunblockWindow = findSunblockWindow() {
                        HStack {
                            Image(systemName: "sun.max.trianglebadge.exclamationmark")
                                .foregroundColor(.orange)
                            Text("Sunblock needed from \(sunblockWindow)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func findSunblockWindow() -> String? {
        guard !hourlyData.isEmpty else { return nil }
        
        // Find hours where UV index is 3 or higher (sunblock needed)
        let sunblockHours = hourlyData.filter { $0.uvIndex >= 3.0 }
        
        guard !sunblockHours.isEmpty,
              let firstHour = sunblockHours.first?.hour,
              let lastHour = sunblockHours.last?.hour else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        
        let startTime = formatter.string(from: firstHour).lowercased()
        // Add 1 hour to the last hour to show the end of the protection window
        let endHour = lastHour.addingTimeInterval(3600)
        let endTime = formatter.string(from: endHour).lowercased()
        
        if startTime == endTime {
            return nil // No window if same time
        } else {
            return "\(startTime) to \(endTime)"
        }
    }
    
    private func uvColor(for value: Double) -> Color {
        switch value {
        case 0..<3:
            return .green
        case 3..<6:
            return .yellow
        case 6..<8:
            return .orange
        case 8..<11:
            return .red
        default:
            return .purple
        }
    }
    
    private func uvDescription(for value: Double) -> String {
        switch value {
        case 0..<3:
            return "Low"
        case 3..<6:
            return "Moderate"
        case 6..<8:
            return "High"
        case 8..<11:
            return "Very High"
        default:
            return "Extreme"
        }
    }
}