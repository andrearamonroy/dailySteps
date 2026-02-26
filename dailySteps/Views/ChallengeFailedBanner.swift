import SwiftUI
import CloudKit

// MARK: - Encouraging messages

private let encouragingMessages: [String] = [
    "You got this — try again! 💪",
    "Don't give up, you're closer than you think! 🔥",
    "One bad day doesn't define you. Get back out there! 🚀",
    "Champions restart. Give it another shot! 🏆",
    "You can dooooo ittttt!!! We believe in you! 🎉",
    "Shake it off and try again — you've got this! ⚡️",
    "Restart and crush it! 💥",
    "Miss once, come back twice as strong! 💫",
]

// MARK: - Challenge Failed Banner

struct ChallengeFailedBanner: View {
    let challengeName: String
    let challenge: CKRecord
    let failureReason: ChallengeFailureReason
    var onTryAgain: () -> Void
    var onDismiss: () -> Void

    @State private var offsetY: CGFloat = -200
    @State private var opacity: Double = 0
    private let message = encouragingMessages.randomElement()!

    var reasonText: String {
        switch failureReason {
        case .missedDay:  return "You missed a day and your streak reset."
        case .finalDay:   return "You didn't reach the step goal on the final day."
        case .both:       return "Your streak reset and the challenge ended."
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // Badge icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.72, blue: 0.0),
                                    Color(red: 1.0, green: 0.45, blue: 0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    ChallengeIconView(challenge: challenge)
                        .frame(width: 26, height: 26)
                     
                }

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(challengeName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.75))

                    Text(message)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(reasonText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.65))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 1)
                }

                Spacer()

                // Dismiss X
                Button { animateDismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 26, height: 26)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            // Try Again button
            Button {
                animateDismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    onTryAgain()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .bold))
                    Text("Try Again")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .foregroundColor(Color(red: 1.0, green: 0.55, blue: 0.1))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.white)
                .cornerRadius(10)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.45, blue: 0.15),
                            Color(red: 0.95, green: 0.30, blue: 0.20)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.orange.opacity(0.35), radius: 16, x: 0, y: 6)
        )
        .padding(.horizontal, 16)
        .offset(y: offsetY)
        .opacity(opacity)
        .onAppear { animateIn() }
    }

    private func animateIn() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) {
            offsetY = 0
            opacity = 1
        }
        // Auto-dismiss after 8 seconds if user doesn't interact
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            animateDismiss()
        }
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.warning)
    }

    private func animateDismiss() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            offsetY = -200
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            onDismiss()
        }
    }
}

// MARK: - Failure reason

enum ChallengeFailureReason {
    case missedDay
    case finalDay
    case both
}

// MARK: - CloudKit failure detection
// Add this to CloudKitManager

extension CloudKitManager {
    /// Call this on app launch / onAppear inside StepView.
    /// Returns a failure reason if the active enrollment has failed, nil otherwise.
    func checkForChallengeFailure(
        challenge: CKRecord,
        enrollment: CKRecord,
        completion: @escaping (ChallengeFailureReason?) -> Void
    ) {
        // Already completed — not a failure
        if enrollment["completedAt"] as? Date != nil {
            completion(nil)
            return
        }

        let duration      = challenge["duration"] as? Int ?? 30
        let targetSteps   = challenge["targetSteps"] as? Int ?? 10000
        let daysCompleted = enrollment["totalDaysCompleted"] as? Int ?? 0
        let currentStreak = enrollment["currentStreak"] as? Int ?? 0
        let startDate     = enrollment["startDate"] as? Date ?? Date()

        // Days elapsed since challenge started
        let daysSinceStart = Calendar.current.dateComponents(
            [.day], from: startDate, to: Date()
        ).day ?? 0

        let missedDay  = currentStreak == 0 && daysCompleted > 0
        let finalDayFailed = daysSinceStart >= duration && daysCompleted < duration

        switch (missedDay, finalDayFailed) {
        case (true, true):  completion(.both)
        case (true, false): completion(.missedDay)
        case (false, true): completion(.finalDay)
        default:            completion(nil)
        }
    }
}

// MARK: - How to use in StepView
/*

 1. Add state to StepView:

    @State private var showFailureBanner = false
    @State private var failureReason: ChallengeFailureReason = .missedDay
    @AppStorage("lastFailureBannerDate") private var lastFailureBannerDate: String = ""

 2. In loadActiveChallenge(), inside the .success case, after setting
    activeChallenge and enrollment, add:

    self.checkChallengeFailure(challenge: challenge, enrollment: enrollment)

 3. Add the helper to StepView:

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

 4. Add the banner overlay inside your NavigationStack, ABOVE the toolbar:

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
*/

//// MARK: - Preview
//
//#Preview {
//    ZStack(alignment: .top) {
//        Color(.systemGroupedBackground).ignoresSafeArea()
//        ChallengeFailedBanner(
//            challengeName: "Turbo Tuesday",
//            challenge: "turboTuesday",
//            failureReason: .missedDay,
//            onTryAgain: { print("try again") },
//            onDismiss: { print("dismissed") }
//        )
//        .padding(.top, 20)
//    }
//}
