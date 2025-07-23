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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
