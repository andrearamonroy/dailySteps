//
//  Theme.swift
//  dailySteps
//
//  Created by Andrea on 1/14/26.
//

import Foundation

import SwiftUI
enum BackgroundColor: String, CaseIterable, Identifiable {
    case cloud
    case blush
    case gold
    case sage
    case sky
    case lavender
    case pearl
    case pistacho
    case aurora

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cloud: return "Cloud"
        case .blush: return "Blush"
        case .gold: return "Gold"
        case .sage: return "Sage"
        case .sky: return "Sky"
        case .lavender: return "Lavender"
        case .pearl: return "Pearl"
        case .pistacho: return "Pistacho"
        case .aurora: return "Aurora"
        }
    }

    var color: Color {
        switch self {
        case .cloud:
            // ▢ Soft gray-blue, visible
            return Color(red: 0.88, green: 0.92, blue: 0.95)
            
        case .blush:
            // ▢ Soft pink, clearly visible
            return Color(red: 1.0, green: 0.85, blue: 0.90)
            
        case .gold:
            // ▢ Warm beige, more saturated
            return Color(red: 1.0, green: 0.92, blue: 0.70)
            
        case .sage:
            // ▢ Muted green, visible pastel
            return Color(red: 0.82, green: 0.92, blue: 0.84)
            
        case .sky:
            // ▢ Soft blue, clearly visible
            return Color(red: 0.80, green: 0.90, blue: 1.0)
            
        case .lavender:
            // ▢ Soft purple, more visible
            return Color(red: 0.88, green: 0.82, blue: 0.98)
            
        case .pearl:
            // ▢ Cool gray, visible neutral
            return Color(red: 0.87, green: 0.90, blue: 0.92)
            
        case .pistacho:
            // ▢ Warm off-white, visible
            return Color(red: 0.85, green: 0.95, blue: 0.78)
            
        case .aurora:
                    // Midpoint between blue (0.3,0.5,0.9) and pink (0.9,0.5,0.6)
                    // of the Daily Steps gradient — soft periwinkle blush
            return Color(red: 0.80, green: 0.88, blue: 0.98)
            
           
        }
    }
}
