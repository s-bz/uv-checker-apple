import SwiftUI

struct UVWheelView: View {
    let hourlyData: [HourlyUVData]
    @State private var selectedHour: Date?
    @State private var dragAngle: Double = 0
    @State private var isDragging = false
    
    let sunscreenWindow: (start: Date?, end: Date?)
    let peakWindow: (start: Date?, end: Date?, maxUV: Double)
    let onHourSelected: ((Date, HourlyUVData) -> Void)?
    
    // Wheel dimensions
    private let outerRadius: CGFloat = 70
    private let innerRadius: CGFloat = 50
    private let strokeWidth: CGFloat = 20
    private let segmentGap: Angle = .degrees(1.5)
    
    init(
        hourlyData: [HourlyUVData],
        sunscreenWindow: (start: Date?, end: Date?) = (nil, nil),
        peakWindow: (start: Date?, end: Date?, maxUV: Double) = (nil, nil, 0),
        onHourSelected: ((Date, HourlyUVData) -> Void)? = nil
    ) {
        self.hourlyData = hourlyData
        self.sunscreenWindow = sunscreenWindow
        self.peakWindow = peakWindow
        self.onHourSelected = onHourSelected
        
        // Initialize with current hour selected
        let currentHour = Date()
        if let closestHour = hourlyData.min(by: { abs($0.hour.timeIntervalSince(currentHour)) < abs($1.hour.timeIntervalSince(currentHour)) }) {
            self._selectedHour = State(initialValue: closestHour.hour)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background circle
                Circle()
                    .fill(Color(UIColor.systemBackground))
                    .frame(width: outerRadius * 2, height: outerRadius * 2)
                
                // Hour segments
                ForEach(Array(hourlyData.prefix(24).enumerated()), id: \.element.hour) { index, hourData in
                    WheelSegment(
                        startAngle: angleForHour(index) - segmentGap / 2,
                        endAngle: angleForHour(index + 1) - segmentGap / 2,
                        innerRadius: innerRadius,
                        outerRadius: outerRadius,
                        color: colorForUVLevel(hourData.uvLevel),
                        opacity: isPastHour(hourData.hour) ? 0.3 : 1.0,
                        isSelected: isHourSelected(hourData.hour)
                    )
                    .onTapGesture {
                        selectHour(hourData.hour, hourData)
                    }
                }
                
                // Sunscreen window arc overlay
                if let start = sunscreenWindow.start,
                   let end = sunscreenWindow.end {
                    SunscreenWindowArc(
                        startTime: start,
                        endTime: end,
                        innerRadius: innerRadius - 5,
                        outerRadius: outerRadius + 5,
                        hourlyData: hourlyData
                    )
                }
                
                // Peak UV window highlight
                if let start = peakWindow.start,
                   let end = peakWindow.end {
                    PeakWindowArc(
                        startTime: start,
                        endTime: end,
                        innerRadius: innerRadius,
                        outerRadius: outerRadius,
                        hourlyData: hourlyData
                    )
                }
                
                // Current time indicator
                CurrentTimeIndicator(
                    radius: outerRadius,
                    hourlyData: hourlyData
                )
                
                // Center content
                CenterDisplay(
                    selectedHour: selectedHour,
                    hourlyData: hourlyData
                )
                
                // Hour labels around the wheel
                ForEach(0..<24, id: \.self) { hour in
                    HourLabel(
                        hour: hour,
                        radius: outerRadius + 15,
                        angle: angleForHour(hour)
                    )
                }
                
                // Drag handle
                if let selectedHour = selectedHour,
                   let index = hourlyData.firstIndex(where: { $0.hour == selectedHour }) {
                    DragHandle(
                        angle: angleForHour(index),
                        radius: outerRadius,
                        isDragging: isDragging
                    )
                }
            }
            .frame(width: (outerRadius + 15) * 2, height: (outerRadius + 15) * 2)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        handleDrag(value, in: geometry)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    // MARK: - Helper Methods
    
    private func angleForHour(_ hour: Int) -> Angle {
        // Map 0-23 hours to 0-360 degrees, starting from top (12 o'clock)
        let degreesPerHour = 360.0 / 24.0
        return .degrees(Double(hour) * degreesPerHour - 90)
    }
    
    private func hourFromAngle(_ angle: Angle) -> Int {
        let degrees = angle.degrees + 90
        let normalizedDegrees = degrees < 0 ? degrees + 360 : degrees
        let hour = Int(normalizedDegrees / 15) % 24
        return hour
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
    
    private func isPastHour(_ hour: Date) -> Bool {
        return hour < Date()
    }
    
    private func isHourSelected(_ hour: Date) -> Bool {
        guard let selectedHour = selectedHour else { return false }
        return Calendar.current.isDate(hour, equalTo: selectedHour, toGranularity: .hour)
    }
    
    private func selectHour(_ hour: Date, _ data: HourlyUVData) {
        selectedHour = hour
        onHourSelected?(hour, data)
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    private func handleDrag(_ value: DragGesture.Value, in geometry: GeometryProxy) {
        isDragging = true
        
        let center = CGPoint(
            x: geometry.size.width / 2,
            y: geometry.size.height / 2
        )
        
        let angle = atan2(
            value.location.y - center.y,
            value.location.x - center.x
        )
        
        let degrees = angle * 180 / .pi
        let hour = hourFromAngle(.degrees(degrees))
        
        if hour < hourlyData.count {
            let hourData = hourlyData[hour]
            selectHour(hourData.hour, hourData)
        }
    }
}

// MARK: - Subviews

struct WheelSegment: View {
    let startAngle: Angle
    let endAngle: Angle
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    let color: Color
    let opacity: Double
    let isSelected: Bool
    
    var body: some View {
        Path { path in
            path.addArc(
                center: .zero,
                radius: outerRadius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
            path.addArc(
                center: .zero,
                radius: innerRadius,
                startAngle: endAngle,
                endAngle: startAngle,
                clockwise: true
            )
            path.closeSubpath()
        }
        .fill(color.opacity(opacity))
        .overlay(
            isSelected ?
            Path { path in
                path.addArc(
                    center: .zero,
                    radius: outerRadius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false
                )
                path.addArc(
                    center: .zero,
                    radius: innerRadius,
                    startAngle: endAngle,
                    endAngle: startAngle,
                    clockwise: true
                )
                path.closeSubpath()
            }
            .stroke(Color.primary, lineWidth: 2)
            : nil
        )
    }
}

struct SunscreenWindowArc: View {
    let startTime: Date
    let endTime: Date
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    let hourlyData: [HourlyUVData]
    
    var body: some View {
        if let startIndex = hourlyData.firstIndex(where: { $0.hour >= startTime }),
           let endIndex = hourlyData.firstIndex(where: { $0.hour >= endTime }) {
            
            let startAngle = angleForHour(startIndex)
            let endAngle = angleForHour(endIndex)
            
            Path { path in
                path.addArc(
                    center: .zero,
                    radius: (innerRadius + outerRadius) / 2,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false
                )
            }
            .stroke(
                Color.orange.opacity(0.6),
                style: StrokeStyle(
                    lineWidth: 8,
                    lineCap: .round
                )
            )
            .shadow(color: Color.orange.opacity(0.3), radius: 2)
        }
    }
    
    private func angleForHour(_ hour: Int) -> Angle {
        let degreesPerHour = 360.0 / 24.0
        return .degrees(Double(hour) * degreesPerHour - 90)
    }
}

struct PeakWindowArc: View {
    let startTime: Date
    let endTime: Date
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    let hourlyData: [HourlyUVData]
    
    var body: some View {
        if let startIndex = hourlyData.firstIndex(where: { $0.hour >= startTime }),
           let endIndex = hourlyData.firstIndex(where: { $0.hour >= endTime }) {
            
            let startAngle = angleForHour(startIndex)
            let endAngle = angleForHour(endIndex)
            
            Path { path in
                path.addArc(
                    center: .zero,
                    radius: outerRadius + 2,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false
                )
            }
            .stroke(
                Color.primary,
                style: StrokeStyle(
                    lineWidth: 6,
                    lineCap: .round
                )
            )
        }
    }
    
    private func angleForHour(_ hour: Int) -> Angle {
        let degreesPerHour = 360.0 / 24.0
        return .degrees(Double(hour) * degreesPerHour - 90)
    }
}

struct CurrentTimeIndicator: View {
    let radius: CGFloat
    let hourlyData: [HourlyUVData]
    @State private var isPulsing = false
    
    var body: some View {
        let currentHour = Calendar.current.component(.hour, from: Date())
        let currentMinute = Calendar.current.component(.minute, from: Date())
        let fractionalHour = Double(currentHour) + Double(currentMinute) / 60.0
        let angle = angleForTime(fractionalHour)
        
        Circle()
            .fill(Color.primary)
            .frame(width: 10, height: 10)
            .scaleEffect(isPulsing ? 1.2 : 1.0)
            .position(
                x: radius * cos(angle.radians),
                y: radius * sin(angle.radians)
            )
            .animation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
    
    private func angleForTime(_ hour: Double) -> Angle {
        let degreesPerHour = 360.0 / 24.0
        return .degrees(hour * degreesPerHour - 90)
    }
}

struct CenterDisplay: View {
    let selectedHour: Date?
    let hourlyData: [HourlyUVData]
    
    var body: some View {
        VStack(spacing: 4) {
            if let selectedHour = selectedHour,
               let hourData = hourlyData.first(where: { $0.hour == selectedHour }) {
                
                Text(formattedTime(selectedHour))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text("\(Int(hourData.uvIndex))")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(hourData.uvLevel.description)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct HourLabel: View {
    let hour: Int
    let radius: CGFloat
    let angle: Angle
    
    var body: some View {
        Text(labelText)
            .font(.system(size: 10))
            .foregroundColor(.secondary)
            .position(
                x: radius * cos(angle.radians),
                y: radius * sin(angle.radians)
            )
    }
    
    private var labelText: String {
        // Only show labels for key hours
        switch hour {
        case 0: return "12"
        case 6: return "6"
        case 12: return "12"
        case 18: return "18"
        default: return ""
        }
    }
}

struct DragHandle: View {
    let angle: Angle
    let radius: CGFloat
    let isDragging: Bool
    
    var body: some View {
        Circle()
            .fill(Color.primary)
            .frame(width: 18, height: 18)
            .overlay(
                Circle()
                    .fill(Color(UIColor.systemBackground))
                    .frame(width: 12, height: 12)
            )
            .scaleEffect(isDragging ? 1.2 : 1.0)
            .position(
                x: radius * cos(angle.radians),
                y: radius * sin(angle.radians)
            )
            .animation(.spring(response: 0.3), value: isDragging)
    }
}