//
//  UVWidgetEntry.swift
//  Widget
//
//  UV Index Widget Entry Model
//

import WidgetKit
import SwiftUI

struct UVWidgetEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let uvIndex: Double
    let uvLevel: UVWidgetLevel
    let location: String
    let temperature: Double?
    let burnTime: Int? // in minutes
    let sunscreenActive: Bool
    let sunscreenSPF: Int?
    let nextHighUVTime: Date?
    let isDataStale: Bool
}

enum UVWidgetLevel: String {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    case veryHigh = "Very High"
    case extreme = "Extreme"
    
    init(fromIndex index: Double) {
        switch index {
        case 0..<3:
            self = .low
        case 3..<6:
            self = .moderate
        case 6..<8:
            self = .high
        case 8..<11:
            self = .veryHigh
        default:
            self = .extreme
        }
    }
    
    var color: Color {
        switch self {
        case .low:
            return .green
        case .moderate:
            return .yellow
        case .high:
            return .orange
        case .veryHigh:
            return .red
        case .extreme:
            return .purple
        }
    }
    
    var recommendation: String {
        switch self {
        case .low:
            return "No protection needed"
        case .moderate:
            return "Use SPF 30+"
        case .high:
            return "Seek shade midday"
        case .veryHigh:
            return "Extra protection"
        case .extreme:
            return "Avoid sun exposure"
        }
    }
    
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
}