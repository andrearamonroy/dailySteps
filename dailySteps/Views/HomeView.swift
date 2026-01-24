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
                
                ChallengesListView()
                    .tabItem {
                        Label("Challenges", systemImage: "bolt")
                    }
                
                StepGoalHistoryView()
                    .tabItem {
                        Label("History", systemImage: "book")
                    }
                
            })
        }
  
    }
}

#Preview {
    HomeView()
}


