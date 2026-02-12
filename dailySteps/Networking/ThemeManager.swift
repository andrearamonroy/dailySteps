//
//  ThemeManager.swift
//  dailySteps
//
//  Created by Andrea on 2/12/26.
//

import Foundation
import SwiftUI

import SwiftUI

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    private let defaults = UserDefaults(suiteName: "group.com.andrearamonroy.dailySteps")
    
    @Published var backgroundColor: LinearGradient
    
    private init() {
        let colorString = defaults?.string(forKey: "backgroundColor") ?? BackgroundColor.aurora.rawValue
        self.backgroundColor = BackgroundColor(rawValue: colorString)?.color ?? BackgroundColor.aurora.color
    }
    
    func setBackground(_ color: BackgroundColor) {
        self.backgroundColor = color.color
        defaults?.set(color.rawValue, forKey: "backgroundColor")
    }
}
