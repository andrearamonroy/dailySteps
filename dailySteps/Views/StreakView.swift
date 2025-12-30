//
//  StreakView.swift
//  dailySteps
//
//  Created by Andrea Monroy on 12/30/25.
//

import SwiftUI
import CoreData

struct StreakView: View {
    @State private var streakValue  = 0
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Day.date, ascending: true)],
        predicate: NSPredicate(format: "(date >= %@) AND (date <= %@)",
                               Date().startOfMonth as CVarArg,
                               Date().endOfMonth as CVarArg))
    
    private var days: FetchedResults<Day>
    
    
    var body: some View {
        VStack {
            Text("\(streakValue)")
                .font(.system(size: 200, weight: .semibold, design: .rounded))
                .foregroundStyle(streakValue > 0 ? .orange : .pink)
            Text("Current Streak")
                .font(.title2)
                .bold()
                .foregroundStyle(.secondary)
        }
    }
    
    func calculateStreakValue() -> Int {
        //days is empty return 0 for the streak
        guard !days.isEmpty else {return 0}
        
        let nonFutureDays = days.filter { $0.date!.dayInt <= Date().dayInt }
        
        var streakCount = 0
        
        for day in nonFutureDays.reversed() {
            if day.didSteps {
                streakCount += 1
            } else {
                //this checks if the date is not today then break
                // if we are still on the same day then don't break the streak
                if day.date!.dayInt != Date().dayInt {
                    break
                }
             
            }
        }
        
        
       return streakCount
    }
}

#Preview {
    StreakView()
}
