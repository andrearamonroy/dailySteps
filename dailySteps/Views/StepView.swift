//
//  StepView.swift
//  dailySteps
//
//  Created by Andrea Monroy on 12/30/25.
//
import SwiftUI
import CloudKit
struct StepView: View {
    @EnvironmentObject private var mainViewModel: MainViewModel
    @StateObject private var cloudKitManager = CloudKitManager.shared
    @State private var showSettings = false
    @State private var activeChallenge: CKRecord?
    @State private var enrollment: CKRecord?
    @State private var isLoadingChallenge = false
    @State private var lastFetchTime: Date?
    
    private let cacheExpirationInterval: TimeInterval = 300 // 5 minutes
    
    var shouldRefreshChallenge: Bool {
        guard let lastFetch = lastFetchTime else { return true }
        return Date().timeIntervalSince(lastFetch) > cacheExpirationInterval
    }
    
    var challengeTargetSteps: Int? {
        activeChallenge?["targetSteps"] as? Int
    }
    
    @AppStorage("backgroundColor", store: UserDefaults(suiteName: "group.com.andrearamonroy.dailySteps"))
      private var backgroundColorString: String = BackgroundColor.sage.rawValue
      
      var backgroundColor: Color {
          BackgroundColor(rawValue: backgroundColorString)?.color ?? BackgroundColor.sage.color
      }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background color
                backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Date Header
                        Text(mainViewModel.todayDate, format: .dateTime.weekday().day().month().year())
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top)
                        
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
                                VStack(spacing: 8) {
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
                        if isLoadingChallenge || activeChallenge != nil || enrollment != nil {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Active Challenge")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal)
                                
                                if isLoadingChallenge {
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                } else if let challenge = activeChallenge, let enrollmentRecord = enrollment {
                                    ActiveChallengeCardView(
                                        challenge: challenge,
                                        enrollment: enrollmentRecord,
                                        currentSteps: mainViewModel.healthManager.stepCount
                                    )
                                } else {
                                    EmptyActiveChallengeView()
                                }
                            }
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
            }
        }
        .onAppear {
            mainViewModel.healthManager.refreshTodaySteps()
            
            // Only load challenge if cache expired or no data
            if shouldRefreshChallenge || (activeChallenge == nil && enrollment == nil) {
                loadActiveChallenge(forceRefresh: false)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ChallengeEnrolled"))) { _ in
            // Force refresh when user enrolls in a new challenge
            loadActiveChallenge(forceRefresh: true)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ChallengeEnded"))) { _ in
            // Force refresh when challenge ends
            loadActiveChallenge(forceRefresh: true)
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
            return "challenge-10k-daily"
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
