import SwiftUI

enum MacroType: String, CaseIterable {
    case calories, protein, carbs, fats
    var title: String {
        switch self {
        case .calories: return "Calories"
        case .protein: return "Protein"
        case .carbs: return "Carbs"
        case .fats: return "Fats"
        }
    }
    var icon: String {
        switch self {
        case .calories: return "flame.fill"
        case .protein: return "bolt.fill"
        case .carbs: return "leaf.fill"
        case .fats: return "drop.fill"
        }
    }
    var color: Color {
        switch self {
        case .calories: return .accentColor
        case .protein: return .red
        case .carbs: return .orange
        case .fats: return .blue
        }
    }
} 