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


class HealthManager: ObservableObject {
    
    private let healthStore = HKHealthStore()
    
    //this will be deleted
   // @Published var steps: Double = 0.0
    
    //main actor bc we want this changes to show on the UI
    //(set) reusable outside, writable only inside
    @MainActor
    @Published private(set) var stepCount : Int = 0
    
    private let goalProvider: () -> Int
    
    //guards against non negatives
    private var currentGoal: Int {
         max(0, goalProvider())
     }
    
    //helper method --> computed property to use in all needed funcs
    //if it fails it returns nil
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
                   // checkYesterdayStepGoalIfNeeded()
                }
            } catch {
                print("steps: HealthKit authorization failed: \(error)")
            }
        }
    }

    
    ///High-level state update
    /// Call this whenever you want to force a refresh
    // Triggers UI / persistence / widgets
      func refreshTodaySteps() {
          fetchTodaySteps { [weak self] total in
              //rounded down since we don't want to round 9,999 to 10k
              let stepInt = Int(total.rounded(.down))
              
              Task { @MainActor in
                  self?.stepCount = stepInt
              }
          }
      }
    
    /// Fetches total steps for today
    /// this is a data provider
    private func fetchTodaySteps(completion: @escaping (Double) -> Void) {
        
        guard let stepType = stepType else { return }


        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date())
        
        let query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: startOfDay,
            intervalComponents: DateComponents(hour: 1)
        )
        
        query.initialResultsHandler = { _, results, _ in
            guard let stats = results else {
                completion(0.0)
                return
            }
            var totalSteps = 0.0
            stats.enumerateStatistics(from: startOfDay, to: Date()) { stat, _ in
                if let sum = stat.sumQuantity() {
                    totalSteps += sum.doubleValue(for: .count())
                }
            }
            DispatchQueue.main.async {
                completion(totalSteps)
            }
        }
        
        healthStore.execute(query)
    }

    private func enableBackgroundDelivery() {
        guard let stepType = stepType else { return }

        healthStore.enableBackgroundDelivery(for: stepType, frequency: .immediate) { success, error in
            if success {
                print("steps: background delivery enabled")
            } else {
                print("steps: failed to enable background delivery: \(String(describing: error))")
            }
        }
    }

    private func observeStepChanges() {
        guard let stepType = stepType else { return }

        let observerQuery = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] _, _, error in
            if let error = error {
                print("steps: observer error \(error)")
                return
            }

            print("steps: observer triggered")

            self?.fetchTodaySteps { total in
                
                let totalInt = Int(total.rounded(.down))
                
                
                Task { @MainActor in
                
                    guard let self = self else {return}
                    
                    self.stepCount = totalInt
                    
                    let goal = self.currentGoal
                    
                    
                    if goal > 0 && totalInt >= goal {
                        self.saveGoalReached()
                        print("saving to core data")
                    }
                    
                    
                    print("steps: updated in real-time to \(total)")
                    
                }
            }
        }

        healthStore.execute(observerQuery)
    }

    //saves didStepsTrue if they completed their step goal
    @MainActor
    private func saveGoalReached() {
        let context = PersistenceController.shared.container.viewContext
        let today = Calendar.current.startOfDay(for: Date())

        let request: NSFetchRequest<Day> = Day.fetchRequest()
        request.predicate = NSPredicate(format: "date == %@", today as NSDate)

        do {
            let existing = try context.fetch(request)
            //if today already exist in core data use that else create a new day
            let record = existing.first ?? Day(context: context)

            record.date = today

            let goal = self.currentGoal
            
            guard goal > 0, self.stepCount >= goal else {
                // Goal not reached → do nothing
                return
            }

            // Only mark true (never false)
            if record.didSteps == false {
                record.didSteps = true
                try context.save()
                refreshWidget()
                print("Reached step goal for today — saved didSteps = true")
            }

        } catch {
            print("Error saving didSteps: \(error.localizedDescription)")
        }
    }

    
    func saveStepsForToday(
        stepCount: Int,
        context: NSManagedObjectContext
    ) {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart)!

        // Fetch existing record for today
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
                // Update existing record
                day = existingDay
            } else {
                // Create new record
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

    

    //COME BACK 
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
                    
                    // Convert HealthKit Double → Int
                        let yesterdaySteps = Int(sum.doubleValue(for: .count()).rounded(.down))

                    
                    Task { @MainActor in
                    
                        
                        //MARK : COME BACK TO REVIEW THIS HERE
                        
                        let record: Day
                          if let first = existing.first {
                              record = first
                          } else {
                              record = Day(context: context)
                              record.date = yesterday
                          }
                        
                        // Compare yesterday's steps with currentGoal (Int)
                        if self.currentGoal > 0 && yesterdaySteps >= self.currentGoal {
                            record.didSteps = true
                            try? context.save()
                            
                            //refresh widget
                            self.refreshWidget()
                            print("steps: Backfilled yesterday’s goal: \(record.didSteps)")
                        }
                    }
  
                }

                healthStore.execute(query)
            }
        } catch {
            print("steps : Error checking yesterday’s goal: \(error)")
        }
    }
    
    
    
    func refreshWidget(){
        WidgetCenter.shared.reloadTimelines(ofKind: "dailyStepsWidget")
    }
}

extension HealthManager {
    /// Gets step count for a specific date range
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
