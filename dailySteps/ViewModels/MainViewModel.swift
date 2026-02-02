//
//  MainViewModel.swift
//  dailySteps
//
//  Created by Andrea Monroy on 7/23/25.
//

import Foundation
import UserNotifications
import Combine
import SwiftUI
import WidgetKit


class MainViewModel : ObservableObject {
    //Step Goal for the user the change
    /// AppStorage works with swiftui
    @AppStorage("stepGoal") var stepGoal : Int = 10_000 {
        didSet {
            print("oldValue = \(oldValue), newValue = \(stepGoal)")
            
            guard oldValue != stepGoal else { return }
            stepGoalHistoyManager.addChange(goal: stepGoal)
            
            print("Step goal actually changed from \(oldValue) to \(stepGoal). Save it!")
        }
    }
    
    //including the group so that the widget has access to the grace days 
    @AppStorage(
        "graceDays",
        store: UserDefaults(suiteName: "group.com.andrearamonroy.dailySteps")
    )
    var graceDays: Int = 0

    
    @Published var stepGoalHistoyManager = StepGoalHistoryManager()
    
   lazy var healthManager = HealthManager(
        goalProvider: { [weak self] in
            //pass step goal from the user to the health kit manager so that we can compare to the goal and then save
            self?.stepGoal ?? 0
        }
    )
    
    private var notificationSentForDay = Date.distantPast
    private let calendar = Calendar.current
    private var cancellables = Set<AnyCancellable>()
    
    //Today's date to be displayed in the main view
    @Published var todayDate = Date()
    //cancellable for the todayDate timer
    private var todayTimer: AnyCancellable?
    
    
    private let groupDefaults = UserDefaults(suiteName: "group.com.andrearamonroy.dailySteps")!

        // MARK: - Theme Colors
        @Published var primaryColor: PastelColor {
            didSet { saveColors() }
        }
        @Published var secondaryColor: PastelColor {
            didSet { saveColors() }
        }
    @Published var backgroundColor: PastelColor {
        didSet { saveColors() }
    }
    
    
    init(){

        
      
        // Load persisted colors from App Group
        let primaryRaw = groupDefaults.string(forKey: "primaryColor") ?? PastelColor.blue.rawValue
        let secondaryRaw = groupDefaults.string(forKey: "secondaryColor") ?? PastelColor.mint.rawValue
        let backgroundRaw = groupDefaults.string(forKey: "backgroundColor") ?? PastelColor.mint.rawValue
        
        self.primaryColor = PastelColor(rawValue: primaryRaw) ?? .blue
        self.secondaryColor = PastelColor(rawValue: secondaryRaw) ?? .mint
        
        self.backgroundColor = PastelColor(rawValue: backgroundRaw) ?? .mint



        // Observe HealthManager's steps and update
        healthManager.$stepCount
                .receive(on: DispatchQueue.main)
                .sink { [weak self] newSteps in
                    /*
                    weak self prevents retain cycles and memory leaks but it can become nil at any time
                    self is optional because of weak self we need it to actually exist to call .checkStepGoalAndNotify
                    below is the same as =
                     
                     if self == nil {
                         return // exit the closure immediately
                     }
                     let self = self! // unwrap self safely for the rest of the closure
                     
                    */
                    guard let self = self else { return }
                    
                    print("Steps updated:", newSteps)
                    self.checkStepGoalAndNotify(steps: newSteps, stepGoal: self.stepGoal)
                }
                .store(in: &cancellables)
        
        requestNotificationPermission()
        
        CloudKitManager.setHealthManager(healthManager)
     
        // use it again later to create more challenges
        //CloudKitManager.shared.createSampleChallenges()
       // CloudKitReferenceAdder.shared.addReferences()
        
        
    }
    
 
    
    private func saveColors() {
        groupDefaults.set(primaryColor.rawValue, forKey: "primaryColor")
        groupDefaults.set(secondaryColor.rawValue, forKey: "secondaryColor")

        // Tell widgets to refresh
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    //If i need to do push notification I will make a separate class for this
    private func checkStepGoalAndNotify(steps: Int, stepGoal: Int ) {
        let today = Date().startOfDay
        // Only notify once per day
        guard steps >= stepGoal && notificationSentForDay < today else { return }
        
        sendNotification()
        notificationSentForDay = today
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error = \(error.localizedDescription)")
            } else if granted {
                print("Notification permision granted!!!")
            }
        }
    }
    
    private func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Congrats!"
        content.body = "You've reached \(stepGoal) steps today"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger)
        UNUserNotificationCenter.current().add(request) {error in
            if let error = error {
                print("Error scheduling step goal reached notification \(error.localizedDescription)")
            }
        }
    }

}
