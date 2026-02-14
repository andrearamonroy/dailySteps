import SwiftUI
import Foundation

struct BadgesView: View {
    @EnvironmentObject var appState: AppState
    @State private var completedBadges: [EnrollmentWithChallenge] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    ProgressView("Loading badges...")
                } else if completedBadges.isEmpty {
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.45, green: 0.55, blue: 1.0).opacity(0.15),
                                            Color(red: 0.75, green: 0.45, blue: 1.0).opacity(0.15)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 110, height: 110)
                            Image(systemName: "rosette")
                                .font(.system(size: 48))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.45, green: 0.55, blue: 1.0),
                                            Color(red: 0.75, green: 0.45, blue: 1.0)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        VStack(spacing: 8) {
                            Text("No Badges Yet")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(Color(.label))
                            Text("Enroll in a challenge and\nearn your first badge!")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        Button(action: {
                            appState.selectedTab = 1 // Navigate to challenges tab
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Browse Challenges")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.45, green: 0.55, blue: 1.0),
                                        Color(red: 0.75, green: 0.45, blue: 1.0)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(
                                color: Color(red: 0.55, green: 0.45, blue: 1.0).opacity(0.35),
                                radius: 10, x: 0, y: 4
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(32)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Header stats
                            HStack(spacing: 20) {
                                StatBadge(
                                    icon: "trophy.fill",
                                    value: "\(completedBadges.count)",
                                    label: "Badges",
                                    color: .orange
                                )
                                
                                StatBadge(
                                    icon: "flame.fill",
                                    value: "\(totalDaysCompleted)",
                                    label: "Days",
                                    color: .red
                                )
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                            
                            // Badges grid
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 16) {
                                ForEach(completedBadges, id: \.enrollmentID) { badge in
                                    BadgeCard(badge: badge)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Badges")
            .onAppear {
                loadBadges()
            }
        }
    }
    
    private var totalDaysCompleted: Int {
        completedBadges.reduce(0) { $0 + $1.duration }
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

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct BadgeCard: View {
    let badge: EnrollmentWithChallenge
    
    var body: some View {
        VStack(spacing: 14) {
            // Badge icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: gradientColors[0].opacity(0.3), radius: 8, x: 0, y: 4)
                
                Image(badge.challengeIconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
            }
            .padding(.top, 8)
            
            VStack(spacing: 6) {
                Text(badge.challengeName)
                    .font(.system(size: 16, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                
                // Duration badge
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text("\(badge.duration) day\(badge.duration > 1 ? "s" : "")")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
            }
            
            Divider()
                .padding(.horizontal, 8)
            
            VStack(spacing: 6) {
                // Steps per day
                HStack(spacing: 4) {
                    Image(systemName: "figure.walk")
                        .font(.caption)
                    Text("\(formatSteps(badge.targetSteps))/day")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.secondary)
                
                // Completion date
                if let completedDate = badge.completedAt {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text(formatDate(completedDate))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
    
    private var gradientColors: [Color] {
        // Different gradient based on duration
        switch badge.duration {
        case 1...3:
            return [.green, .mint]
        case 4...7:
            return [.blue, .cyan]
        case 8...14:
            return [.purple, .pink]
        default:
            return [.orange, .red]
        }
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

