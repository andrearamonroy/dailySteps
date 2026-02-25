//
//  Persistence.swift
//  dailySteps
//
//  Created by Andrea on 4/20/25.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    let databaseName : String = "dailySteps.sqlite"

    
    var oldStoreURL : URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return directory.appendingPathComponent(databaseName)
    }
    
    var sharedStoredURL : URL {
        
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.andrearamonroy.dailySteps") else {
            fatalError("❌ App Group container not found. Check your App Groups capability in Xcode.")
        }
    
        return container.appendingPathComponent(databaseName)
    }

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        //forcwed unwrapped
        let startDate = Calendar.current.dateInterval(of: .month, for: .now)!.start
        for dayOffSet in 0..<31 {
            let newDay = Day(context: viewContext)
            newDay.date = Calendar.current.date(byAdding: .day, value: dayOffSet ,to: startDate)
            newDay.didSteps = Bool.random()
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "dailySteps")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Always use shared store — works for both app and widget
            container.persistentStoreDescriptions.first!.url = sharedStoredURL
        }
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        migrateStore(for: container) // safe — exits immediately if old store doesn't exist
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    
    func migrateStore(for container: NSPersistentContainer) {
        let coordinator = container.persistentStoreCoordinator
        
        guard let oldStore = coordinator.persistentStore(for: oldStoreURL) else { return }
        print("old store deleted")
        
        
        do {
            let _ = try coordinator.migratePersistentStore(oldStore, to: sharedStoredURL, type: .sqlite)
            print("migrated from old to new store successfully")
        } catch {
            fatalError("Unable to migrate to shared to store : \(error)")
        }
        
        do {
            try FileManager.default.removeItem(at: oldStoreURL)
            print("old store deleted")
        } catch {
            print("unable to delete old store")
        }
    }
    
}
