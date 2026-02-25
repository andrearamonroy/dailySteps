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
        
        // If goal already met, no point in motivating further
           guard currentSteps < goalSteps else {
               UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["encouragingMessage"])
               return
           }
        
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
            content.body = "You've got \(goalSteps - currentSteps) steps to go. Keep going!"
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
    // MARK: - Evening Reminder (if goal not met)
    func scheduleEveningReminderIfNeeded(currentSteps: Int, goalSteps: Int, challengeSteps: Int? = nil) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["eveningReminder"])
        
        let personalGoalMet = currentSteps >= goalSteps
        let challengeGoalMet = challengeSteps.map { currentSteps >= $0 } ?? false
        let eitherGoalMet = personalGoalMet || challengeGoalMet

        let content = UNMutableNotificationContent()
        content.sound = .default

        let motivationalQuotes = [
            "Hard work today is tomorrow's reward. Rest well! 🌟",
            "You showed up and gave it your all. 💪",
            "Every step you took today is an investment in a healthier you. 🏆",
            "Discipline beats motivation every time — and you proved it today. 🔥",
            "Your body moved, your mind grew stronger. See you tomorrow! ✨",
            "Rest is part of the journey. You earned it today. 🌙",
            "One day at a time, one step at a time. You crushed it. 🎯"
        ]

        let randomQuote = motivationalQuotes.randomElement() ?? motivationalQuotes[0]

        if eitherGoalMet {
            if personalGoalMet && challengeGoalMet {
                content.title = "Double Goal Crusher! 🏆🔥"
                content.body = "You hit BOTH your personal and challenge goals today. \(randomQuote)"
            } else if challengeGoalMet {
                content.title = "Challenge Goal Conquered! 🏆"
                content.body = "You smashed today's challenge target. \(randomQuote)"
            } else {
                content.title = "Personal Goal Done! 🎉"
                content.body = "You hit your step goal today. \(randomQuote)"
            }
        } else {
            let stepsLeft = goalSteps - currentSteps
            content.title = "Evening Check-In 🌙"
            content.body = "You're \(stepsLeft) steps away from your goal. One last push — you've got this!"
        }

        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "eveningReminder", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling evening reminder: \(error.localizedDescription)")
            } else {
                print("✅ Evening reminder scheduled (goal met: \(eitherGoalMet))")
            }
        }
    }
    
    // MARK: - Schedule Daily Encouragement Messages
    func scheduleDailyEncouragementMessages() {
        // Remove any existing encouragement notifications
        let identifiers = (0..<10).map { "encouragement-\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        
        let messages: [(title: String, body: String)] = [
            ("Every Step Counts! 👟", "Keep moving — small steps lead to big results."),
            ("You've Got This! 💪", "Momentum builds one step at a time. Keep going!"),
            ("Stay the Course! 🌟", "Consistency is your superpower. Don't stop now."),
            ("Move Your Body! 🚶", "A little movement goes a long way. You've got this."),
            ("Keep It Up! 🔥", "Progress is progress, no matter the pace."),
            ("One Step at a Time! 🎯", "Don't think about the finish line — just the next step."),
            ("Make It Count! ✨", "Every walk, every step — it all adds up."),
            ("You're Doing Great! 🌈", "Be proud of yourself for showing up today."),
            ("Stay Active! 🏃", "Your future self will thank you for moving today."),
            ("Keep Moving Forward! 🚀", "Even slow progress is still progress. Keep at it!")
        ]
        
        // Spread messages across the day from 8 AM to 8 PM (~every 1.5 hours)
        let startHour = 8
        let intervalMinutes = 90
        
        for (index, message) in messages.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = message.title
            content.body = message.body
            content.sound = .default
            
            var dateComponents = DateComponents()
            let totalMinutes = startHour * 60 + index * intervalMinutes
            dateComponents.hour = totalMinutes / 60
            dateComponents.minute = totalMinutes % 60
            
            // Only schedule within reasonable hours (before 9 PM)
            guard (dateComponents.hour ?? 0) < 21 else { break }
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: "encouragement-\(index)", content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ Error scheduling encouragement message \(index): \(error.localizedDescription)")
                } else {
                    print("✅ Encouragement message \(index) scheduled at \(dateComponents.hour ?? 0):\(String(format: "%02d", dateComponents.minute ?? 0))")
                }
            }
        }
    }
    
    // MARK: - Cancel Daily Encouragement Messages
    func cancelDailyEncouragementMessages() {
        let identifiers = (0..<10).map { "encouragement-\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        print("🔕 Daily encouragement messages cancelled")
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
