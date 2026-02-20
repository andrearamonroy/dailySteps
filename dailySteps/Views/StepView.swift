//
//  StepView.swift
//  dailySteps
//
//  Created by Andrea Monroy on 12/30/25.
//
import SwiftUI
import CloudKit
import AVFoundation

struct StepView: View {
    @EnvironmentObject private var mainViewModel: MainViewModel
    @StateObject private var cloudKitManager = CloudKitManager.shared
    @State private var showSettings = false
    @State private var activeChallenge: CKRecord?
    @State private var enrollment: CKRecord?
    @State private var isLoadingChallenge = false
    @State private var lastFetchTime: Date?
    
    @EnvironmentObject var appState: AppState
    @State private var audioPlayer: AVAudioPlayer?
    private let cacheExpirationInterval: TimeInterval = 300 // 5 minutes
    
    var shouldRefreshChallenge: Bool {
        guard let lastFetch = lastFetchTime else { return true }
        return Date().timeIntervalSince(lastFetch) > cacheExpirationInterval
    }
    
    var challengeTargetSteps: Int? {
        activeChallenge?["targetSteps"] as? Int
    }

    
    @ObservedObject var themeManager = ThemeManager.shared
    
    
    ///congrats card
    @State private var showGoalReachedOverlay = false
    @State private var hasShownGoalCelebrationToday = false
    @AppStorage("lastGoalCelebrationDate") private var lastCelebrationDateStr: String = ""
    
    //failed banner
    @State private var showFailureBanner = false
    @State private var failureReason: ChallengeFailureReason = .missedDay
    @AppStorage("lastFailureBannerDate") private var lastFailureBannerDate: String = ""
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Day.date, ascending: true)],
            predicate: NSPredicate(format: "(date >= %@) AND (date <= %@)",
                                   Date().startOfMonth as CVarArg,
                                   Date().endOfMonth as CVarArg))
        private var days: FetchedResults<Day>
    
    @AppStorage("lastFeedbackPromptDate") private var lastFeedbackPromptDate: String = ""
    @State private var showFeedbackPrompt = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background color
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Date Header
                        Text(mainViewModel.todayDate, format: .dateTime.weekday().day().month().year())
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top)
                        
                        GreetingCardView()
                        
                        // Challenge Goal Banner (if active challenge exists)
                        if let challenge = activeChallenge,
                           let targetSteps = challengeTargetSteps,
                           let challengeName = challenge["name"] as? String {
                            ChallengeGoalBanner(
                                challengeName: challengeName,
                                targetSteps: targetSteps,
                                currentSteps: mainViewModel.healthManager.stepCount, challengeID: challenge["challengeID"] as? String ?? "" )
                        }
                        
                        // Today's Steps with Dual Goals
                        VStack(spacing: 16) {
                            // Main step count
                            Text("\(mainViewModel.healthManager.stepCount)")
                                .font(.system(size: 48, weight: .bold))
                            
                            Text("steps today")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Divider()
                                .padding(.horizontal, 40)
                            
                            // Goals section
                            if let targetSteps = challengeTargetSteps {
                                // Show both goals side by side
                                HStack(spacing: 0) {
                                    // Personal Goal
                                    GoalProgressView(
                                        title: "Personal Goal",
                                        goalSteps: Int(mainViewModel.stepGoal),
                                        currentSteps: mainViewModel.healthManager.stepCount,
                                        color: .green,
                                        isChallenge: false
                                    )
                                    
                                    Divider()
                                        .frame(height: 60)
                                    
                                    // Challenge Goal
                                    GoalProgressView(
                                        title: "Challenge Goal",
                                        goalSteps: targetSteps,
                                        currentSteps: mainViewModel.healthManager.stepCount,
                                        color: .blue,
                                        isChallenge: true
                                    )
                                }
                            } else {
                                // Only personal goal (no active challenge)
                                VStack(spacing: 16) {
                                    Text("Personal Goal")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text("\(Int(mainViewModel.stepGoal))")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    
                                    if mainViewModel.healthManager.stepCount >= mainViewModel.stepGoal {
                                        HStack(spacing: 6) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                            Text("Goal Reached")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.green)
                                        }
                                    } else {
                                        Text("\(Int(mainViewModel.stepGoal) - mainViewModel.healthManager.stepCount) steps to go")
                                            .font(.subheadline)
                                            .foregroundColor(.orange)
                                    }
                                    
                                    Divider()
                                        .padding(.horizontal, 40)
                                        .padding(.vertical, 4)
                                    
                                    VStack(spacing: 4) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "flame.fill")
                                                .font(.system(size: 16))
                                                .foregroundStyle(
                                                    LinearGradient(
                                                        colors: [.orange, .red],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                            
                                            StreakNumberView()
                                                .environment(\.managedObjectContext, viewContext)
                                                .environmentObject(mainViewModel)
                                        }
                                        
                                        Text("day streak")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        .padding(.horizontal)
                        
                        // Weekly Steps
                        WeeklyStepsView()
                        
                        // Active Challenge Section (moved to bottom)
                        // Active Challenge Section OR Enrollment Prompt
                        if isLoadingChallenge {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Active Challenge")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal)
                                
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                            .padding(.bottom)
                        } else if let challenge = activeChallenge, let enrollmentRecord = enrollment {
                            // Has active challenge - show challenge card
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Active Challenge")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal)
                                
                                ActiveChallengeCardView(
                                    challenge: challenge,
                                    enrollment: enrollmentRecord,
                                    currentSteps: mainViewModel.healthManager.stepCount
                                )
                            }
                            .padding(.bottom)
                        } else {
                            // No active challenge - show enrollment prompt
                            EnrollmentPromptView()
                                .padding(.bottom)
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: StepGoalSettingsView()
                        .environmentObject(mainViewModel)) {
                            Image(systemName: "gearshape")
                        }
                }
            }
            .refreshable {
                loadActiveChallenge(forceRefresh: true)
                mainViewModel.healthManager.refreshTodaySteps()
                
                //update progress after refresh
                mainViewModel.checkAndUpdateProgress(currentSteps: mainViewModel.healthManager.stepCount)
            }
        }
        
        
        
        .overlay(alignment: .top) {
            if showFailureBanner, let challenge = activeChallenge {
                ChallengeFailedBanner(
                    challengeName: challenge["name"] as? String ?? "Challenge",
                    challengeIconName: challenge.challengeIconName,
                    failureReason: failureReason,
                    onTryAgain: {
                        showFailureBanner = false
                        // Navigate to challenges list so they can re-enroll
                        appState.selectedTab = 2
                    },
                    onDismiss: {
                        showFailureBanner = false
                    }
                )
                .padding(.top, 8)
                .zIndex(998)
            }
        }
    
        // ADD challenge completed overlay
        .overlay {
            if appState.showChallengeCompletedOverlay {
                ChallengeCompletedOverlay(
                    challengeName: appState.completedChallengeName,
                    totalDays: appState.completedChallengeDays,
                    targetSteps: appState.completedChallengeSteps,
                    challengeIconName: appState.completedChallengeIconName,
                    isShowing: $appState.showChallengeCompletedOverlay
                ) {
                    // "View My Badge" tapped
                    appState.showBadgeSpotlight = true
                }
                .transition(.opacity)
                .zIndex(999)
            }
        }
        
        .overlay {
            if showFeedbackPrompt {
                FeedbackPromptView(isShowing: $showFeedbackPrompt)
                    .transition(.opacity)
                    .zIndex(1000)
            }
        }
        .fullScreenCover(isPresented: $appState.showBadgeSpotlight) {
            BadgeSpotlightView(
                challengeIconName: appState.completedChallengeIconName,
                challengeName: appState.completedChallengeName,
                isShowing: $appState.showBadgeSpotlight
            ) {
                // Navigate to badges tab
                appState.selectedTab = 3
                
            /*
                // Show feedback prompt after dismissing badge spotlight
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if mainViewModel.shouldShowFeedbackPrompt() {
                        withAnimation {
                            showFeedbackPrompt = true
                        }
                    }
                }
             */
            }
        }
        //1
        .overlay {
            if showGoalReachedOverlay, let challenge = activeChallenge {
                GoalReachedOverlay(
                    challengeName: challenge["name"] as? String ?? "Challenge",
                    targetSteps: challenge["targetSteps"] as? Int ?? Int(mainViewModel.stepGoal),
                    challengeIconName: challenge.challengeIconName,
                    isShowing: $showGoalReachedOverlay
                )
                .transition(.opacity)
                .zIndex(999)
                .onAppear {
                     try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                     try? AVAudioSession.sharedInstance().setActive(true)
                     playWinSound()
                 }
                 .onDisappear {
                     audioPlayer?.stop()
                     audioPlayer = nil
                 }
            }
        }
        
        
        .onAppear {
            mainViewModel.healthManager.refreshTodaySteps()
            
            //update progress with current steps
            mainViewModel.checkAndUpdateProgress(currentSteps: mainViewModel.healthManager.stepCount)
            
            // Schedule evening reminder if goal not met yet
              NotificationManager.shared.scheduleEveningReminderIfNeeded(
                  currentSteps: mainViewModel.healthManager.stepCount,
                  goalSteps: Int(mainViewModel.stepGoal)
              )
            checkGoalCelebration(steps: mainViewModel.healthManager.stepCount)
            
            // Only load challenge if cache expired or no data
            if shouldRefreshChallenge || (activeChallenge == nil && enrollment == nil) {
                loadActiveChallenge(forceRefresh: false)
            }
            
            
            if appState.dismissChallengeListView == true {
                loadActiveChallenge(forceRefresh: true)
                //reset
                //appState.dismissChallengeListView = false
            }
        }
        
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ChallengeEnded"))) { _ in
            // Force refresh when challenge ends
            loadActiveChallenge(forceRefresh: true)
        }
        
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ChallengeEnrolled"))) { _ in
            // Force refresh when user enrolls in a new challenge
            loadActiveChallenge(forceRefresh: true)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ChallengeEnded"))) { _ in
            // Force refresh when challenge ends
            loadActiveChallenge(forceRefresh: true)
        }
        
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowFeedbackPrompt"))) { _ in
            triggerFeedbackPromptIfNeeded()
        }
        .onChange(of: appState.dismissChallengeListView) { oldValue, newValue in
            loadActiveChallenge(forceRefresh: true)
            //reset to false
            //appState.dismissChallengeListView = false
        }
        

        
        .onChange(of: mainViewModel.healthManager.stepCount) { oldValue, newValue in
            if newValue > oldValue {
                mainViewModel.checkAndUpdateProgress(currentSteps: newValue)
                
                // Send encouraging notifications
                NotificationManager.shared.scheduleEncouragingNotification(
                    currentSteps: newValue,
                    goalSteps: Int(mainViewModel.stepGoal)
                )
                
                // Check personal goal
                if oldValue < mainViewModel.stepGoal && newValue >= mainViewModel.stepGoal {
                    
                    // Force a Core Data save immediately here
                    try? viewContext.save()
                    
                    NotificationManager.shared.sendGoalReachedNotification(type: .personal)
                    
                    // Send personal streak milestone
                    let personalStreak = StreakCalculator.calculate(
                        days: Array(days),
                        maxGraceDays: mainViewModel.graceDays
                    )
                    NotificationManager.shared.sendStreakMilestone(streak: personalStreak, type: .personal)
                }
                
                // Check challenge goal (if active)
                if let targetSteps = challengeTargetSteps,
                   oldValue < targetSteps && newValue >= targetSteps {
                    NotificationManager.shared.sendGoalReachedNotification(type: .challenge)
                    
                    // Send challenge streak milestone
                    if let enrollment = enrollment,
                       let challengeStreak = enrollment["currentStreak"] as? Int {
                        NotificationManager.shared.sendStreakMilestone(streak: challengeStreak, type: .challenge)
                    }
                }
            }
            
            checkGoalCelebration(steps: newValue)
        }
    }

    
    private func checkChallengeFailure(challenge: CKRecord, enrollment: CKRecord) {
        // Only show once per calendar day
        if let last = ISO8601DateFormatter().date(from: lastFailureBannerDate),
           Calendar.current.isDateInToday(last) { return }

        cloudKitManager.checkForChallengeFailure(
            challenge: challenge,
            enrollment: enrollment
        ) { reason in
            DispatchQueue.main.async {
                guard let reason else { return }
                self.failureReason = reason
                self.lastFailureBannerDate = ISO8601DateFormatter().string(from: Date())
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation { self.showFailureBanner = true }
                }
            }
        }
    }
      
    
    private func shouldShowFeedbackPrompt() -> Bool {
        // Don't show if already shown today
        if let last = ISO8601DateFormatter().date(from: lastFeedbackPromptDate),
           Calendar.current.isDateInToday(last) {
            return false
        }
        return mainViewModel.shouldShowFeedbackPrompt()
    }

    private func triggerFeedbackPromptIfNeeded() {
        guard shouldShowFeedbackPrompt() else { return }
        lastFeedbackPromptDate = ISO8601DateFormatter().string(from: Date())
        withAnimation {
            showFeedbackPrompt = true
        }
    }
    private func checkGoalCelebration(steps: Int) {
        let goal = activeChallenge?["targetSteps"] as? Int ?? Int(mainViewModel.stepGoal)
        guard steps >= goal else { return }
        guard !hasShownGoalCelebrationToday else { return }

        // Only once per calendar day
        if let last = ISO8601DateFormatter().date(from: lastCelebrationDateStr),
           Calendar.current.isDateInToday(last) { return }

        hasShownGoalCelebrationToday = true
        lastCelebrationDateStr = ISO8601DateFormatter().string(from: Date())

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            
    
            withAnimation { showGoalReachedOverlay = true }
            
            /*
            if mainViewModel.shouldShowFeedbackPrompt() {
                       DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                           withAnimation {
                               showFeedbackPrompt = true
                           }
                       }
                   }
             */
        }
    }
    
   private func playWinSound() {
         // Uses a system sound as fallback — replace "win" with your own .mp3/.wav asset name
         if let url = Bundle.main.url(forResource: "win", withExtension: "mp3") {
             audioPlayer = try? AVAudioPlayer(contentsOf: url)
             audioPlayer?.play()
         } else {
             // Fallback to system sound
             AudioServicesPlaySystemSound(1025) // "Fanfare" system sound
         }
     }


    private func incrementGoalCompletionCount() {
        let current = UserDefaults.standard.integer(forKey: "goalCompletionCount")
        UserDefaults.standard.set(current + 1, forKey: "goalCompletionCount")
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - challenge: <#challenge description#>
    ///   - enrollment: <#enrollment description#>
    func checkIfChallengeJustCompleted(challenge: CKRecord, enrollment: CKRecord) {
        // Don't fire if already completed
        if enrollment["completedAt"] as? Date != nil { return }

        let totalDays   = challenge["duration"] as? Int ?? 30
        let daysCompleted = enrollment["totalDaysCompleted"] as? Int ?? 0
        let targetSteps = challenge["targetSteps"] as? Int ?? 10000
        let todaySteps  = mainViewModel.healthManager.stepCount

        guard daysCompleted >= totalDays && todaySteps >= targetSteps else { return }

        cloudKitManager.markChallengeCompleted(enrollment: enrollment) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    appState.completedChallengeName     = challenge["name"] as? String ?? "Challenge"
                    appState.completedChallengeIconName = challenge.challengeIconName
                    appState.completedChallengeDays     = totalDays
                    appState.completedChallengeSteps    = targetSteps

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        withAnimation {
                            self.appState.showChallengeCompletedOverlay = true
                        }
                    }
                    
                case .failure(let error):
                    print("❌ Failed to mark complete: \(error.localizedDescription)")
                }
            }
        }
    }
     

   
    
    private func loadActiveChallenge(forceRefresh: Bool = false) {
        // Check cache first
        if !forceRefresh, let lastFetch = lastFetchTime {
            if Date().timeIntervalSince(lastFetch) < cacheExpirationInterval {
                print("✅ Using cached challenge data")
                return
            }
        }
        
        isLoadingChallenge = true
        
        cloudKitManager.fetchActiveEnrollment { result in
            DispatchQueue.main.async {
                isLoadingChallenge = false
                lastFetchTime = Date()
                
                switch result {
                case .success(let (challenge, enrollment)):
                    self.activeChallenge = challenge
                    self.enrollment = enrollment
                   
          
                    // ADD THESE TWO:
                    self.checkIfChallengeJustCompleted(challenge: challenge, enrollment: enrollment)
                    self.checkGoalCelebration(steps: self.mainViewModel.healthManager.stepCount)

                    self.checkChallengeFailure(challenge: challenge, enrollment: enrollment)
                    print("✅ Loaded active challenge: \(challenge["name"] as? String ?? "Unknown")")
                case .failure(let error):
                    print("ℹ️ No active challenge: \(error.localizedDescription)")
                    self.activeChallenge = nil
                    self.enrollment = nil
                }
            }
        }
    }
}

// MARK: - Challenge Goal Banner
struct ChallengeGoalBanner: View {
    let challengeName: String
    let targetSteps: Int
    let currentSteps: Int
    let challengeID: String
    
    var isCompleted: Bool {
        currentSteps >= targetSteps
    }
    
    var progress: Double {
        min(Double(currentSteps) / Double(targetSteps), 1.0)
    }
    
    var challengeIconName: String {
        let id = challengeID.lowercased()
        //test
        if id.contains("first-challenge"){ return "10kMonday" }
        
        if id.contains("10k-monday"){
            return "10kMonday"
        } else if id.contains("weekend-warrior") {
            return "weekendWarrior"
        } else if id.contains("freedom-friday") {
            return "freedomFriday"
        } else if id.contains("steady-sunday") {
            return "steadySunday"
        } else if id.contains("super-saturday") {
            return "superSaturday"
        } else if id.contains("thirsty-thursday") {
            return "thursday"
        } else if id.contains("turbo-tuesday") {
            return "turboTuesday"
        } else if id.contains("10k-everyday") {
            return "10kEveryday"
        }else if id.contains("7k-everyday") {
           return "7kEveryday"
       }
        else if id.contains("wellness-wednesday") {
           return "wellnesWed"
       }

        
        //change later to app's icon to default
        else {
            return "10k-monday"
        }


    }

    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Custom Icon
                Image(challengeIconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundColor(isCompleted ? .green : .blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's Challenge")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Text(challengeName)
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(formatSteps(targetSteps))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(isCompleted ? .green : .blue)
                    Text("step goal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // ... rest of banner
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isCompleted ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isCompleted ? Color.green.opacity(0.3) : Color.blue.opacity(0.3), lineWidth: 2)
        )
        .padding(.horizontal)
    }
    
    private func formatSteps(_ steps: Int) -> String {
        if steps >= 1000 {
            return "\(steps / 1000),\(String(format: "%03d", steps % 1000))"
        }
        return "\(steps)"
    }
}


// MARK: - Goal Progress View
struct GoalProgressView: View {
    let title: String
    let goalSteps: Int
    let currentSteps: Int
    let color: Color
    let isChallenge: Bool
    
    @EnvironmentObject var mainViewModel: MainViewModel
    @Environment(\.managedObjectContext) private var viewContext
    
    var isCompleted: Bool {
        currentSteps >= goalSteps
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Title with icon
            HStack(spacing: 4) {
                if isChallenge {
                    Image(systemName: "trophy.fill")
                        .font(.caption2)
                        .foregroundColor(color)
                }
                Text(title)
                    .font(.caption)
                    .foregroundColor(isChallenge ? color : .secondary)
            }
            
            // Goal number
            Text("\(formatSteps(goalSteps))")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(isChallenge ? color : .primary)
            
            // Status
            if isCompleted {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text("Reached")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            } else {
                Text("\(goalSteps - currentSteps) to go")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            // Add streak ONLY for personal goal
            if !isChallenge {
                Divider()
                    .padding(.horizontal, 20)
                    .padding(.vertical, 4)
                
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        StreakNumberView()
                            .environment(\.managedObjectContext, viewContext)
                            .environmentObject(mainViewModel)
                    }
                    
                    Text("day streak")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func formatSteps(_ steps: Int) -> String {
        if steps >= 1000 {
            return "\(steps / 1000),\(String(format: "%03d", steps % 1000))"
        }
        return "\(steps)"
    }
}

// MARK: - Streak Number View
struct StreakNumberView: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Day.date, ascending: true)],
        predicate: NSPredicate(format: "(date >= %@) AND (date <= %@)",
                               Date().startOfMonth as CVarArg,
                               Date().endOfMonth as CVarArg))
    private var days: FetchedResults<Day>
    
    var body: some View {
        let streakValue = StreakCalculator.calculate(
            days: Array(days),
            maxGraceDays: mainViewModel.graceDays
        )
        
        Text("\(streakValue)")
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundStyle(
                streakValue > 0
                ? LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
                : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing)
            )
    }
}


// MARK: - Active Challenge Card
struct ActiveChallengeCardView: View {
    let challenge: CKRecord
    let enrollment: CKRecord
    let currentSteps: Int
    
    var challengeName: String {
        challenge["name"] as? String ?? "Challenge"
    }
    
    var challengeDescription: String {
        challenge["description"] as? String ?? ""
    }
    
    var duration: Int {
        challenge["duration"] as? Int ?? 30
    }
    
    var targetSteps: Int {
        challenge["targetSteps"] as? Int ?? 10000
    }
    
    var currentStreak: Int {
        enrollment["currentStreak"] as? Int ?? 0
    }
    
    var startDate: Date {
        enrollment["startDate"] as? Date ?? Date()
    }
    
    var expectedEndDate: Date {
        Calendar.current.date(byAdding: .day, value: duration, to: startDate) ?? Date()
    }
    
    var daysCompleted: Int {
        enrollment["totalDaysCompleted"] as? Int ?? 0
    }
    
    var daysRemaining: Int {
        max(duration - daysCompleted, 0)
    }
    
    var progressPercentage: Int {
        guard duration > 0 else { return 0 }
        return Int((Double(daysCompleted) / Double(duration)) * 100)
    }
    
    var todayProgress: Int {
        guard targetSteps > 0 else { return 0 }
        return min(Int((Double(currentSteps) / Double(targetSteps)) * 100), 100)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top section with emoji and title
            HStack(alignment: .top, spacing: 12) {
                Image(challenge.challengeIconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(challengeName)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text(challengeDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            .padding()
            
            // Tags row
            HStack(spacing: 8) {
                TagLabel(text: "\(duration) days", color: .gray)
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
            
            Divider()
                .padding(.horizontal)
            
            // Stats grid
            HStack(spacing: 0) {
                StatBox(
                    icon: "flame.fill",
                    iconColor: .orange,
                    title: "Streak",
                    value: "\(currentStreak) days",
                    backgroundColor: Color.orange.opacity(0.1)
                )
                
                Divider()
                    .frame(height: 60)
                
                StatBox(
                    icon: "clock.fill",
                    iconColor: .purple,
                    title: "Remaining",
                    value: "\(daysRemaining) days",
                    backgroundColor: Color.purple.opacity(0.1)
                )
                
                Divider()
                    .frame(height: 60)
                
                StatBox(
                    icon: "chart.bar.fill",
                    iconColor: .green,
                    title: "Progress",
                    value: "\(progressPercentage)%",
                    backgroundColor: Color.green.opacity(0.1)
                )
            }
            .padding(.vertical, 16)
            
            Divider()
                .padding(.horizontal)
            
            // Today's Challenge Progress
            VStack(spacing: 12) {
                HStack {
                    Text("Today's Goal")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(currentSteps) / \(formatSteps(targetSteps))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: currentSteps >= targetSteps ? [Color.green, Color.green] : [Color.blue, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(todayProgress) / 100, height: 8)
                    }
                }
                .frame(height: 8)
                
                if currentSteps >= targetSteps {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Today's goal completed! 🎉")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                } else {
                    Text("\(targetSteps - currentSteps) steps remaining today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.blue.opacity(0.05))
            
            Divider()
                .padding(.horizontal)
            
            // Dates section
            VStack(spacing: 8) {
                HStack {
                    Text("Started:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatDate(startDate))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Expected end:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatDate(expectedEndDate))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            .padding()
            
            // Progress text
            Text("\(daysCompleted) / \(duration) days completed")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.bottom)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func formatSteps(_ steps: Int) -> String {
        if steps >= 1000 {
            return "\(steps / 1000),\(String(format: "%03d", steps % 1000))"
        }
        return "\(steps)"
    }
}

// MARK: - Stat Box Component
struct StatBox: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let backgroundColor: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Tag Label Component
struct TagLabel: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(6)
    }
}

// MARK: - Empty State View
struct EmptyActiveChallengeView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No Active Challenges")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Start your journey by enrolling in a challenge!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
    }
}

#Preview {
    StepView()
        .environmentObject(MainViewModel())
}
// MARK: - Enrollment Prompt View
struct EnrollmentPromptView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Join a Challenge")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            NavigationLink(destination: ChallengesListView()) {
                VStack(spacing: 16) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.4, green: 0.7, blue: 1.0),
                                        Color(red: 0.7, green: 0.5, blue: 1.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Ready for a Challenge?")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text("Push yourself further and track your progress with daily step challenges")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Call to action button
                    HStack {
                        Text("Browse Challenges")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Image(systemName: "arrow.right")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.4, green: 0.7, blue: 1.0),
                                Color(red: 0.7, green: 0.5, blue: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .padding(32)
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.7, blue: 1.0).opacity(0.3),
                                    Color(red: 0.7, green: 0.5, blue: 1.0).opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal)
        }
    }
}
