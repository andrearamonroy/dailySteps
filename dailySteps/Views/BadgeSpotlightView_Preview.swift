import SwiftUI
import AVFoundation
import AudioToolbox


// MARK: - Preview

struct BadgeSpotlightPreview: View {
    @State private var isShowing = true
    
    var body: some View {
        ZStack {
            // Background to show it's full screen
            Color.gray.opacity(0.3)
                .ignoresSafeArea()
            
            if isShowing {
                BadgeSpotlightView(
                    challengeIconName: "trophy.fill",
                    challengeName: "10K Everyday",
                    isShowing: $isShowing
                ) {
                    print("Navigate to badges tapped")
                }
            } else {
                VStack {
                    Text("Badge Spotlight Dismissed")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Button("Show Again") {
                        isShowing = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}

#Preview {
    BadgeSpotlightPreview()
}
