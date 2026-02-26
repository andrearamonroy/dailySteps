//
//  StepsManager.swift
//  dailySteps
//
//  Created by Andrea on 7/12/25.
//

import Foundation
import HealthKit
import Combine
import CoreData
import WidgetKit
import UIKit

class HealthManager: ObservableObject {
    
    private let healthStore = HKHealthStore()
    
    @MainActor
    @Published private(set) var stepCount: Int = 0 {
        didSet {
            guard stepCount != oldValue else { return }
            guard let sharedDefaults = UserDefaults(suiteName: "group.com.andrearamonroy.dailySteps") else { return }
            sharedDefaults.set(stepCount, forKey: "currentStepCount")
            sharedDefaults.set(Date(), forKey: "stepCountDate")
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    private let goalProvider: () -> Int
    
    // Add timer property
    private var refreshTimer: Timer?
    
    private var currentGoal: Int {
         max(0, goalProvider())
     }
    
    private var stepType : HKQuantityType? {
        HKQuantityType.quantityType(forIdentifier: .stepCount)
    }
    
    init(goalProvider: @escaping () -> Int) {
        self.goalProvider = goalProvider
        
        guard let stepType = stepType else { return }

        Task {
            do {
                if HKHealthStore.isHealthDataAvailable() {
                    try await healthStore.requestAuthorization(toShare: [], read: [stepType])
                    refreshTodaySteps()
                    enableBackgroundDelivery()
                    observeStepChanges()
                    startPeriodicRefresh() // Add timer
                    setupAppLifecycleObservers() // Add lifecycle monitoring
                }
            } catch {
                print("steps: HealthKit authorization failed: \(error)")
            }
        }
    }
    
    // MARK: - Periodic Refresh (Most Reliable)
    private func startPeriodicRefresh() {
        // Stop any existing timer
        refreshTimer?.invalidate()
        
        // Refresh every 10 seconds while app is active
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            print("⏰ Timer refresh triggered")
            self?.refreshTodaySteps()
        }
        
        // Make sure timer runs in common modes (works during scrolling, etc.)
        if let timer = refreshTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    private func stopPeriodicRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        print("⏸️ Timer stopped")
    }
    
    // MARK: - App Lifecycle
    private func setupAppLifecycleObservers() {
        // Refresh when app becomes active
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("📱 App became active - refreshing steps")
            self?.refreshTodaySteps()
            self?.startPeriodicRefresh() // Restart timer
        }
        
        // Stop timer when app goes to background (save battery)
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("📱 App going to background - stopping timer")
            self?.stopPeriodicRefresh()
        }
    }

    // MARK: - High-level state update
    func refreshTodaySteps() {
        fetchTodaySteps { [weak self] total in
            let stepInt = Int(total.rounded(.down))
            
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                // Always write to UserDefaults for widget, even if UI value hasn't changed
                if let defaults = UserDefaults(suiteName: "group.com.andrearamonroy.dailySteps") {
                    defaults.set(stepInt, forKey: "currentStepCount")
                    defaults.set(Date(), forKey: "stepCountDate")
                }
                
                
                guard stepInt != self.stepCount else { return }
                
                print("🔄 Updating steps: old=\(self.stepCount), new=\(stepInt)")
                
                // Never overwrite a real step count with zero UNLESS it's a new day
                if stepInt == 0 && self.stepCount > 0 {
                    let lastUpdateDate = UserDefaults(suiteName: "group.com.andrearamonroy.dailySteps")?.object(forKey: "stepCountDate") as? Date ?? Date()
                    let isNewDay = !Calendar.current.isDateInToday(lastUpdateDate)
                    
                    if !isNewDay {
                        print("⚠️ Ignoring zero step update — same day, keeping: \(self.stepCount)")
                        return
                    }
                    print("🌅 New day detected — resetting step count to 0")
                }
                
                // Always update to trigger UI refresh
                self.stepCount = stepInt
                
                let goal = self.currentGoal
                if goal > 0 && stepInt >= goal {
                    self.saveGoalReached()
                    print("✅ Goal reached! Saving to Core Data")
                }
            
                
                print("📊 Steps updated to: \(stepInt)")
            }
        }
    }
    
    // MARK: - Fetch Today's Steps
    private func fetchTodaySteps(completion: @escaping (Double) -> Void) {
        guard let stepType = stepType else {
            completion(0.0)
            return
        }

        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date())
        
        let query = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            if let error = error {
                print("❌ Fetch steps error: \(error.localizedDescription)")
                completion(0.0)
                return
            }
            
            let totalSteps = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0.0
            
            DispatchQueue.main.async {
                completion(totalSteps)
            }
        }
        
        healthStore.execute(query)
    }

    // MARK: - Background Delivery
    private func enableBackgroundDelivery() {
        guard let stepType = stepType else { return }

        healthStore.enableBackgroundDelivery(for: stepType, frequency: .immediate) { success, error in
            if success {
                print("✅ Background delivery enabled")
            } else {
                print("❌ Failed to enable background delivery: \(String(describing: error))")
            }
        }
    }

    // MARK: - Observer Query
    private func observeStepChanges() {
        guard let stepType = stepType else { return }

        let observerQuery = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] _, completionHandler, error in
            if let error = error {
                print("❌ Observer error: \(error)")
                completionHandler()
                return
            }

            print("🔔 Observer triggered - step count changed")
            self?.refreshTodaySteps()
            completionHandler()
        }

        healthStore.execute(observerQuery)
    }

    // MARK: - Save Goal to Core Data
    @MainActor
    private func saveGoalReached() {
        let context = PersistenceController.shared.container.viewContext
        let today = Calendar.current.startOfDay(for: Date())

        let request: NSFetchRequest<Day> = Day.fetchRequest()
        request.predicate = NSPredicate(format: "date == %@", today as NSDate)

        do {
            let existing = try context.fetch(request)
            let record = existing.first ?? Day(context: context)
            record.date = today
            record.stepCount = Int64(self.stepCount) // always update

            let goal = self.currentGoal
            if goal > 0 && self.stepCount >= goal && record.didSteps == false {
                record.didSteps = true
                print("✅ Goal reached — saved didSteps = true")
            }

            try context.save()
            refreshWidget()

        } catch {
            print("❌ Error saving: \(error.localizedDescription)")
        }
    }

    func saveStepsForToday(
        stepCount: Int,
        context: NSManagedObjectContext
    ) {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart)!

        let request: NSFetchRequest<Day> = Day.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            todayStart as NSDate,
            tomorrowStart as NSDate
        )

        do {
            let results = try context.fetch(request)

            let day: Day
            if let existingDay = results.first {
                day = existingDay
            } else {
                day = Day(context: context)
                day.date = todayStart
            }

            day.stepCount = Int64(stepCount)

            try context.save()
            print("steps: Saved step count for today:", stepCount)

        } catch {
            print("steps: Failed to save step count:", error)
        }
    }

    private func checkYesterdayStepGoalIfNeeded() {
        let context = PersistenceController.shared.container.viewContext
        let yesterday = Date().yesterday
        let nextDay = yesterday.nextDay
        
        let request: NSFetchRequest<Day> = Day.fetchRequest()
        request.predicate = NSPredicate(format: "date == %@", yesterday as NSDate)
        
        do {
            let existing = try context.fetch(request)
            if existing.isEmpty {
                let predicate = HKQuery.predicateForSamples(withStart: yesterday, end: nextDay)
                
                guard let stepType = stepType else { return }
                
                let query = HKStatisticsQuery(
                    quantityType: stepType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum
                ) { _, result, _ in
                    guard let sum = result?.sumQuantity() else { return }
                    
                    let yesterdaySteps = Int(sum.doubleValue(for: .count()).rounded(.down))
                    
                    Task { @MainActor in
                        let record: Day
                        if let first = existing.first {
                            record = first
                        } else {
                            record = Day(context: context)
                            record.date = yesterday
                        }
                        
                        if self.currentGoal > 0 && yesterdaySteps >= self.currentGoal {
                            record.didSteps = true
                            try? context.save()
                            self.refreshWidget()
                            print("steps: Backfilled yesterday's goal: \(record.didSteps)")
                        }
                    }
                }

                healthStore.execute(query)
            }
        } catch {
            print("steps : Error checking yesterday's goal: \(error)")
        }
    }
    
    func refreshWidget(){
        WidgetCenter.shared.reloadTimelines(ofKind: "dailyStepsWidget")
    }
    
    // MARK: - Cleanup
    deinit {
        stopPeriodicRefresh()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Extensions
extension HealthManager {
    func getSteps(from startDate: Date, to endDate: Date, completion: @escaping (Int) -> Void) {
        guard let stepType = stepType else {
            completion(0)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        
        let query = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            if let error = error {
                print("❌ Error fetching steps: \(error.localizedDescription)")
                completion(0)
                return
            }
            
            let steps = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
            completion(Int(steps.rounded(.down)))
        }
        
        healthStore.execute(query)
    }
}
