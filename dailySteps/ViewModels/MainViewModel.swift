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
    
    var healthManager: HealthManager!
    
    private var notificationSentForDay = Date.distantPast
    private let calendar = Calendar.current
    private var cancellables = Set<AnyCancellable>()
    
    //Today's date to be displayed in the main view
    @Published var todayDate = Date()
    //cancellable for the todayDate timer
    private var todayTimer: AnyCancellable?
    
    
    private let groupDefaults = UserDefaults(suiteName: "group.com.andrearamonroy.dailySteps")!
    
    private let cloudKitManager = CloudKitManager.shared

//        // MARK: - Theme Colors
//        @Published var primaryColor: BackgroundColor {
//            didSet { saveColors() }
//        }
//        @Published var secondaryColor: BackgroundColor {
//            didSet { saveColors() }
//        }
//    @Published var backgroundColor: BackgroundColor {
//        didSet { saveColors() }
//    }
    
    
    init(){

        
        self.healthManager = HealthManager(goalProvider: { [weak self] in
                   self?.stepGoal ?? 0
               })
        
      
//        // Load persisted colors from App Group
//        let primaryRaw = groupDefaults.string(forKey: "primaryColor") ?? BackgroundColor.aurora.rawValue
//        let secondaryRaw = groupDefaults.string(forKey: "secondaryColor") ?? BackgroundColor.aurora.rawValue
//        let backgroundRaw = groupDefaults.string(forKey: "backgroundColor") ?? BackgroundColor.aurora.rawValue
//        
//        self.primaryColor = BackgroundColor(rawValue: primaryRaw) ?? .aurora
//        self.secondaryColor = BackgroundColor(rawValue: secondaryRaw) ?? .aurora
//        
//        self.backgroundColor = BackgroundColor(rawValue: backgroundRaw) ?? .aurora



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
    
 /*
    
    private func saveColors() {
        groupDefaults.set(primaryColor.rawValue, forKey: "primaryColor")
        groupDefaults.set(secondaryColor.rawValue, forKey: "secondaryColor")
        groupDefaults.set(backgroundColor.rawValue, forKey: "backgroundColor")

        // Tell widgets to refresh
        WidgetCenter.shared.reloadAllTimelines()
    }
    
  */
    
    func checkAndUpdateProgress(currentSteps: Int) {
        cloudKitManager.updateTodayProgress(stepCount: currentSteps) { result in
            switch result {
            case .success:
                print("✅ Progress updated successfully")
                
                // Fetch updated enrollment to check status
                self.cloudKitManager.fetchActiveEnrollment { enrollmentResult in
                    if case .success(let (challenge, enrollment)) = enrollmentResult {
                        let streak = enrollment["currentStreak"] as? Int ?? 0
                        let isActive = enrollment["isActive"] as? Bool ?? true
                        let duration = challenge["duration"] as? Int ?? 1
                        let totalDaysCompleted = enrollment["totalDaysCompleted"] as? Int ?? 0
                        
                        // Send challenge streak milestone notification
                        NotificationManager.shared.sendStreakMilestone(streak: streak, type: .challenge)
                        
                        // Check if challenge just completed
                        if !isActive {
                            print("🎉 Challenge is now complete - posting notification")
                            DispatchQueue.main.async {
                                NotificationCenter.default.post(name: NSNotification.Name("ChallengeEnded"), object: nil)
                            }
                            
                            // Show feedback prompt after completing a full challenge
                            if self.shouldShowFeedbackPrompt() {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                                    NotificationCenter.default.post(name: NSNotification.Name("ShowFeedbackPrompt"), object: nil)
                                }
                            }
                        }
                        // Show prompt after first successful day if challenge is multi-day
                        else if duration > 1 && totalDaysCompleted == 1 {
                            print("🎯 First day of multi-day challenge completed!")
                            if self.shouldShowFeedbackPrompt() {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                    NotificationCenter.default.post(name: NSNotification.Name("ShowFeedbackPrompt"), object: nil)
                                }
                            }
                        }
                    }
                }
                
            case .failure(let error):
                print("❌ Failed to update progress: \(error.localizedDescription)")
            }
        }
    }

func shouldShowFeedbackPrompt() -> Bool {
        // Don't show more than once every 7 days
        if let lastPrompt = UserDefaults.standard.object(forKey: "lastFeedbackPromptDate") as? Date {
            let daysSinceLastPrompt = Calendar.current.dateComponents([.day], from: lastPrompt, to: Date()).day ?? 0
            if daysSinceLastPrompt < 7 {
                return false
            }
        }
        return true
    }
    
    
    //If i need to do push notification I will make a separate class for this
    private func checkStepGoalAndNotify(steps: Int, stepGoal: Int ) {
        let today = Date().startOfDay
        // Only notify once per day
        guard steps >= stepGoal && notificationSentForDay < today else { return }
        
       // sendNotification()
        notificationSentForDay = today
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error = \(error.localizedDescription)")
            } else if granted {
                print("Notification permission granted!!!")
                
                // Schedule daily reminder at 9 AM
                var dateComponents = DateComponents()
                dateComponents.hour = 9
                dateComponents.minute = 0
                
                //reminders with streak count
                NotificationManager.shared.scheduleDailyGoalReminder(at: dateComponents)
                
                //reminders with encouragement messages. 
                NotificationManager.shared.scheduleDailyEncouragementMessages()
            }
        }
    }
    @MainActor
    // In StepView or MainViewModel
    func scheduleEveningCheck() {
        NotificationManager.shared.scheduleEveningReminderIfNeeded(
            currentSteps: healthManager.stepCount,
            goalSteps: Int(stepGoal)
        )
    }
    /*private func sendNotification() {
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
    }*/

}

extension UserDefaults {
    static let group: UserDefaults = {
        UserDefaults(suiteName: "group.com.andrearamonroy.dailySteps") ?? .standard
    }()
}
