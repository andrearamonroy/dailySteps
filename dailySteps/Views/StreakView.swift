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
  
    
    var body: some View {
        
        let streakValue = StreakCalculator.calculate(
            days: Array(days),
            maxGraceDays: mainViewModel.graceDays
        )

        
        VStack {
            Text("\(streakValue)")
                .font(.system(size: 200, weight: .semibold, design: .rounded))
                .foregroundStyle(streakValue > 0 ? mainViewModel.primaryColor.color : mainViewModel.secondaryColor.color)
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
