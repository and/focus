import Foundation
import SwiftUI

enum AppCategory: String, Codable, CaseIterable {
    case productive
    case communication
    case reference
    case neutral
    case distracting
    
    var color: Color {
        switch self {
        case .productive: return .green
        case .communication: return .blue
        case .reference: return .purple
        case .neutral: return .gray
        case .distracting: return .red
        }
    }
    
    var displayName: String {
        switch self {
        case .productive: return "Productive"
        case .communication: return "Communication"
        case .reference: return "Reference"
        case .neutral: return "Neutral"
        case .distracting: return "Distracting"
        }
    }
}

enum FocusLevel: String, Codable, CaseIterable {
    case deepFocus = "Deep Focus"
    case focused = "Focused"
    case moderate = "Moderate"
    case scattered = "Scattered"
    case distracted = "Distracted"
    
    var color: Color {
        switch self {
        case .deepFocus: return Color(red: 34/255, green: 197/255, blue: 94/255) // #22C55E
        case .focused: return Color(red: 59/255, green: 130/255, blue: 246/255) // #3B82F6
        case .moderate: return Color(red: 234/255, green: 179/255, blue: 8/255) // #EAB308
        case .scattered: return Color(red: 249/255, green: 115/255, blue: 22/255) // #F97316
        case .distracted: return Color(red: 239/255, green: 68/255, blue: 68/255) // #EF4444
        }
    }
    
    static func from(score: Int) -> FocusLevel {
        switch score {
        case 80...100: return .deepFocus
        case 60...79: return .focused
        case 40...59: return .moderate
        case 20...39: return .scattered
        default: return .distracted
        }
    }
}
