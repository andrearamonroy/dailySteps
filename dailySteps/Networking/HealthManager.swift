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


class HealthManager: ObservableObject{
    
    private let healthStore = HKHealthStore()
    
    @Published var steps: Double = 0.0
    
    private let goalProvider: () -> Double
    
    //guards against non negatives
    private var currentGoal: Double {
         max(0, goalProvider())
     }
    
    init(goalProvider: @escaping () -> Double) {
        
        self.goalProvider = goalProvider
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        Task {
            do {
                if HKHealthStore.isHealthDataAvailable() {
                    try await healthStore.requestAuthorization(toShare: [], read: [stepType])
                    refreshTodaySteps()
                    enableBackgroundDelivery()
                    observeStepChanges()
                    checkYesterdayStepGoalIfNeeded()
                }
            } catch {
                print("steps: HealthKit authorization failed: \(error)")
            }
        }
    }

    
    /// Call this whenever you want to force a refresh
      func refreshTodaySteps() {
          fetchTodaySteps { [weak self] total in
              self?.steps = total
          }
      }
    
    /// Fetches total steps for today
    private func fetchTodaySteps(completion: @escaping (Double) -> Void) {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
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
        let stepType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        healthStore.enableBackgroundDelivery(for: stepType, frequency: .immediate) { success, error in
            if success {
                print("steps: background delivery enabled")
            } else {
                print("steps: failed to enable background delivery: \(String(describing: error))")
            }
        }
    }

    private func observeStepChanges() {
        let stepType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        let observerQuery = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] _, _, error in
            if let error = error {
                print("steps: observer error \(error)")
                return
            }

            print("steps: observer triggered")

            self?.fetchTodaySteps { total in
                self?.steps = total
                
                let goal = self?.currentGoal ?? 0
                
                if goal > 0 && total >= goal {
                    self?.saveGoalReachedIfNeeded()
                    print("saving to core data")
                }
                print("steps: updated in real-time to \(total)")
            }
        }

        healthStore.execute(observerQuery)
    }

    //saves didStepsTrue if they completed their step goal
    private func saveGoalReachedIfNeeded() {
        let context = PersistenceController.shared.container.viewContext
        let today = Calendar.current.startOfDay(for: Date())
        
        let request: NSFetchRequest<Day> = Day.fetchRequest()
        request.predicate = NSPredicate(format: "date == %@", today as NSDate)
        print("steps : before do ")
        do {
            let existing = try context.fetch(request)
            
            //review this logic ...? before is the old one below is new logic
            
//            if existing.first == nil {
//                let goal = Day(context: context)
//                goal.date = today
//                goal.didSteps = true
//                try context.save()
//                print("steps : Saved steps for today!!")
//                
//                //refresh the widget
//                refreshWidget()
//            
//            }
            
          
            let goal = self.currentGoal
            
            let record = Day(context: context)
            record.date = today
            if (goal > 0) && (self.steps >= goal) {
                record.didSteps = true
                try? context.save()
                
                //refresh widget
                self.refreshWidget()
                print("reached step goal for the day -- saving to core data: \(record.didSteps)")
            }
            
            
        } catch {
            print("steps : error saving didSteps to core data \(error.localizedDescription)")
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
                let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
                
                let query = HKStatisticsQuery(
                    quantityType: stepType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum
                ) { _, result, _ in
                    guard let sum = result?.sumQuantity() else { return }
                   
                    
                    let goal = self.currentGoal
                    
                    let record = Day(context: context)
                    record.date = yesterday
                    if (goal > 0) && (self.steps >= goal) {
                        record.didSteps = true
                        try? context.save()
                        
                        //refresh widget
                        self.refreshWidget()
                        print("steps: Backfilled yesterday’s goal: \(record.didSteps)")
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

