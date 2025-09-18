import Foundation
import SwiftData

@Model
final class SkinProfile {
    var fitzpatrickType: Int
    var eyeColor: EyeColor?
    var naturalHairColor: HairColor?
    var hasFreckles: Bool
    var tanningResponse: TanningResponse?
    var createdAt: Date
    var updatedAt: Date
    
    @Transient
    var medBaseline: Int {
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
    
    @Transient
    var typeDescription: String {
        switch fitzpatrickType {
        case 1: return "Very fair skin, always burns, never tans"
        case 2: return "Fair skin, burns easily, tans minimally"
        case 3: return "Medium skin, burns moderately, tans gradually"
        case 4: return "Olive skin, burns minimally, tans well"
        case 5: return "Brown skin, rarely burns, tans profusely"
        case 6: return "Dark brown/black skin, never burns"
        default: return "Unknown skin type"
        }
    }
    
    @Transient
    var typeName: String {
        switch fitzpatrickType {
        case 1: return "Type I"
        case 2: return "Type II"
        case 3: return "Type III"
        case 4: return "Type IV"
        case 5: return "Type V"
        case 6: return "Type VI"
        default: return "Unknown"
        }
    }
    
    init(
        fitzpatrickType: Int,
        eyeColor: EyeColor? = nil,
        naturalHairColor: HairColor? = nil,
        hasFreckles: Bool = false,
        tanningResponse: TanningResponse? = nil
    ) {
        self.fitzpatrickType = fitzpatrickType
        self.eyeColor = eyeColor
        self.naturalHairColor = naturalHairColor
        self.hasFreckles = hasFreckles
        self.tanningResponse = tanningResponse
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // Helper function to refine Fitzpatrick type based on additional attributes
    func refinedFitzpatrickType() -> Int {
        var score = 0
        
        // Eye color contribution
        if let eyeColor = eyeColor {
            switch eyeColor {
            case .lightBlue, .lightGray, .lightGreen:
                score += 0
            case .blue, .gray, .green:
                score += 1
            case .hazel:
                score += 2
            case .lightBrown:
                score += 3
            case .darkBrown, .black:
                score += 4
            }
        }
        
        // Hair color contribution
        if let hairColor = naturalHairColor {
            switch hairColor {
            case .red, .lightBlonde:
                score += 0
            case .blonde:
                score += 1
            case .darkBlonde, .lightBrown:
                score += 2
            case .brown:
                score += 3
            case .darkBrown, .black:
                score += 4
            case .gray, .white:
                score += 2 // Neutral contribution
            }
        }
        
        // Freckles contribution
        if hasFreckles {
            score -= 1
        }
        
        // Tanning response contribution
        if let tanningResponse = tanningResponse {
            switch tanningResponse {
            case .alwaysBurns:
                score += 0
            case .usuallyBurns:
                score += 1
            case .sometimesBurns:
                score += 2
            case .rarelyBurns:
                score += 3
            case .neverBurns:
                score += 4
            }
        }
        
        // Map score to Fitzpatrick type
        let divisor = (eyeColor != nil ? 1 : 0) + 
                      (naturalHairColor != nil ? 1 : 0) + 
                      (tanningResponse != nil ? 1 : 0)
        let averageScore = divisor > 0 ? Double(score) / Double(divisor) : 2.0
        
        // Adjust base type based on score
        let adjustment = Int(round(averageScore - 2))
        return (fitzpatrickType + adjustment).clamped(to: 1...6)
    }
}

// MARK: - Supporting Enums
enum EyeColor: String, CaseIterable, Codable {
    case lightBlue = "light_blue"
    case lightGray = "light_gray"
    case lightGreen = "light_green"
    case blue = "blue"
    case gray = "gray"
    case green = "green"
    case hazel = "hazel"
    case lightBrown = "light_brown"
    case darkBrown = "dark_brown"
    case black = "black"
    
    var displayName: String {
        switch self {
        case .lightBlue: return "Light Blue"
        case .lightGray: return "Light Gray"
        case .lightGreen: return "Light Green"
        case .blue: return "Blue"
        case .gray: return "Gray"
        case .green: return "Green"
        case .hazel: return "Hazel"
        case .lightBrown: return "Light Brown"
        case .darkBrown: return "Dark Brown"
        case .black: return "Black"
        }
    }
}

enum HairColor: String, CaseIterable, Codable {
    case red = "red"
    case lightBlonde = "light_blonde"
    case blonde = "blonde"
    case darkBlonde = "dark_blonde"
    case lightBrown = "light_brown"
    case brown = "brown"
    case darkBrown = "dark_brown"
    case black = "black"
    case gray = "gray"
    case white = "white"
    
    var displayName: String {
        switch self {
        case .red: return "Red"
        case .lightBlonde: return "Light Blonde"
        case .blonde: return "Blonde"
        case .darkBlonde: return "Dark Blonde"
        case .lightBrown: return "Light Brown"
        case .brown: return "Brown"
        case .darkBrown: return "Dark Brown"
        case .black: return "Black"
        case .gray: return "Gray"
        case .white: return "White"
        }
    }
}

enum TanningResponse: String, CaseIterable, Codable {
    case alwaysBurns = "always_burns"
    case usuallyBurns = "usually_burns"
    case sometimesBurns = "sometimes_burns"
    case rarelyBurns = "rarely_burns"
    case neverBurns = "never_burns"
    
    var displayName: String {
        switch self {
        case .alwaysBurns: return "Always burns, never tans"
        case .usuallyBurns: return "Usually burns, tans minimally"
        case .sometimesBurns: return "Sometimes burns, tans gradually"
        case .rarelyBurns: return "Rarely burns, tans easily"
        case .neverBurns: return "Never burns, always tans"
        }
    }
}

// MARK: - Helper Extensions
extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}