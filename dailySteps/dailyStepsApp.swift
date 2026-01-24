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
   
    init(){
#if DEBUG
       // setupCloudKitmain()
#endif
    }
    
    func setupCloudKitmain() {
        // Step 1: Check CloudKit is available
        CloudKitManager.shared.checkAccountStatus { available, error in
            if available {
                print("✅ CloudKit available")
                
                // Step 2: Add references (runs once, safe to run multiple times)
                CloudKitReferenceAdder.shared.addReferences()
                
                // That's it! Now go configure in dashboard
            } else {
                print("❌ CloudKit not available: \(error?.localizedDescription ?? "")")
            }
        }
    }
    
    var body: some Scene {
        

        WindowGroup {
            if hasCompletedOnboarding {
                HomeView()
                    .environmentObject(mainViewModel)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            } else {
                WelcomeView(hasCompletedOnboarding: $hasCompletedOnboarding)
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
