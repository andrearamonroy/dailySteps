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

    var color: LinearGradient {
        switch self {
        case .cloud:
            // Soft gray-blue gradient
            return LinearGradient(
                colors: [Color(red: 0.88, green: 0.92, blue: 0.95), Color(red: 0.80, green: 0.85, blue: 0.90)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
        case .blush:
            // Soft pink gradient
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.85, blue: 0.90), Color(red: 1.0, green: 0.75, blue: 0.82)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
        case .gold:
            // Warm beige gradient
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.92, blue: 0.70), Color(red: 0.95, green: 0.82, blue: 0.55)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
        case .sage:
            // Muted green gradient
            return LinearGradient(
                colors: [Color(red: 0.82, green: 0.92, blue: 0.84), Color(red: 0.70, green: 0.85, blue: 0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
        case .sky:
            // Soft blue gradient
            return LinearGradient(
                colors: [Color(red: 0.80, green: 0.90, blue: 1.0), Color(red: 0.65, green: 0.80, blue: 0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
        case .lavender:
            // Soft purple gradient
            return LinearGradient(
                colors: [Color(red: 0.88, green: 0.82, blue: 0.98), Color(red: 0.78, green: 0.70, blue: 0.92)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
        case .pearl:
            // Cool gray gradient
            return LinearGradient(
                colors: [Color(red: 0.87, green: 0.90, blue: 0.92), Color(red: 0.78, green: 0.82, blue: 0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
        case .pistacho:
            // Warm off-white gradient
            return LinearGradient(
                colors: [Color(red: 0.85, green: 0.95, blue: 0.78), Color(red: 0.75, green: 0.88, blue: 0.68)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
        case .aurora:
            return LinearGradient(
                colors: [
                    Color(red: 0.75, green: 0.85, blue: 0.98),  // Medium light blue
                    Color(red: 0.98, green: 0.82, blue: 0.88)   // Medium light pink
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
