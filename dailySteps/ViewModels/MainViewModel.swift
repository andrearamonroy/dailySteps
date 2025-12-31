//
//  MainViewModel.swift
//  dailySteps
//
//  Created by Andrea Monroy on 7/23/25.
//

import Foundation
import UserNotifications
import Combine


class MainViewModel : ObservableObject {
    //Step Goal for the user the change
    @Published var stepGoal: Double = 10000
    
   lazy var healthManager = HealthManager(
        goalProvider: { [weak self] in
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
    
    init(){
        // Observe HealthManager's steps and update
        healthManager.$steps
                .receive(on: DispatchQueue.main)
                .sink { [weak self] newSteps in
                    print("Steps updated:", newSteps)
                    self?.checkStepGoalAndNotify(steps: newSteps, stepGoal: self?.stepGoal ?? 0.0)
                }
                .store(in: &cancellables)
        
        requestNotificationPermission()
    }
    
    private func checkStepGoalAndNotify(steps: Double, stepGoal: Double ) {
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
    
    //timer to update today's date on the main screen
    func startTodayTimer(){
        //timer check every 60 secs to update at midnight
        todayTimer = Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                self?.todayDate = date
            }
    }
    //timer (stop action) to update today's date on the main screen
    func stopTodayTimer(){
        todayTimer?.cancel()
        todayTimer = nil
    }

}
