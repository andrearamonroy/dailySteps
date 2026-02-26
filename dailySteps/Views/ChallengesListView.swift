//
//  ChallengesListView.swift
//  dailySteps
//
//  Created by Andrea on 1/23/26.
//

import SwiftUI
import CloudKit

// MARK: - CloudKit Manager Extension for Account Status
extension CKRecord {
    var challengeCardGradient: LinearGradient {
        let gradientID = (self["cardGradient"] as? String ?? "").lowercased()
        
        switch gradientID {
        case "redorange":
            return LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "yelloworange":
            return LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "greenteal":
            return LinearGradient(colors: [.green, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "purplepink":
            return LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "pinkred":
            return LinearGradient(colors: [.pink, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}
extension CloudKitManager {
    
    /// Checks if the user is logged into their iCloud account
    /// - Parameter completion: Callback with account status result
    func checkAccountStatus(completion: @escaping (Result<CKAccountStatus, Error>) -> Void) {
        CKContainer.default().accountStatus { status, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(status))
            }
        }
    }
    
    /// Fetches all challenges from the public database
    /// - Parameter completion: Callback with array of challenge records or error
    func fetchAllChallenges(completion: @escaping (Result<[CKRecord], Error>) -> Void) {
        let predicate = NSPredicate(value: true) // Fetches all records
        let query = CKQuery(recordType: "Challenge", predicate: predicate)
        
        // Optional: Sort by name
        query.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        publicDatabase.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                print("❌ Error fetching challenges: \(error.localizedDescription)")
                completion(.failure(error))
            } else if let records = records {
                print("✅ Fetched \(records.count) challenges")
                completion(.success(records))
            }
        }
    }
}

// MARK: - SwiftUI View

import SwiftUI

struct ChallengesListView: View {
    @State private var sortNewestFirst = true
    @StateObject private var cloudKitManager = CloudKitManager.shared
    @State private var challenges: [CKRecord] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @EnvironmentObject private var mainViewModel: MainViewModel
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var themeManager = ThemeManager.shared

    
    var sortedChallenges: [CKRecord] {
        challenges.sorted {
            let date0 = $0.creationDate ?? Date.distantPast
            let date1 = $1.creationDate ?? Date.distantPast
            return sortNewestFirst ? date0 > date1 : date0 < date1
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.backgroundColor
                      .ignoresSafeArea()
                
                if isLoading {
                    ProgressView("Loading challenges...")
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text(error)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            loadChallenges()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if challenges.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No challenges available")
                            .font(.headline)
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            
                            // Header
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "trophy.fill")
                                        .font(.title2)
                                    Text("Challenges")
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                    
                                    Spacer()
                                    
                                    // Sort toggle button
                                    Button {
                                        withAnimation {
                                            sortNewestFirst.toggle()
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: sortNewestFirst ? "arrow.down" : "arrow.up")
                                                .font(.caption)
                                            Text(sortNewestFirst ? "Newest" : "Oldest")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(8)
                                    }
                                }
                                Text("Choose a challenge and start your journey")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                            .padding(.bottom, 16)

                            // Challenge cards
                            VStack(spacing: 12) {
                                ForEach(sortedChallenges, id: \.recordID) { challenge in
                                    NavigationLink(destination: ChallengeDetailView(challenge: challenge)) {
                                        ChallengeCardView(challenge: challenge)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("")
                }
            }
            .onAppear {
                if challenges.isEmpty {
                      loadChallenges() // Uses cache
                  }
    
            }
            .refreshable {
                loadChallenges(forceRefresh: true) // Bypasses cache
            }
            .onChange(of: appState.dismissChallengeListView) { oldValue, newValue in
                
                if newValue {
                  
                        dismiss()
                    
                }
            }
        }
    }
    
    private func loadChallenges(forceRefresh: Bool = false) {
        isLoading = true
        errorMessage = nil
        
        cloudKitManager.fetchAllChallenges { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let fetchedChallenges):
                    self.challenges = fetchedChallenges
                case .failure(let error):
                    if let ckError = error as? CKError {
                        switch ckError.code {
                        case .unknownItem:
                            self.errorMessage = "Challenge record type not found in CloudKit. Schema may not be deployed to production."
                        case .notAuthenticated:
                            self.errorMessage = "Please sign in to iCloud to load challenges."
                        default:
                            self.errorMessage = "Failed to load challenges: \(ckError.localizedDescription)"
                        }
                    } else {
                        self.errorMessage = "Failed to load challenges: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
  
}

// MARK: - Challenge Card View
struct ChallengeCardView: View {
    let challenge: CKRecord
    
    var body: some View {
        HStack(spacing: 16) {
            // Custom Icon
            ChallengeIconView(challenge: challenge)
                .frame(width: 80, height: 80)
               // Only works if "Template Image"
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(challenge["name"] as? String ?? "Unknown Challenge")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(challenge["description"] as? String ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // Tags
                HStack(spacing: 8) {
                    if let duration = challenge["duration"] as? Int {
                        TagView(text: "\(duration) Days", color: .blue)
                    }
                    
                    if let steps = challenge["targetSteps"] as? Int {
                        TagView(text: "\(formatSteps(steps)) steps per day", color: .gray)
                    }
                }
                .padding(.top, 4)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func formatSteps(_ steps: Int) -> String {
        if steps >= 1000 {
            return "\(steps / 1000),\(String(format: "%03d", steps % 1000))"
        }
        return "\(steps)"
    }
}

// MARK: - Tag View

struct TagView: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(color == .blue ? .blue : .secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color == .blue ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
            .cornerRadius(6)
    }
}

// MARK: - Challenge Detail View
struct ChallengeDetailView: View {
    let challenge: CKRecord
    @Environment(\.dismiss) var dismiss
    @StateObject private var cloudKitManager = CloudKitManager.shared
    @State private var isFlipped = false
    @State private var showTutorial = true
    @State private var isEnrolling = false
    @State private var hasActiveChallenge = false
    @State private var activeChallengeName: String?
    @State private var showEnrolledMessage = false
    @State private var showReplaceAlert = false
    @State private var showDayRestrictionAlert = false
    @State private var showAppleAccountAlert = false
    @State private var invalidDayMessage = ""
    @EnvironmentObject var appState: AppState
    
    // Check if this challenge has day restrictions
    var hasWeekdayRestriction: Bool {
        guard let challengeID = challenge["challengeID"] as? String else { return false }
        return challengeID.lowercased().contains("monday") ||
               challengeID.lowercased().contains("tuesday") ||
               challengeID.lowercased().contains("wednesday") ||
               challengeID.lowercased().contains("thursday") ||
               challengeID.lowercased().contains("friday") ||
               challengeID.lowercased().contains("saturday") ||
               challengeID.lowercased().contains("sunday") ||
               challengeID.lowercased().contains("weekend")
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 24) {
                    // Flip card
                    ZStack {
                        CardBackView(challenge: challenge)
                            .rotation3DEffect(
                                .degrees(isFlipped ? 0 : 180),
                                axis: (x: 0, y: 1, z: 0)
                            )
                            .opacity(isFlipped ? 1 : 0)
                        
                        CardFrontView(challenge: challenge)
                            .rotation3DEffect(
                                .degrees(isFlipped ? 180 : 0),
                                axis: (x: 0, y: 1, z: 0)
                            )
                            .opacity(isFlipped ? 0 : 1)
                    }
                    .frame(height: 500)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            isFlipped.toggle()
                            showTutorial = false
                        }
                    }
                    .overlay(
                        Group {
                            if showTutorial {
                                ZStack {
                                    Color.black.opacity(0.4)
                                        .ignoresSafeArea()
                                    
                                    VStack(spacing: 16) {
                                        Text("👆")
                                            .font(.system(size: 50))
                                            .scaleEffect(showTutorial ? 1.2 : 1.0)
                                            .animation(
                                                Animation.easeInOut(duration: 0.8)
                                                    .repeatForever(autoreverses: true),
                                                value: showTutorial
                                            )
                                        
                                        Text("Tap to flip")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 24)
                                            .padding(.vertical, 12)
                                            .background(
                                                Capsule()
                                                    .fill(Color.blue)
                                                    .shadow(color: Color.blue.opacity(0.5), radius: 10, x: 0, y: 5)
                                            )
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.white)
                                            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                                    )
                                    .padding(40)
                                }
                                .transition(.opacity)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        showTutorial = false
                                    }
                                }
                            }
                        }
                    )
                    
                    // Enroll button
                    VStack(spacing: 12) {
                        Button(action: {
                            attemptEnrollment()
                        }) {
                            HStack {
                                if isEnrolling {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "person.fill")
                                    //later say enroll solo whent hey can enroll with friends but not now
                                    Text("Enroll")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isEnrolling)
                        
                        if hasActiveChallenge, let name = activeChallengeName {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.orange)
                                Text("Currently enrolled in: \(name)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .padding(.top)
            }
            
            // Success message banner at top
            if showEnrolledMessage {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                        
                        Text("Successfully Enrolled!")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.green)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkForActiveChallenge()
        }
        .alert("Replace Current Challenge?", isPresented: $showReplaceAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Replace", role: .destructive) {
                replaceChallenge()
            }
        } message: {
            if let name = activeChallengeName {
                Text("You're currently enrolled in '\(name)'. Do you want to end it and start this new challenge?")
            }
        }
        .alert("Cannot Enroll", isPresented: $showDayRestrictionAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(invalidDayMessage)
        }
        .alert("Apple Account Required", isPresented: $showAppleAccountAlert) {
            Button("Open Settings", role: .none) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To enroll in a challenge, please log into your Apple account in Settings. This is required to save your progress to iCloud.")
        }
    }
    
    private func checkForActiveChallenge() {
        cloudKitManager.fetchActiveEnrollment { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let (challenge, _)):
                    self.hasActiveChallenge = true
                    self.activeChallengeName = challenge["name"] as? String
                case .failure:
                    self.hasActiveChallenge = false
                    self.activeChallengeName = nil
                }
            }
        }
    }
    
    private func attemptEnrollment() {
        // First, check if user is logged into iCloud
        cloudKitManager.checkAccountStatus { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let status):
                    switch status {
                    case .available:
                        // User is logged in, proceed with enrollment checks
                        proceedWithEnrollmentChecks()
                        
                    case .noAccount:
                        // User is not logged into iCloud
                        showAppleAccountAlert = true
                        
                    case .restricted:
                        // Account is restricted (parental controls, etc.)
                        invalidDayMessage = "Your Apple account has restrictions that prevent enrollment. Please check your device settings."
                        showDayRestrictionAlert = true
                        
                    case .couldNotDetermine:
                        // Could not determine account status
                        invalidDayMessage = "Unable to verify your Apple account status. Please check your internet connection and try again."
                        showDayRestrictionAlert = true
                        
                    case .temporarilyUnavailable:
                        // iCloud is temporarily unavailable
                        invalidDayMessage = "iCloud is temporarily unavailable. Please try again in a few moments."
                        showDayRestrictionAlert = true
                        
                    @unknown default:
                        // Future cases
                        invalidDayMessage = "Unable to verify your Apple account. Please try again."
                        showDayRestrictionAlert = true
                    }
                    
                case .failure(let error):
                    // Error checking account status
                    invalidDayMessage = "Error verifying Apple account: \(error.localizedDescription)"
                    showDayRestrictionAlert = true
                }
            }
        }
    }
    
    private func proceedWithEnrollmentChecks() {
        // Check if challenge has weekday restrictions
        if !isValidDayForEnrollment() {
            showDayRestrictionAlert = true
            return
        }
        
        // Check if user has active challenge
        if hasActiveChallenge {
            showReplaceAlert = true
        } else {
            enrollSolo()
        }
    }
    
    private func isValidDayForEnrollment() -> Bool {
        guard let challengeID = challenge["challengeID"] as? String else { return true }
        
        let today = Calendar.current.component(.weekday, from: Date())
        let challengeIDLower = challengeID.lowercased()
        
        // Check for specific day restrictions
        if challengeIDLower.contains("monday") {
            if today != 2 { // Monday is 2 in Calendar.current
                invalidDayMessage = "This challenge can only be started on Mondays."
                return false
            }
        } else if challengeIDLower.contains("tuesday") {
            if today != 3 {
                invalidDayMessage = "This challenge can only be started on Tuesdays."
                return false
            }
        } else if challengeIDLower.contains("wednesday") {
            if today != 4 {
                invalidDayMessage = "This challenge can only be started on Wednesdays."
                return false
            }
        } else if challengeIDLower.contains("thursday") {
            if today != 5 {
                invalidDayMessage = "This challenge can only be started on Thursdays."
                return false
            }
        } else if challengeIDLower.contains("friday") {
            if today != 6 {
                invalidDayMessage = "This challenge can only be started on Fridays."
                return false
            }
        } else if challengeIDLower.contains("saturday") {
            if today != 7 {
                invalidDayMessage = "This challenge can only be started on Saturdays."
                return false
            }
        } else if challengeIDLower.contains("sunday") {
            if today != 1 {
                invalidDayMessage = "This challenge can only be started on Sundays."
                return false
            }
        } else if challengeIDLower.contains("weekend") {
            if today != 7 && today != 1 { // Saturday or Sunday
                invalidDayMessage = "This challenge can only be started on weekends (Saturday or Sunday)."
                return false
            }
        }
        
        return true
    }
    
    private func replaceChallenge() {
        isEnrolling = true
        
        // First, end the current challenge
        cloudKitManager.fetchActiveEnrollment { [self] result in
            switch result {
            case .success(let (_, enrollment)):
                cloudKitManager.endChallenge(enrollment: enrollment) { endResult in
                    switch endResult {
                    case .success:
                        // Now enroll in the new challenge
                        self.enrollSolo()
                    case .failure(let error):
                        DispatchQueue.main.async {
                            self.isEnrolling = false
                            print("❌ Error ending previous challenge: \(error.localizedDescription)")
                        }
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.isEnrolling = false
                    print("❌ Error fetching active challenge: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func enrollSolo() {
        isEnrolling = true
        
        cloudKitManager.enrollInChallenge(
            challenge: challenge,
            enrollmentType: "solo",
            groupID: nil
        ) { result in
            DispatchQueue.main.async {
                isEnrolling = false
                
                switch result {
                case .success:
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        showEnrolledMessage = true
                    }
                 
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        
                        appState.dismissChallengeListView = true
                        dismiss()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            appState.shouldNavigateToStepView = true
                        }
                    
                    }
     
                    
                case .failure(let error):
                    print("❌ Error enrolling: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Card Front View
struct CardFrontView: View {
    let challenge: CKRecord
    
    var body: some View {
        VStack(spacing: 0) {
            // Top colored section
            VStack(spacing: 16) {
                // Custom Icon
                ChallengeIconView(challenge: challenge)
                  
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                
                
                Text(challenge["name"] as? String ?? "Challenge")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                if let duration = challenge["duration"] as? Int {
                    Text("\(duration) DAYS")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(cardGradient)
            
            // ... rest of the card
            
            VStack(spacing: 12) {
                
                Text("\(challenge["description"] as? String ?? "")")
                    .font(.caption)
                    .padding()
                
                HStack(spacing: 40) {
                    VStack(spacing: 4) {
                        Text("🎯")
                            .font(.system(size: 32))
                        Text("\(formatSteps(challenge["targetSteps"] as? Int ?? 0))")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("steps/day")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 4) {
                        Text("📅")
                            .font(.system(size: 32))
                        Text("\(challenge["duration"] as? Int ?? 0)")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("days")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(Color.white)
        }
        .frame(maxWidth: .infinity)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
        .padding(.horizontal)
    }
    
    private var cardGradient: LinearGradient {
        challenge.challengeCardGradient
    }
    
    private func formatSteps(_ steps: Int) -> String {
        if steps >= 1000 {
            return "\(steps / 1000),\(String(format: "%03d", steps % 1000))"
        }
        return "\(steps)"
    }
}
// MARK: - Card Back View

struct CardBackView: View {
    let challenge: CKRecord
    
    var body: some View {
        VStack(spacing: 0) {
            // Top colored section with "RULES"
            VStack(spacing: 16) {
                Text("📋")
                    .font(.system(size: 60))
                
                Text("RULES")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .background(cardGradient)
            
            // Bottom white section with rules
            VStack(alignment: .leading, spacing: 16) {
                RuleRow(number: 1, text: "Achieve \(formatSteps(challenge["targetSteps"] as? Int ?? 0)) steps each day for \(challenge["duration"] as? Int ?? 0) consecutive days")
                
                RuleRow(number: 2, text: "Steps must be recorded on the same device")
                
                RuleRow(number: 3, text: "Challenge resets if you miss a day")
                
                RuleRow(number: 4, text: "Complete by midnight each day in your timezone")
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
        }
        .frame(maxWidth: .infinity)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
        .padding(.horizontal)
       
    }
    
    private var cardGradient: LinearGradient {
        challenge.challengeCardGradient
    }
    
    private func formatSteps(_ steps: Int) -> String {
        if steps >= 1000 {
            return "\(steps / 1000),\(String(format: "%03d", steps % 1000))"
        }
        return "\(steps)"
    }
}
// MARK: - Rule Row

struct RuleRow: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Color.blue)
                .clipShape(Circle())
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    ChallengesListView()
}
