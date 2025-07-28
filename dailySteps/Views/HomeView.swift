//
//  HomeView.swift
//  dailySteps
//
//  Created by Andrea Monroy on 7/23/25.
//
import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var mainViewModel : MainViewModel
    
    var body: some View {
        NavigationView {
            VStack {
            Text("Steps today")
                .font(.largeTitle)
                .bold()
            Text("\(Int(mainViewModel.steps)) steps")
                .font(.title)
            
            if mainViewModel.steps >= 10000 {
                Text("Goal Reached")
                    .foregroundStyle(.green)
            } else {
                Text( "Keep going")
                    .foregroundStyle(.orange)
            }
            
        }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        StepGoalSettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }

                }
            }
    }
  
    }
}

#Preview {
    HomeView()
}
