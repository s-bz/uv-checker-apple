import Foundation
import SwiftData

@Model
final class SunscreenApplication {
    var spfValue: Int
    var quantity: ApplicationQuantity
    var appliedAt: Date
    var activityLevel: ActivityLevel
    var waterExposure: Bool
    var lastWaterExposure: Date?
    
    @Transient
    var doseInMgPerCm2: Double {
        switch quantity {
        case .low: return 0.5
        case .medium: return 1.0
        case .lots: return 2.0
        }
    }
    
    @Transient
    var effectiveSPF: Double {
        // SPF_eff = (SPF_label)^(dose/2) × (1 − decay)
        let baseSPF = pow(Double(spfValue), doseInMgPerCm2 / 2.0)
        let decay = calculateDecay()
        let effective = baseSPF * (1.0 - decay)
        return max(1.0, min(Double(spfValue), effective))
    }
    
    @Transient
    var needsReapplication: Bool {
        let timeSinceApplication = Date().timeIntervalSince(appliedAt) / 3600.0 // hours
        
        // Water exposure forces reapplication after 2 hours
        if waterExposure, let lastWater = lastWaterExposure {
            let timeSinceWater = Date().timeIntervalSince(lastWater) / 3600.0
            if timeSinceWater >= 2.0 {
                return true
            }
        }
        
        // Standard reapplication every 2 hours
        return timeSinceApplication >= 2.0
    }
    
    @Transient
    var reapplyTime: Date {
        if waterExposure, let lastWater = lastWaterExposure {
            // Reapply 2 hours after water exposure
            return lastWater.addingTimeInterval(2 * 3600)
        }
        // Standard reapply after 2 hours
        return appliedAt.addingTimeInterval(2 * 3600)
    }
    
    @Transient
    var statusDescription: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        if needsReapplication {
            return "Needs reapplication"
        } else {
            return "Reapply by \(formatter.string(from: reapplyTime))"
        }
    }
    
    init(
        spfValue: Int,
        quantity: ApplicationQuantity,
        appliedAt: Date = Date(),
        activityLevel: ActivityLevel = .normal,
        waterExposure: Bool = false
    ) {
        self.spfValue = spfValue
        self.quantity = quantity
        self.appliedAt = appliedAt
        self.activityLevel = activityLevel
        self.waterExposure = waterExposure
        self.lastWaterExposure = waterExposure ? Date() : nil
    }
    
    private func calculateDecay() -> Double {
        let hoursSinceApplication = Date().timeIntervalSince(appliedAt) / 3600.0
        let twoHourPeriods = hoursSinceApplication / 2.0
        
        switch activityLevel {
        case .indoors:
            // 0% for first 2h, then 10% each additional 2h
            if hoursSinceApplication <= 2.0 {
                return 0.0
            } else {
                return min(1.0, 0.1 * (twoHourPeriods - 1))
            }
            
        case .normal:
            // 20% each 2h
            return min(1.0, 0.2 * twoHourPeriods)
            
        case .active, .water:
            // 35% each 2h
            return min(1.0, 0.35 * twoHourPeriods)
        }
    }
    
    func updateWaterExposure() {
        waterExposure = true
        lastWaterExposure = Date()
        activityLevel = .water
    }
}

// MARK: - Supporting Enums
enum ApplicationQuantity: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case lots = "lots"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .lots: return "Lots"
        }
    }
    
    var description: String {
        switch self {
        case .low: return "Light application (~0.5 mg/cm²)"
        case .medium: return "Standard application (~1.0 mg/cm²)"
        case .lots: return "Full protection (~2.0 mg/cm²)"
        }
    }
    
    var recommendation: String {
        switch self {
        case .low, .medium:
            return "Consider a double application for full protection"
        case .lots:
            return "Optimal protection achieved"
        }
    }
}

enum ActivityLevel: String, CaseIterable, Codable {
    case indoors = "indoors"
    case normal = "normal"
    case active = "active"
    case water = "water"
    
    var displayName: String {
        switch self {
        case .indoors: return "Indoors"
        case .normal: return "Normal"
        case .active: return "Active"
        case .water: return "Swimming/Water"
        }
    }
    
    var decayDescription: String {
        switch self {
        case .indoors: return "Minimal degradation"
        case .normal: return "Standard degradation"
        case .active: return "Increased degradation from sweat"
        case .water: return "Rapid degradation from water"
        }
    }
}

// MARK: - SPF Options
enum SPFOption: Int, CaseIterable {
    case spf15 = 15
    case spf30 = 30
    case spf50Plus = 50
    
    var displayName: String {
        switch self {
        case .spf15: return "SPF 15"
        case .spf30: return "SPF 30"
        case .spf50Plus: return "SPF 50+"
        }
    }
    
    var value: Int {
        return self.rawValue
    }
}