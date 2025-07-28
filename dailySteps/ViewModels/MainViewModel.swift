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
    @Published var steps: Double = 0.0
    @Published var stepGoal: Double = 10000
    
    private var healthManager = HealthManager()
    private var notificationSentForDay = Date.distantPast
    private let calendar = Calendar.current
    private var cancellables = Set<AnyCancellable>()
    
    init(){
        // Observe HealthManager's steps and update
        healthManager.$steps
                .receive(on: DispatchQueue.main)
                .sink { [weak self] newSteps in
                    print("Steps updated:", newSteps)
                    self?.steps = newSteps
                    self?.checkStepGoalAndNotify(steps: newSteps)
                }
                .store(in: &cancellables)
        
        requestNotificationPermission()
    }
    
    private func checkStepGoalAndNotify(steps: Double) {
        let today = Date().startOfDay
        // Only notify once per day
        guard steps >= 10_949 && notificationSentForDay < today else { return }
        
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
        content.body = "You've reached 10,000 steps today"
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
