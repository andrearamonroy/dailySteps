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
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(mainViewModel)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        .onChange(of: scenePhase) {  oldPhase, newPhase in
            //any time the app goes to the background the steps will be saved
            if newPhase == .background {
                mainViewModel.healthManager.saveStepsForToday(stepCount: mainViewModel.healthManager.stepCount, context: persistenceController.container.viewContext)
            }
        }
    }
}
