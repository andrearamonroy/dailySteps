import SwiftUI
import CloudKit

// Preview wrapper with sample data
struct BadgesView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview with badges
            BadgesViewWithSampleData()
                .previewDisplayName("With Badges")
            
            // Empty state preview
            BadgesView()
                .environmentObject(AppState())
                .previewDisplayName("Empty State")
        }
    }
}



// Wrapper view that injects sample data
struct BadgesViewWithSampleData: View {
    @StateObject private var appState = AppState()
    
    var body: some View {
        BadgesViewPreviewContent()
            .environmentObject(appState)
    }
}

struct BadgesViewPreviewContent: View {
    @EnvironmentObject var appState: AppState
    @State private var completedBadges: [EnrollmentWithChallenge] = sampleBadges
    @State private var isLoading = false
    
    static var sampleBadges: [EnrollmentWithChallenge] = {
        // Create mock CKRecords for preview
        func createMockEnrollment(
            id: String,
            startDate: Date,
            streak: Int,
            daysCompleted: Int,
            completedAt: Date?
        ) -> CKRecord {
            let record = CKRecord(recordType: "Enrollment")
            record.setValue(startDate, forKey: "startDate")
            record.setValue(completedAt, forKey: "completedAt")
            record.setValue(streak, forKey: "currentStreak")
            record.setValue(daysCompleted, forKey: "totalDaysCompleted")
            record.setValue(false, forKey: "isActive")
            return record
        }
        
        func createMockChallenge(
            id: String,
            name: String,
            icon: String,
            duration: Int,
            steps: Int
        ) -> CKRecord {
            let record = CKRecord(recordType: "Challenge")
            record.setValue(id, forKey: "challengeID")
            record.setValue(name, forKey: "name")
            record.setValue(icon, forKey: "iconName")
            record.setValue(duration, forKey: "duration")
            record.setValue(steps, forKey: "targetSteps")
            return record
        }
        
        let now = Date()
        let cal = Calendar.current
        
        return [
            EnrollmentWithChallenge(
                from: createMockEnrollment(
                    id: "1",
                    startDate: now,
                    streak: 1,
                    daysCompleted: 1,
                    completedAt: now
                ),
                challenge: createMockChallenge(
                    id: "10k-monday",
                    name: "10K Monday",
                    icon: "10kMonday",
                    duration: 1,
                    steps: 10000
                )
            ),
            EnrollmentWithChallenge(
                from: createMockEnrollment(
                    id: "2",
                    startDate: cal.date(byAdding: .day, value: -12, to: now)!,
                    streak: 7,
                    daysCompleted: 7,
                    completedAt: cal.date(byAdding: .day, value: -5, to: now)!
                ),
                challenge: createMockChallenge(
                    id: "weekend-warrior",
                    name: "Weekend Warrior",
                    icon: "weekendWarrior",
                    duration: 7,
                    steps: 8000
                )
            ),
            EnrollmentWithChallenge(
                from: createMockEnrollment(
                    id: "3",
                    startDate: cal.date(byAdding: .day, value: -45, to: now)!,
                    streak: 30,
                    daysCompleted: 30,
                    completedAt: cal.date(byAdding: .day, value: -15, to: now)!
                ),
                challenge: createMockChallenge(
                    id: "10k-everyday",
                    name: "10K Everyday",
                    icon: "10kEveryday",
                    duration: 30,
                    steps: 10000
                )
            ),
            EnrollmentWithChallenge(
                from: createMockEnrollment(
                    id: "4",
                    startDate: cal.date(byAdding: .day, value: -2, to: now)!,
                    streak: 1,
                    daysCompleted: 1,
                    completedAt: cal.date(byAdding: .day, value: -2, to: now)!
                ),
                challenge: createMockChallenge(
                    id: "turbo-tuesday",
                    name: "Turbo Tuesday",
                    icon: "turboTuesday",
                    duration: 1,
                    steps: 12000
                )
            ),
            EnrollmentWithChallenge(
                from: createMockEnrollment(
                    id: "5",
                    startDate: cal.date(byAdding: .day, value: -44, to: now)!,
                    streak: 14,
                    daysCompleted: 14,
                    completedAt: cal.date(byAdding: .day, value: -30, to: now)!
                ),
                challenge: createMockChallenge(
                    id: "7k-everyday",
                    name: "7K Everyday",
                    icon: "7kEveryday",
                    duration: 14,
                    steps: 7000
                )
            ),
            EnrollmentWithChallenge(
                from: createMockEnrollment(
                    id: "6",
                    startDate: cal.date(byAdding: .day, value: -7, to: now)!,
                    streak: 1,
                    daysCompleted: 1,
                    completedAt: cal.date(byAdding: .day, value: -7, to: now)!
                ),
                challenge: createMockChallenge(
                    id: "super-saturday",
                    name: "Super Saturday",
                    icon: "superSaturday",
                    duration: 1,
                    steps: 15000
                )
            )
        ]
    }()
    
    var totalDaysCompleted: Int {
        completedBadges.reduce(0) { $0 + $1.duration }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
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
            .navigationTitle("Badges")
        }
    }
}
