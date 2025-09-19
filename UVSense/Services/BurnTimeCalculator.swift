import Foundation

class BurnTimeCalculator {
    
    // Calibration constant set so fair skin (Type I) at UVI 10 with no SPF yields ~10 minutes
    private static let calibrationConstant: Double = 1.0
    
    struct BurnTimeResult {
        let burnTimeMinutes: Int
        let reapplyTime: Date?
        let effectiveSPF: Double
        let warningLevel: WarningLevel
        
        enum WarningLevel {
            case safe       // > 60 minutes
            case caution    // 30-60 minutes
            case warning    // 15-30 minutes
            case danger     // < 15 minutes
            
            var color: String {
                switch self {
                case .safe: return "systemGreen"
                case .caution: return "systemYellow"
                case .warning: return "systemOrange"
                case .danger: return "systemRed"
                }
            }
            
            var message: String {
                switch self {
                case .safe: return "Safe exposure time"
                case .caution: return "Take precautions"
                case .warning: return "Limit exposure"
                case .danger: return "Seek shade immediately"
                }
            }
        }
        
        var displayText: String {
            if burnTimeMinutes >= 240 {
                return "Safe without sunscreen"
            } else if burnTimeMinutes >= 60 {
                let hours = burnTimeMinutes / 60
                let minutes = burnTimeMinutes % 60
                
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
                // For times less than 60 minutes, round up to nearest 5 minutes
                let roundedMinutes = ((burnTimeMinutes + 4) / 5) * 5
                return "\(roundedMinutes) minutes"
            }
        }
        
        var shortDisplayText: String {
            if burnTimeMinutes >= 240 {
                return "4h+"
            } else if burnTimeMinutes >= 60 {
                return "\(burnTimeMinutes / 60)h"
            } else {
                return "\(burnTimeMinutes)m"
            }
        }
    }
    
    // MARK: - Main Calculation Method
    static func calculateBurnTime(
        skinProfile: SkinProfile?,
        uvIndex: Double,
        sunscreen: SunscreenApplication? = nil,
        cloudCover: Double? = nil
    ) -> BurnTimeResult {
        
        // Default to Type II if no profile
        let fitzpatrickType = skinProfile?.refinedFitzpatrickType() ?? 2
        let medBaseline = getMEDBaseline(for: fitzpatrickType)
        
        // Calculate effective SPF
        let effectiveSPF = calculateEffectiveSPF(sunscreen: sunscreen)
        
        // Apply cloud cover attenuation if available
        let adjustedUVIndex = applyCloudCoverAttenuation(uvIndex: uvIndex, cloudCover: cloudCover)
        
        // Core burn time formula: BT = k × MED(Fitz) × SPF_eff ÷ UVI_hour
        let burnTimeRaw = calibrationConstant * Double(medBaseline) * effectiveSPF / max(0.1, adjustedUVIndex)
        
        // Clamp between 5 and 240 minutes
        let burnTimeMinutes = Int(max(5, min(240, burnTimeRaw)))
        
        // Calculate reapply time if sunscreen is applied
        let reapplyTime = sunscreen?.reapplyTime
        
        // Determine warning level
        let warningLevel: BurnTimeResult.WarningLevel
        switch burnTimeMinutes {
        case 60...:
            warningLevel = .safe
        case 30..<60:
            warningLevel = .caution
        case 15..<30:
            warningLevel = .warning
        default:
            warningLevel = .danger
        }
        
        return BurnTimeResult(
            burnTimeMinutes: burnTimeMinutes,
            reapplyTime: reapplyTime,
            effectiveSPF: effectiveSPF,
            warningLevel: warningLevel
        )
    }
    
    // MARK: - Helper Methods
    
    private static func getMEDBaseline(for fitzpatrickType: Int) -> Int {
        // Minimal Erythema Dose (MED) in J/m² based on Fitzpatrick type
        switch fitzpatrickType {
        case 1: return 200  // Type I - Always burns, never tans
        case 2: return 250  // Type II - Burns easily, tans minimally
        case 3: return 300  // Type III - Burns moderately, tans gradually
        case 4: return 450  // Type IV - Burns minimally, tans well
        case 5: return 600  // Type V - Rarely burns, tans profusely
        case 6: return 1000 // Type VI - Never burns
        default: return 250 // Default to Type II
        }
    }
    
    private static func calculateEffectiveSPF(sunscreen: SunscreenApplication?) -> Double {
        guard let sunscreen = sunscreen else { return 1.0 }
        
        // SPF_eff = (SPF_label)^(dose/2) × (1 − decay)
        let dose = sunscreen.doseInMgPerCm2
        let baseSPF = pow(Double(sunscreen.spfValue), dose / 2.0)
        
        // Calculate decay based on time and activity
        let decay = calculateSPFDecay(sunscreen: sunscreen)
        
        // Apply decay and clamp to valid range
        let effectiveSPF = baseSPF * (1.0 - decay)
        
        // Clamp between 1 and the labeled SPF value
        return max(1.0, min(Double(sunscreen.spfValue), effectiveSPF))
    }
    
    private static func calculateSPFDecay(sunscreen: SunscreenApplication) -> Double {
        let hoursSinceApplication = Date().timeIntervalSince(sunscreen.appliedAt) / 3600.0
        let twoHourPeriods = hoursSinceApplication / 2.0
        
        switch sunscreen.activityLevel {
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
            
        case .active:
            // 35% each 2h
            return min(1.0, 0.35 * twoHourPeriods)
            
        case .water:
            // 35% each 2h, but force reapply at 2h after water
            if let lastWater = sunscreen.lastWaterExposure {
                let hoursSinceWater = Date().timeIntervalSince(lastWater) / 3600.0
                if hoursSinceWater >= 2.0 {
                    return 1.0 // Full decay - needs reapplication
                }
            }
            return min(1.0, 0.35 * twoHourPeriods)
        }
    }
    
    private static func applyCloudCoverAttenuation(uvIndex: Double, cloudCover: Double?) -> Double {
        guard let cloudCover = cloudCover else { return uvIndex }
        
        // Cloud cover reduces UV by approximately:
        // - Light clouds (0-30%): 10% reduction
        // - Moderate clouds (30-70%): 30% reduction
        // - Heavy clouds (70-100%): 50% reduction
        // Note: UV can still be high even with clouds!
        
        let attenuation: Double
        switch cloudCover {
        case 0..<0.3:
            attenuation = 0.9 // 10% reduction
        case 0.3..<0.7:
            attenuation = 0.7 // 30% reduction
        case 0.7...1.0:
            attenuation = 0.5 // 50% reduction
        default:
            attenuation = 1.0
        }
        
        return uvIndex * attenuation
    }
    
    // MARK: - Batch Calculation for Hourly Forecast
    static func calculateHourlyBurnTimes(
        skinProfile: SkinProfile?,
        hourlyForecast: [HourlyUVData],
        sunscreen: SunscreenApplication? = nil
    ) -> [Date: BurnTimeResult] {
        
        var results: [Date: BurnTimeResult] = [:]
        
        for hourData in hourlyForecast {
            // Create a temporary sunscreen with adjusted time for future calculation
            var adjustedSunscreen = sunscreen
            
            if let sunscreen = sunscreen {
                // Calculate how far in the future this hour is
                let hoursInFuture = hourData.hour.timeIntervalSince(Date()) / 3600.0
                
                // Adjust the applied time to account for decay by that future time
                // This simulates what the SPF effectiveness will be at that hour
                if hoursInFuture > 0 {
                    // Create a copy with adjusted application time
                    adjustedSunscreen = SunscreenApplication(
                        spfValue: sunscreen.spfValue,
                        quantity: sunscreen.quantity,
                        appliedAt: sunscreen.appliedAt.addingTimeInterval(-hoursInFuture * 3600),
                        activityLevel: sunscreen.activityLevel,
                        waterExposure: sunscreen.waterExposure
                    )
                }
            }
            
            let result = calculateBurnTime(
                skinProfile: skinProfile,
                uvIndex: hourData.uvIndex,
                sunscreen: adjustedSunscreen,
                cloudCover: hourData.cloudCover
            )
            
            results[hourData.hour] = result
        }
        
        return results
    }
}