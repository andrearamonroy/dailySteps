//
//  ThemePickerView.swift
//  dailySteps
//
//  Created by Andrea on 1/14/26.
//

import SwiftUI


struct ThemePickerView1: View {
    @Binding var primary: PastelColor
    @Binding var secondary: PastelColor

    var body: some View {
        HStack(spacing: 16) {
            VStack {
                Text("Primary")
                colorSquare(for: $primary)
            }
            VStack {
                Text("Secondary")
                colorSquare(for: $secondary)
            }
        }
    }

    private func colorSquare(for binding: Binding<PastelColor>) -> some View {
        HStack {
            ForEach(PastelColor.allCases, id: \.self) { color in
                Rectangle()
                    .fill(color.color)
                    .frame(width: 30, height: 30)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(binding.wrappedValue == color ? Color.primary : Color.clear, lineWidth: 2)
                    )
                    .onTapGesture { binding.wrappedValue = color }
            }
        }
    }
}


struct ThemePickerView: View {

    @Binding var primary: PastelColor
    @Binding var secondary: PastelColor
    @Binding var background: PastelColor

    private let columns = Array(
        repeating: GridItem(.fixed(40), spacing: 12),
        count: 4
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            Text("Primary Color")
                .font(.headline)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(PastelColor.allCases) { pastel in
                    ColorSquare(
                        color: pastel.color,
                        isSelected: primary == pastel
                    )
                    .onTapGesture {
                        primary = pastel
                    }
                }
            }

            Text("Secondary Color")
                .font(.headline)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(PastelColor.allCases) { pastel in
                    ColorSquare(
                        color: pastel.color,
                        isSelected: secondary == pastel
                    )
                    .opacity(primary == pastel ? 0.4 : 1)
                    .onTapGesture {
                        guard pastel != primary else { return }
                        secondary = pastel
                    }
                }
            }
            
            Text("Background Color")
                .font(.headline)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(PastelColor.allCases) { pastel in
                    ColorSquare(
                        color: pastel.color,
                        isSelected: background == pastel
                    )
                    .opacity(primary == pastel ? 0.4 : 1)
                    .onTapGesture {
                        guard pastel != primary else { return }
                        guard pastel != secondary else { return }
                        background = pastel
                    }
                }
            }
        }
    }
}

struct ColorSquare: View {
    let color: Color
    let isSelected: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(color)
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



