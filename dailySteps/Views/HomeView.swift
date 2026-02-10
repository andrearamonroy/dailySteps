//
//  HomeView.swift
//  dailySteps
//
//  Created by Andrea Monroy on 7/23/25.
//
import SwiftUI


struct HomeView: View {
    @EnvironmentObject private var mainViewModel : MainViewModel
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            NavigationStack {
                BadgesTabView()
            }
            .tabItem {
                Label("Badges", systemImage: "rosette")
            }
            .tag(0)
            
            NavigationStack {
                StepView()
            }
            .tabItem {
                Label("Steps", systemImage: "figure.walk")
            }
            .tag(1)
            
            NavigationStack {
                ChallengesListView()
            }
            .tabItem {
                Label("Challenges", systemImage: "trophy")
            }
            .tag(2)
            
        }
        .onAppear {
                   // Force it to tag 1 when the view appears
                   if appState.selectedTab != 1 {
                       appState.selectedTab = 1
                   }
               }
        .onChange(of: appState.shouldNavigateToStepView) { oldValue, newValue in
            if newValue {
                appState.selectedTab = 1
                appState.shouldNavigateToStepView = false
            }
        }
    }
}

#Preview {
    HomeView()
}


