//
//  ContentView.swift
//  dailySteps
//
//  Created by Andrea on 4/20/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Day.date, ascending: true)],
        predicate: NSPredicate(format: "(date >= %@) AND (date <= %@)",
                               Date().startOfCalendarWithPrefixDays as CVarArg,
                               Date().endOfMonth as CVarArg))
    private var days: FetchedResults<Day>
    
    @StateObject private var healthManager = HealthManager()
    
    //create an array that holds the days of the week
    let daysOfWeek = ["S","M","T","W","T","F","S"]
    
    var body: some View {
        NavigationView {
            
            VStack {
                Text("Steps today")
                    .font(.largeTitle)
                    .bold()
                Text("\(Int(healthManager.steps)) steps")
                                .font(.title)

                if healthManager.steps == 1000 {
                    Text("Goal Reached")
                        .foregroundStyle(.green)
                } else {
                    Text( "Keep going")
                        .foregroundStyle(.orange)
                }

            }
            
            
            
            //header
            VStack {
                
                HStack {
                    ForEach(daysOfWeek, id: \.self) { dayOfWeek in
                        Text(dayOfWeek)
                            .fontWeight(.black)
                            .foregroundStyle(.titlePink)
                            .frame(maxWidth: .infinity)
                    }
                    
                }
                
                //days grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                    ForEach(days) {day  in
                        
                        if day.date!.monthInt != Date().monthInt {
                            Text("")
                        } else {
                            Text(day.date!.formatted(.dateTime.day()))
                                .fontWeight(.bold)
                                .foregroundStyle(day.didSteps ? .circlePink : .secondary)
                                .frame(maxWidth: .infinity,minHeight: 40)
                                .background(
                                    Circle()
                                        .foregroundStyle(.circlePink.opacity(day.didSteps ? 0.4 : 0.0))
                                )

                        }
                    }
                }
              
            }
            .navigationTitle(Date().formatted(.dateTime.month(.wide)))
            .padding()
            .onAppear{
            
                if days.isEmpty {
                    createMonthDays(for: .now.startOfPreviousMonth)
                    createMonthDays(for: .now)
                    
                } else if days.count < 10 {
                    createMonthDays(for: .now)
                }
            }
        }
    }
    func createMonthDays(for date: Date){
        for dayOffset in 0..<date.numberOfDaysInMonth {
            //to create a new date you do Date() but in core data you need to create it in the viewContext
            let newDay = Day(context: viewContext)
            newDay.date = Calendar.current.date(byAdding: .day, value: dayOffset, to: date.startOfMonth)
            newDay.didSteps = false
        }
        
        do {
            try viewContext.save()
            print("✅\(date.monthFullName) days created")
        } catch  {
            print("Failed to save contaxt")
        }
    }
}



#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
