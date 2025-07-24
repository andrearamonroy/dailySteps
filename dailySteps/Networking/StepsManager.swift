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

class HealthManager: ObservableObject {
    private let healthStore = HKHealthStore()
    
    @Published var steps: Double = 0.0
    
    init() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        Task {
            do {
                if HKHealthStore.isHealthDataAvailable() {
                    try await healthStore.requestAuthorization(toShare: [], read: [stepType])
                    startStepQuery()
                    enableBackgroundDelivery()
                    observeStepChanges()
                }
            } catch {
                print("steps: HealthKit authorization failed: \(error)")
            }
        }
    }
    
    private func startStepQuery() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: Date()), end: Date())
        
        let query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: Calendar.current.startOfDay(for: Date()),
            intervalComponents: DateComponents(hour: 1)
        )

        query.initialResultsHandler = { [weak self] _, results, error in
            guard let self = self, let stats = results else {
                print("steps: Failed to fetch steps: \(String(describing: error))")
                return
            }

            var totalSteps = 0.0
            stats.enumerateStatistics(from: Calendar.current.startOfDay(for: Date()), to: Date()) { stat, _ in
                if let sum = stat.sumQuantity() {
                    totalSteps += sum.doubleValue(for: .count())
                }
            }

            DispatchQueue.main.async {
                self.steps = totalSteps
            }
        }

        // Enable real-time updates
        query.statisticsUpdateHandler = { [weak self] _, stat, _, _ in
            if let quantity = stat?.sumQuantity() {
                let newSteps = quantity.doubleValue(for: .count())
                DispatchQueue.main.async {
                    self?.steps = newSteps
                    print("steps: in real time fetch \(self?.steps)")
                }
            }
        }

        healthStore.execute(query)
    }
    
    
    
    private func saveGoalReachedIfNeeded(){
        let context = PersistenceController.shared.container.viewContext
        let today = Calendar.current.startOfDay(for: Date())
        
        let request: NSFetchRequest<Day> = Day.fetchRequest()
                request.predicate = NSPredicate(format: "date == %@", today as NSDate)
        
        do{
            let existing = try context.fetch(request)
            if existing.first == nil {
                let goal = Day(context: context)
                goal.date = today
                goal.didSteps = true
                try context.save()
                print("steps : Saved 10k steps for today!!")
            }
        }catch{
            print(
                "steps : error saving didSteps to core data \(error.localizedDescription)"
            )
        }
    }
    private func checkYesterdayStepGoalIfNeeded(){
        let context = PersistenceController.shared.container.viewContext
        let yesterday = Date().yesterday
        let nextDay = yesterday.nextDay
        
        let request: NSFetchRequest<Day> = Day.fetchRequest()
            request.predicate = NSPredicate(format: "date == %@", yesterday as NSDate)
        
        do{
            let existing = try context.fetch(request)
            if existing.isEmpty {
                let predicate = HKQuery.predicateForSamples(withStart: yesterday, end: nextDay)
                let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
                
                let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                             guard let sum = result?.sumQuantity() else { return }
                             let steps = sum.doubleValue(for: .count())

                             let record = Day(context: context)
                             record.date = yesterday
                            record.didSteps = steps >= 10_000
                             try? context.save()
                    print("steps: Backfilled yesterday’s goal: \(record.didSteps)")
                         }

                         HKHealthStore().execute(query)
            }
        }catch{
            print("steps : Error checking yesterday’s goal: \(error)")
        }
        
        
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
            self?.startStepQuery()
        }

        healthStore.execute(observerQuery)
    }
}
