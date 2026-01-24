//
//  ChallengesListView.swift
//  dailySteps
//
//  Created by Andrea on 1/23/26.
//

import SwiftUI
import CloudKit
// MARK: - Fetch Challenges

extension CloudKitManager {
    
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
    @StateObject private var cloudKitManager = CloudKitManager.shared
    @State private var challenges: [CKRecord] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
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
                                ForEach(challenges, id: \.recordID) { challenge in
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
                loadChallenges()
            }
            .refreshable {
                loadChallenges()
            }
        }
    }
    
    private func loadChallenges() {
        isLoading = true
        errorMessage = nil
        
        cloudKitManager.fetchAllChallenges { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let fetchedChallenges):
                    self.challenges = fetchedChallenges
                case .failure(let error):
                    self.errorMessage = "Failed to load challenges: \(error.localizedDescription)"
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
            // Icon
            Text(challengeEmoji)
                .font(.system(size: 40))
            
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
                    // Duration tag
                    if let duration = challenge["duration"] as? Int {
                        TagView(text: "\(duration) Days", color: .blue)
                    }
                    
                    // Steps tag
                    if let steps = challenge["targetSteps"] as? Int {
                        TagView(text: "\(formatSteps(steps)) steps per day", color: .gray)
                    }
                }
                .padding(.top, 4)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var challengeEmoji: String {
        let id = (challenge["challengeID"] as? String ?? "").lowercased()
        if id.contains("10k") || id.contains("daily") {
            return "🎯"
        } else if id.contains("weekend") {
            return "⚡️"
        } else if id.contains("marathon") {
            return "🏃"
        } else if id.contains("peak") {
            return "🔥"
        } else if id.contains("social") {
            return "👥"
        } else if id.contains("streak") {
            return "✨"
        } else {
            return "🎯"
        }
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
    @State private var isFlipped = false
    @State private var showTutorial = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Flip card
                ZStack {
                    // Back of card (Rules)
                    CardBackView(challenge: challenge)
                        .rotation3DEffect(
                            .degrees(isFlipped ? 0 : 180),
                            axis: (x: 0, y: 1, z: 0)
                        )
                        .opacity(isFlipped ? 1 : 0)
                    
                    // Front of card
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
                    // Tutorial hint
                    Group {
                        if showTutorial {
                            ZStack {
                                // Semi-transparent background
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
                
             
                // Enroll buttons (outside the card)
                VStack(spacing: 12) {
                    Button(action: {
                        print("Enrolling solo in: \(challenge["name"] as? String ?? "")")
                    }) {
                        HStack {
                            Image(systemName: "person.fill")
                            Text("Enroll Solo")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        print("Enrolling with friends in: \(challenge["name"] as? String ?? "")")
                    }) {
                        HStack {
                            Image(systemName: "person.2.fill")
                            Text("Enroll with Friends")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.pink)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .padding(.top)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Card Front View

struct CardFrontView: View {
    let challenge: CKRecord
    
    var body: some View {
        VStack(spacing: 0) {
            // Top colored section
            VStack(spacing: 16) {
                Text(challengeEmoji)
                    .font(.system(size: 80))
                
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
            .padding(.vertical, 40)
            .background(cardGradient)
            
            // Bottom white section
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("GOAL")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    if let steps = challenge["targetSteps"] as? Int {
                        Text("\(formatSteps(steps)) steps per day")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("ABOUT")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    Text(challenge["description"] as? String ?? "")
                        .font(.body)
                        .foregroundColor(.primary)
                }
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
        let id = (challenge["challengeID"] as? String ?? "").lowercased()
        if id.contains("10k") || id.contains("daily") {
            return LinearGradient(colors: [Color.red, Color.orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if id.contains("weekend") {
            return LinearGradient(colors: [Color.yellow, Color.orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            return LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    private var challengeEmoji: String {
        let id = (challenge["challengeID"] as? String ?? "").lowercased()
        if id.contains("10k") || id.contains("daily") {
            return "🎯"
        } else if id.contains("weekend") {
            return "⚡️"
        } else {
            return "🎯"
        }
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
        let id = (challenge["challengeID"] as? String ?? "").lowercased()
        if id.contains("10k") || id.contains("daily") {
            return LinearGradient(colors: [Color.red, Color.orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if id.contains("weekend") {
            return LinearGradient(colors: [Color.yellow, Color.orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            return LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
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
