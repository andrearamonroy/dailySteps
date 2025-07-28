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

    @StateObject private var mainViewModel = MainViewModel()
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(mainViewModel)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
