
import SwiftUI
import Foundation

struct BadgesView: View {
    @State private var completedBadges: [EnrollmentWithChallenge] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    ProgressView("Loading badges...")
                } else if completedBadges.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "trophy")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No Badges Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Complete challenges to earn badges!")
                            .foregroundColor(.secondary)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                            ForEach(completedBadges, id: \.enrollmentID) { badge in
                                BadgeCard(badge: badge)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Badges")
            .onAppear {
                loadBadges()
            }
        }
    }
    
    private func loadBadges() {
        isLoading = true
        
        CloudKitManager.shared.fetchAllEnrollmentsWithChallengeDetails { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let enrollments):
                    // Filter only completed challenges
                    self.completedBadges = enrollments
                        .filter { $0.completedAt != nil }
                        .sorted { $0.completedAt! > $1.completedAt! } // Newest first
                    
                    print("✅ Loaded \(self.completedBadges.count) badges")
                    
                case .failure(let error):
                    print("❌ Error loading badges: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct BadgeCard: View {
    let badge: EnrollmentWithChallenge
    
    var body: some View {
        VStack(spacing: 12) {
            // This loads the image from Assets using the icon name!
            Image(badge.challengeIconName)
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
            
            Text(badge.challengeName)
                .font(.headline)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Text("\(badge.duration) days")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let completedDate = badge.completedAt {
                Text("Completed \(formatDate(completedDate))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 4) {
                Image(systemName: "figure.walk")
                    .font(.caption2)
                Text("\(formatSteps(badge.targetSteps))/day")
                    .font(.caption2)
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatSteps(_ steps: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: steps)) ?? "\(steps)"
    }
}
