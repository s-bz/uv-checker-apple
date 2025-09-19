import SwiftUI

struct UVTimelineView: View {
    let hourlyData: [HourlyUVData]
    let sunscreenWindow: (start: Date?, end: Date?)
    @State private var selectedHour: Date?
    @State private var selectedHourData: HourlyUVData?
    
    init(hourlyData: [HourlyUVData], sunscreenWindow: (start: Date?, end: Date?)) {
        self.hourlyData = hourlyData
        self.sunscreenWindow = sunscreenWindow
        // Initialize with current hour selected
        let currentHour = Date()
        if let closestHour = hourlyData.min(by: { abs($0.hour.timeIntervalSince(currentHour)) < abs($1.hour.timeIntervalSince(currentHour)) }) {
            self._selectedHour = State(initialValue: closestHour.hour)
            self._selectedHourData = State(initialValue: closestHour)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("24-Hour Forecast")
                .font(.headline)
            
            // Sunscreen Window - only show when actually needed
            if let start = sunscreenWindow.start,
               let end = sunscreenWindow.end {
                HStack {
                    Image(systemName: "sun.max.trianglebadge.exclamationmark")
                        .foregroundColor(.orange)
                    
                    Text("Sunblock needed")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("\(formattedTime(start)) - \(formattedTime(end))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Timeline
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 2) {
                        ForEach(Array(hourlyData.prefix(24).enumerated()), id: \.element.hour) { index, hourData in
                            TimelineSegment(
                                hourData: hourData,
                                hour: Calendar.current.component(.hour, from: hourData.hour),
                                isSelected: isHourSelected(hourData.hour),
                                isPast: isPastHour(hourData.hour),
                                isCurrentHour: isCurrentHour(hourData.hour)
                            )
                            .onTapGesture {
                                selectedHour = hourData.hour
                                selectedHourData = hourData
                                
                                // Haptic feedback
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                            }
                            .id(hourData.hour)
                        }
                    }
                    .padding(.horizontal)
                }
                .onAppear {
                    // Scroll to current hour on appear with a slight delay to ensure layout is ready
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if let currentHourData = getCurrentHourData() {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(currentHourData.hour, anchor: .leading)
                            }
                        }
                    }
                }
            }
            
            // Selected hour details
            if let selectedData = selectedHourData,
               let selectedTime = selectedHour {
                SelectedHourDetails(
                    time: selectedTime,
                    uvData: selectedData
                )
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func isHourSelected(_ hour: Date) -> Bool {
        guard let selectedHour = selectedHour else { return false }
        return Calendar.current.isDate(hour, equalTo: selectedHour, toGranularity: .hour)
    }
    
    private func isPastHour(_ hour: Date) -> Bool {
        return hour < Date()
    }
    
    private func isCurrentHour(_ hour: Date) -> Bool {
        return Calendar.current.isDate(hour, equalTo: Date(), toGranularity: .hour)
    }
    
    private func getCurrentHourIndex() -> Int? {
        let currentHour = Calendar.current.component(.hour, from: Date())
        return hourlyData.firstIndex { hourData in
            Calendar.current.component(.hour, from: hourData.hour) == currentHour
        }
    }
    
    private func getCurrentHourData() -> HourlyUVData? {
        let currentHour = Date()
        return hourlyData.min(by: { abs($0.hour.timeIntervalSince(currentHour)) < abs($1.hour.timeIntervalSince(currentHour)) })
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct TimelineSegment: View {
    let hourData: HourlyUVData
    let hour: Int
    let isSelected: Bool
    let isPast: Bool
    let isCurrentHour: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            // Time label
            Text(timeLabel)
                .font(.system(size: 9))
                .foregroundColor(isSelected ? .primary : .secondary)
            
            // UV bar
            RoundedRectangle(cornerRadius: 4)
                .fill(colorForUVLevel(hourData.uvLevel))
                .opacity(isPast && !isCurrentHour ? 0.3 : 1.0)
                .frame(width: 32, height: barHeight)
                .overlay(
                    // UV index number
                    Text("\(Int(hourData.uvIndex))")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                )
                .overlay(
                    // Selection indicator
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.primary, lineWidth: 2)
                        .opacity(isSelected ? 1 : 0)
                )
                .overlay(
                    // Current hour indicator
                    isCurrentHour ?
                    VStack {
                        Spacer()
                        Circle()
                            .fill(Color.primary)
                            .frame(width: 6, height: 6)
                            .offset(y: 10)
                    } : nil
                )
        }
    }
    
    private var timeLabel: String {
        // Show label for every hour to avoid confusion
        if hour == 0 {
            return "12a"
        } else if hour < 12 {
            return "\(hour)a"
        } else if hour == 12 {
            return "12p"
        } else {
            return "\(hour - 12)p"
        }
    }
    
    private var barHeight: CGFloat {
        // Scale height based on UV index (max height 60)
        let maxHeight: CGFloat = 60
        let minHeight: CGFloat = 20
        let scaledHeight = minHeight + (maxHeight - minHeight) * CGFloat(hourData.uvIndex) / 11.0
        return scaledHeight
    }
    
    private func colorForUVLevel(_ level: UVLevel) -> Color {
        switch level {
        case .low:
            return Color.green
        case .moderate:
            return Color.yellow
        case .high:
            return Color.orange
        case .veryHigh:
            return Color.red
        case .extreme:
            return Color.purple
        }
    }
}

struct SelectedHourDetails: View {
    let time: Date
    let uvData: HourlyUVData
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formattedTime(time))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    // UV Index
                    VStack(alignment: .leading, spacing: 2) {
                        Text("UV Index")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(Int(uvData.uvIndex))")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text(uvData.uvLevel.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    // Conditions
                    if let temp = uvData.temperature {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Temperature")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(Int(temp))°")
                                .font(.title3)
                                .fontWeight(.medium)
                        }
                    }
                    
                    if let cloudCover = uvData.cloudCover, cloudCover > 0 {
                        Divider()
                            .frame(height: 30)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Cloud Cover")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(Int(cloudCover * 100))%")
                                .font(.title3)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Recommendation
            VStack(alignment: .trailing, spacing: 4) {
                Image(systemName: uvData.uvLevel.icon)
                    .font(.title2)
                    .foregroundColor(colorForUVLevel(uvData.uvLevel))
                
                Text(uvData.uvLevel.shortRecommendation)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding()
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(8)
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func colorForUVLevel(_ level: UVLevel) -> Color {
        switch level {
        case .low:
            return Color.green
        case .moderate:
            return Color.yellow
        case .high:
            return Color.orange
        case .veryHigh:
            return Color.red
        case .extreme:
            return Color.purple
        }
    }
}

// MARK: - UVLevel Extensions
extension UVLevel {
    var icon: String {
        switch self {
        case .low:
            return "sun.min"
        case .moderate:
            return "sun.min.fill"
        case .high:
            return "sun.max"
        case .veryHigh:
            return "sun.max.fill"
        case .extreme:
            return "sun.max.trianglebadge.exclamationmark"
        }
    }
    
    var shortRecommendation: String {
        switch self {
        case .low:
            return "Safe"
        case .moderate:
            return "Use SPF"
        case .high:
            return "Protect skin"
        case .veryHigh:
            return "Limit exposure"
        case .extreme:
            return "Avoid sun"
        }
    }
}