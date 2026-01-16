//
//  Theme.swift
//  dailySteps
//
//  Created by Andrea on 1/14/26.
//

import Foundation

import SwiftUI

enum PastelColor: String, CaseIterable, Identifiable {
    case pink
    case peach
    case yellow
    case mint
    case teal
    case blue
    case lavender
    case gray

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .pink:      return Color(red: 1.0, green: 0.8, blue: 0.85)
        case .peach:     return Color(red: 1.0, green: 0.85, blue: 0.7)
        case .yellow:    return Color(red: 1.0, green: 0.95, blue: 0.7)
        case .mint:      return Color(red: 0.8, green: 1.0, blue: 0.85)
        case .teal:      return Color(red: 0.75, green: 0.95, blue: 0.9)
        case .blue:      return Color(red: 0.8, green: 0.9, blue: 1.0)
        case .lavender:  return Color(red: 0.9, green: 0.85, blue: 1.0)
        case .gray:      return Color(red: 0.9, green: 0.9, blue: 0.9)
        }
    }
}
