//
//  dailyStepsApp.swift
//  dailySteps
//
//  Created by Andrea on 4/20/25.
//

import SwiftUI

@main
struct dailyStepsApp: App {
    let persistenceController = PersistenceController.shared
    
    //might use later to know what scene or state the app is in 
    @Environment(\.scenePhase) private var scenePhase
  

    @StateObject private var mainViewModel = MainViewModel()
    
    @State private var hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    
    @StateObject private var appState = AppState()
    
    @State private var isShowingSplash = true
   
    init(){
#if DEBUG
       // setupCloudKitmain()
#endif
    }
    
  
    
    var body: some Scene {
        
        WindowGroup {
            ZStack {
                // Your existing code — unchanged
                ZStack {
                    if hasCompletedOnboarding {
                        HomeView()
                            .environmentObject(mainViewModel)
                            .environment(\.managedObjectContext, persistenceController.container.viewContext)
                            .environmentObject(appState)
                    } else {
                        WelcomeView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    }
                }

                // Splash on top
                if isShowingSplash {
                    LetteringView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemBackground).ignoresSafeArea())
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .zIndex(1) // ensures it always sits on top
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        isShowingSplash = false
                    }
                }
            }
        }
        .onChange(of: scenePhase) {  oldPhase, newPhase in
            //any time the app goes to the background the steps will be saved
            if newPhase == .background {
                mainViewModel.healthManager.saveStepsForToday(stepCount: mainViewModel.healthManager.stepCount, context: persistenceController.container.viewContext)
            }
        }
    }
}
