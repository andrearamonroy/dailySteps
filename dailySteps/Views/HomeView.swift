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
            TabView(content: {
               CalendarView()
                    .tabItem {
                        Label("Calendar", systemImage: "calendar")
                    }
                StepView()
                    .tabItem {
                        Label("Steps", systemImage: "figure.walk")
                    }
            })
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

struct StepView : View {
    @EnvironmentObject private var mainViewModel : MainViewModel
    var body : some View {
        VStack {
        Text("Steps today")
            .font(.largeTitle)
            .bold()
        Text("\(Int(mainViewModel.steps)) steps")
            .font(.title)
        
        if mainViewModel.steps >= 5000 {
            Text("Goal Reached")
                .foregroundStyle(.green)
        } else {
            Text( "Keep going")
                .foregroundStyle(.orange)
        }
        
    }
    }
}
