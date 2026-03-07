import SwiftUI
import CloudKit

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
