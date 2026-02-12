//
//  ThemePickerView.swift
//  dailySteps
//
//  Created by Andrea on 1/14/26.
//

import SwiftUI

struct ThemePickerView: View {
    @ObservedObject var themeManager = ThemeManager.shared
    
    // Get current background color from saved string
    private var currentBackground: BackgroundColor {
        let colorString = UserDefaults(suiteName: "group.com.andrearamonroy.dailySteps")?
            .string(forKey: "backgroundColor") ?? BackgroundColor.aurora.rawValue
        return BackgroundColor(rawValue: colorString) ?? .aurora
    }

    private let columns = Array(
        repeating: GridItem(.fixed(40), spacing: 12),
        count: 4
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            Text("Background Color")
                .font(.headline)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(BackgroundColor.allCases) { pastel in
                    ColorSquare(
                        gradient: pastel.color,
                        isSelected: currentBackground == pastel
                    )
                    .onTapGesture {
                        themeManager.setBackground(pastel)
                    }
                }
            }
        }
    }
}

struct ColorSquare: View {
    let gradient: LinearGradient
    let isSelected: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(gradient)
            .frame(width: 32, height: 32)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        isSelected ? Color.primary : Color.clear,
                        lineWidth: 2
                    )
            )
            .shadow(radius: isSelected ? 2 : 0)
    }
}
