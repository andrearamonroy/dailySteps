import SwiftUI
import CloudKit

// ============================================================
// MARK: - 1. ADD TO AppState
// ============================================================
// Add these two properties to your AppState class:
//
//   @Published var showChallengeCompletedOverlay = false
//   @Published var showBadgeSpotlight = false
//   @Published var completedChallengeName: String = ""
//   @Published var completedChallengeIconName: String = ""
//   @Published var completedChallengeDays: Int = 0
//   @Published var completedChallengeSteps: Int = 0


// ============================================================
// MARK: - 2. CLOUDKIT — CHECK FOR COMPLETION IN loadActiveChallenge
// ============================================================
// Inside StepView.loadActiveChallenge(), in the .success case,
// ADD this check after setting self.activeChallenge and self.enrollment:
//
//   case .success(let (challenge, enrollment)):
//       self.activeChallenge = challenge
//       self.enrollment = enrollment
//
//       // ↓ ADD THIS ↓
//       self.checkIfChallengeJustCompleted(challenge: challenge, enrollment: enrollment)
//
// Then add this helper to StepView:



// ============================================================
// MARK: - 3. ADD OVERLAYS TO StepView body
// ============================================================
// Inside your NavigationStack in StepView, add these two overlays
// AFTER your existing toolbar/refreshable modifiers:
//
//   .overlay {
//       if appState.showChallengeCompletedOverlay {
//           ChallengeCompletedOverlay(
//               challengeName: appState.completedChallengeName,
//               totalDays: appState.completedChallengeDays,
//               targetSteps: appState.completedChallengeSteps,
//               challengeIconName: appState.completedChallengeIconName,
//               isShowing: $appState.showChallengeCompletedOverlay
//           ) {
//               // "View My Badge" tapped — show spotlight
//               appState.showBadgeSpotlight = true
//           }
//           .transition(.opacity)
//           .zIndex(999)
//       }
//   }
//   .fullScreenCover(isPresented: $appState.showBadgeSpotlight) {
//       BadgeSpotlightView(
//           challengeIconName: appState.completedChallengeIconName,
//           challengeName: appState.completedChallengeName,
//           isShowing: $appState.showBadgeSpotlight
//       ) {
//           // Navigate to badges tab (tab index 3)
//           appState.selectedTab = 3
//       }
//   }


// ============================================================
// MARK: - 4. ADD BADGES TAB TO YOUR MAIN TAB VIEW
// ============================================================
// Find your main TabView (likely in ContentView or MainTabView)
// and add BadgesTabView as the 4th tab:
//
//   TabView(selection: $appState.selectedTab) {
//
//       // ... your existing tabs (0, 1, 2) ...
//
//       BadgesTabView()
//           .tabItem {
//               Label("Badges", systemImage: "rosette")
//           }
//           .tag(3)
//   }


// ============================================================
// MARK: - 5. STORE CHALLENGE NAME/ID ON ENROLLMENT AT ENROLL TIME
// ============================================================
// In your CloudKitManager.enrollInChallenge(), when creating the
// enrollment CKRecord, make sure you store these fields so
// fetchCompletedBadges() can read them back without a join:
//
//   enrollmentRecord["challengeName"] = challenge["name"]
//   enrollmentRecord["challengeID"]   = challenge["challengeID"]
//   enrollmentRecord["duration"]      = challenge["duration"]
//   enrollmentRecord["targetSteps"]   = challenge["targetSteps"]
//
// These are denormalised copies — they let BadgesTabView show
// badge info even if the original Challenge record changes.


// ============================================================
// MARK: - Preview helper (remove before shipping)
// ============================================================

struct ChallengeCompletionPreview: View {
    @State private var showCompleted = true
    @State private var showSpotlight = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            Text("StepView behind")

            if showCompleted {
                ChallengeCompletedOverlay(
                    challengeName: "Turbo Tuesday",
                    totalDays: 30,
                    targetSteps: 12000,
                    challengeIconName: "turboTuesday",
                    isShowing: $showCompleted
                ) {
                    showSpotlight = true
                }
                .transition(.opacity)
                .zIndex(999)
            }
        }
        .fullScreenCover(isPresented: $showSpotlight) {
            BadgeSpotlightView(
                challengeIconName: "turboTuesday",
                challengeName: "Turbo Tuesday",
                isShowing: $showSpotlight
            ) {
                print("→ navigate to badges tab")
            }
        }
    }
}

#Preview("Completion Flow") {
    ChallengeCompletionPreview()
}
