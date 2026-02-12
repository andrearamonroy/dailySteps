//
//  StreakView.swift
//  dailySteps
//
//  Created by Andrea Monroy on 12/30/25.
//

import SwiftUI
import CoreData

struct StreakView: View {
  
    @EnvironmentObject var mainViewModel: MainViewModel
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Day.date, ascending: true)],
        predicate: NSPredicate(format: "(date >= %@) AND (date <= %@)",
                               Date().startOfMonth as CVarArg,
                               Date().endOfMonth as CVarArg))
    
    private var days: FetchedResults<Day>
  
    @ObservedObject var themeManager = ThemeManager.shared
    
    var body: some View {
        
        let streakValue = StreakCalculator.calculate(
            days: Array(days),
            maxGraceDays: mainViewModel.graceDays
        )

        VStack {
            Text("\(streakValue)")
                .font(.system(size: 200, weight: .semibold, design: .rounded))
                .foregroundStyle(streakValue > 0 ? themeManager.backgroundColor : themeManager.backgroundColor)
            Text("day streak")
                .font(.title2)
                .bold()
                .foregroundStyle(.secondary)
        }
    }
    
  

}

#Preview {
    StreakView()
}

// Add this new view at the bottom of StepView.swift

struct StreakCompactView: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var themeManager = ThemeManager.shared
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Day.date, ascending: true)],
        predicate: NSPredicate(format: "(date >= %@) AND (date <= %@)",
                               Date().startOfMonth as CVarArg,
                               Date().endOfMonth as CVarArg))
    private var days: FetchedResults<Day>
    
    var body: some View {
        let streakValue = StreakCalculator.calculate(
            days: Array(days),
            maxGraceDays: mainViewModel.graceDays
        )
        
        HStack(spacing: 4) {
            Text("\(streakValue)")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(
                    streakValue > 0
                    ? LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
                    : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing)
                )
            
            Image(systemName: "flame.fill")
                .font(.title2)
                .foregroundColor(streakValue > 0 ? .orange : .gray)
        }
    }
}
