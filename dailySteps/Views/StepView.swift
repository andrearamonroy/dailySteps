//
//  StepView.swift
//  dailySteps
//
//  Created by Andrea Monroy on 12/30/25.
//

import SwiftUI

struct StepView : View {
    @EnvironmentObject private var mainViewModel : MainViewModel
    var body : some View {
        VStack {
            
            Text(mainViewModel.todayDate, format: .dateTime.weekday().day().month().year())
             
            
            
            
            Text("\(Int(mainViewModel.healthManager.steps))")
                .font(.title)
            Text("steps")
                .font(.headline)
                .bold()
            Text("--------------")
            Text("Goal: \(Int(mainViewModel.stepGoal))")
            
            if mainViewModel.healthManager.steps >= mainViewModel.stepGoal {
                Text("Goal Reached")
                    .foregroundStyle(.green)
            } else if mainViewModel.healthManager.steps < mainViewModel.stepGoal {
                Text( "Keep going")
                    .foregroundStyle(.orange)
            } else if mainViewModel.healthManager.steps == 0.0 {
                Text( "Get your first step in! You got this!")
                    .foregroundStyle(.orange)
            }
            
        }
        
        .onAppear {
            mainViewModel.startTodayTimer()
        }
        .onDisappear {
            mainViewModel.stopTodayTimer()
        }
        
    }
}

#Preview {
    StepView()
}
