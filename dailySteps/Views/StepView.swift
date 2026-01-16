//
//  StepView.swift
//  dailySteps
//
//  Created by Andrea Monroy on 12/30/25.
//

import SwiftUI

struct StepView : View {
    @EnvironmentObject private var mainViewModel : MainViewModel
    @State private var showSettings = false  
    var body : some View {
        NavigationStack {
            VStack {
                
                Text(mainViewModel.todayDate, format: .dateTime.weekday().day().month().year())
                
                
                
                
                Text("\(mainViewModel.healthManager.stepCount)")
                    .font(.title)
                Text("steps")
                    .font(.headline)
                    .bold()
                Text("--------------")
                Text("Goal: \(Int(mainViewModel.stepGoal))")
                
                if mainViewModel.healthManager.stepCount >= mainViewModel.stepGoal {
                    Text("Goal Reached")
                        .foregroundStyle(.green)
                } else {
                    Text( "Keep going")
                        .foregroundStyle(.orange)
                }
                
                
                WeeklyStepsView()
                
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: StepGoalSettingsView()
                        .environmentObject(mainViewModel)) {
                            Image(systemName: "gearshape")
                        }
                }
            }
            
        }

        
        .onAppear {
            mainViewModel.healthManager.refreshTodaySteps()
        }
       
        
    }
}

#Preview {
    StepView()
}
