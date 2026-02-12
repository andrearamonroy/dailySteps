import UserNotifications
import Foundation

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private init() {}
    
    // MARK: - Schedule Daily Goal Reminder
    func scheduleDailyGoalReminder(at time: DateComponents) {
        let content = UNMutableNotificationContent()
        content.title = "Time to Move! 🚶‍♀️"
        content.body = "Don't forget to reach your step goal today. Every step counts!"
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyGoalReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling daily reminder: \(error.localizedDescription)")
            } else {
                print("✅ Daily reminder scheduled for \(time.hour ?? 0):\(time.minute ?? 0)")
            }
        }
    }
    
    // MARK: - Schedule Encouraging Messages Based on Progress
    func scheduleEncouragingNotification(currentSteps: Int, goalSteps: Int) {
        // Remove any existing encouraging notifications
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["encouragingMessage"])
        
        let progress = Double(currentSteps) / Double(goalSteps)
        
        let content = UNMutableNotificationContent()
        content.sound = .default
        
        var triggerTime: TimeInterval = 0
        
        // Different messages based on progress
        if progress < 0.25 {
            // Less than 25% - early motivation
            content.title = "Let's Get Moving! 🌟"
            content.body = "You've got \(goalSteps - currentSteps) steps to go. Start strong!"
            triggerTime = 60 * 60 * 2 // 2 hours from now
            
        } else if progress < 0.50 {
            // 25-50% - keep going
            content.title = "You're Making Progress! 💪"
            content.body = "Halfway there! Just \(goalSteps - currentSteps) more steps to go."
            triggerTime = 60 * 60 * 3 // 3 hours from now
            
        } else if progress < 0.75 {
            // 50-75% - almost there
            content.title = "So Close! 🎯"
            content.body = "Only \(goalSteps - currentSteps) steps left. You've got this!"
            triggerTime = 60 * 60 * 2 // 2 hours from now
            
        } else if progress < 1.0 {
            // 75-99% - final push
            content.title = "Final Push! 🔥"
            content.body = "Just \(goalSteps - currentSteps) steps away from your goal!"
            triggerTime = 60 * 30 // 30 minutes from now
            
        } else {
            // Goal reached - don't schedule another notification
            return
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: triggerTime, repeats: false)
        let request = UNNotificationRequest(identifier: "encouragingMessage", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling encouraging notification: \(error.localizedDescription)")
            } else {
                print("✅ Encouraging notification scheduled")
            }
        }
    }
   
    // MARK: - Send Goal Reached Celebration
    func sendGoalReachedNotification(type: StreakType) {
        let content = UNMutableNotificationContent()
        content.sound = .default
        
        switch type {
        case .personal:
            content.title = "Personal Goal Crushed! 🎉"
            content.body = "Amazing work! You've reached your personal step goal today."
        case .challenge:
            content.title = "Challenge Goal Complete! 🏆"
            content.body = "Incredible! You've hit today's challenge target. Keep it up!"
        }
        
        let identifier = type == .personal ? "personalGoalReached" : "challengeGoalReached"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error sending \(type) goal notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Send Streak Milestone Notification
    func sendStreakMilestone(streak: Int, type: StreakType) {
        guard streak > 0 && (streak % 7 == 0 || streak == 3 || streak == 5) else { return }
        
        let content = UNMutableNotificationContent()
        content.sound = .default
        
        // Different messaging based on type
        let prefix = type == .personal ? "Personal" : "Challenge"
        let emoji = type == .personal ? "🔥" : "🏆"
        
        switch streak {
        case 3:
            content.title = "\(prefix) 3 Day Streak! \(emoji)"
            content.body = type == .personal ?
                "You're building a solid habit. Keep it up!" :
                "3 days into your challenge. You're doing great!"
        case 5:
            content.title = "\(prefix) 5 Day Streak! 🌟"
            content.body = type == .personal ?
                "Consistency is key! You're doing amazing." :
                "Almost there! Keep pushing toward your challenge goal."
        case 7:
            content.title = "\(prefix) One Week Streak! \(emoji)"
            content.body = type == .personal ?
                "A full week of crushing your goals! Incredible!" :
                "One week in your challenge! Outstanding dedication!"
        case 14:
            content.title = "\(prefix) Two Week Streak! 💎"
            content.body = type == .personal ?
                "Two weeks strong! You're unstoppable!" :
                "Two weeks of challenge excellence! Keep going!"
        case 30:
            content.title = "\(prefix) 30 Day Streak! 👑"
            content.body = type == .personal ?
                "One month of dedication! You're a champion!" :
                "30 days of challenge commitment! Legendary!"
        default:
            if streak % 7 == 0 {
                content.title = "\(prefix) \(streak) Day Streak! 🎊"
                content.body = "\(streak / 7) weeks of pure dedication!"
            } else {
                return
            }
        }
        
        // Use different identifiers so both can show
        let identifier = type == .personal ? "personalStreakMilestone-\(streak)" : "challengeStreakMilestone-\(streak)"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error sending \(type) streak notification: \(error.localizedDescription)")
            } else {
                print("✅ \(type) streak notification sent: \(streak) days")
            }
        }
    }

    enum StreakType {
        case personal
        case challenge
    }
    
    // MARK: - Evening Reminder (if goal not met)
    func scheduleEveningReminderIfNeeded(currentSteps: Int, goalSteps: Int) {
        // Only send if goal not met
        guard currentSteps < goalSteps else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Evening Check-In 🌙"
        content.body = "You still have \(goalSteps - currentSteps) steps to reach your goal today!"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 20 // 8 PM
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "eveningReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling evening reminder: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Cancel All Notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("🔕 All notifications cancelled")
    }
    
    // MARK: - Cancel Specific Notification
    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
