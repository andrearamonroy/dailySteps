import SwiftUI
import AVFoundation

// MARK: - Badge Spotlight View

/// Full-screen spotlight shown after challenge completion card.
/// Badge zooms in → pulses → plays sound → user taps to navigate to Badges tab.
struct BadgeSpotlightView: View {
    let challengeIconName: String
    let challengeName: String
    @Binding var isShowing: Bool
    var onNavigateToBadges: () -> Void

    // Animation states
    @State private var backdropOpacity: Double = 0
    @State private var badgeScale: CGFloat = 0.1
    @State private var badgeOpacity: Double = 0
    @State private var ring1Scale: CGFloat = 0.8
    @State private var ring2Scale: CGFloat = 0.8
    @State private var ring3Scale: CGFloat = 0.8
    @State private var ringOpacity1: Double = 0
    @State private var ringOpacity2: Double = 0
    @State private var ringOpacity3: Double = 0
    @State private var labelOpacity: Double = 0
    @State private var labelOffset: CGFloat = 20
    @State private var buttonOpacity: Double = 0
    @State private var pulseActive: Bool = false
    @State private var rayRotation: Double = 0
    @State private var audioPlayer: AVAudioPlayer?

    var body: some View {
        ZStack {
            // ── Dark backdrop ─────────────────────────────────────
            Color.black.opacity(0.92)
                .ignoresSafeArea()
                .opacity(backdropOpacity)

            // ── Rotating light rays ───────────────────────────────
            RayBurstShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.85, blue: 0.3).opacity(0.12),
                            Color.clear
                        ],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                )
                .frame(width: 500, height: 500)
                .rotationEffect(.degrees(rayRotation))
                .opacity(backdropOpacity)

            // ── Pulse rings ───────────────────────────────────────
            ZStack {
                Circle()
                    .stroke(
                        Color(red: 1.0, green: 0.72, blue: 0.0).opacity(ringOpacity1),
                        lineWidth: 2.5
                    )
                    .frame(width: 130, height: 130)
                    .scaleEffect(ring1Scale)

                Circle()
                    .stroke(
                        Color(red: 1.0, green: 0.72, blue: 0.0).opacity(ringOpacity2),
                        lineWidth: 2
                    )
                    .frame(width: 170, height: 170)
                    .scaleEffect(ring2Scale)

                Circle()
                    .stroke(
                        Color(red: 1.0, green: 0.72, blue: 0.0).opacity(ringOpacity3),
                        lineWidth: 1.5
                    )
                    .frame(width: 220, height: 220)
                    .scaleEffect(ring3Scale)
            }
            .scaleEffect(pulseActive ? 1.08 : 1.0)
            .animation(
                .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                value: pulseActive
            )

            // ── Badge ─────────────────────────────────────────────
            ZStack {
                // Glow backdrop
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 1.0, green: 0.65, blue: 0.0).opacity(0.5),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.78, blue: 0.1),
                                Color(red: 1.0, green: 0.42, blue: 0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: .orange.opacity(0.7), radius: 24, x: 0, y: 8)

                Image(challengeIconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
            }
            .scaleEffect(badgeScale)
            .opacity(badgeOpacity)
            

            // ── Text + CTA ────────────────────────────────────────
            VStack(spacing: 20) {
                Spacer()

                VStack(spacing: 8) {
                    Text("Badge Earned")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(red: 1.0, green: 0.72, blue: 0.0))
                        .tracking(2)
                        .textCase(.uppercase)

                    Text(challengeName)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                .opacity(labelOpacity)
                .offset(y: labelOffset)

                Button {
                    navigateToBadges()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "rosette")
                            .font(.system(size: 16, weight: .semibold))
                        Text("See All Badges")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 36)
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
                        color: Color(red: 0.55, green: 0.45, blue: 1.0).opacity(0.45),
                        radius: 16, x: 0, y: 8
                    )
                }
                .opacity(buttonOpacity)

                Spacer()
                    .frame(height: 60)
            }
        }
        .onAppear {
            runEntranceSequence()
        }
    }

    // MARK: - Entrance Sequence

    private func runEntranceSequence() {
        // 1. Backdrop fades in
        withAnimation(.easeIn(duration: 0.35)) {
            backdropOpacity = 1.0
        }

        // 2. Badge zooms in with spring
        withAnimation(.spring(response: 0.55, dampingFraction: 0.60).delay(0.25)) {
            badgeScale = 1.0
            badgeOpacity = 1.0
        }

        // 3. Rings appear
        withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
            ring1Scale = 1.0; ringOpacity1 = 0.7
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.65)) {
            ring2Scale = 1.0; ringOpacity2 = 0.5
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.80)) {
            ring3Scale = 1.0; ringOpacity3 = 0.3
        }

        // 4. Start pulse loop
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            pulseActive = true
        }

        // 5. Play sound
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            playWinSound()
        }

        // 6. Start ray rotation
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false).delay(0.3)) {
            rayRotation = 360
        }

        // 7. Label slides up
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.8)) {
            labelOpacity = 1.0
            labelOffset = 0
        }

        // 8. Button fades in
        withAnimation(.easeIn(duration: 0.4).delay(1.2)) {
            buttonOpacity = 1.0
        }
    }

    private func navigateToBadges() {
        withAnimation(.easeIn(duration: 0.35)) {
            backdropOpacity = 0
            badgeOpacity = 0
            labelOpacity = 0
            buttonOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            isShowing = false
            onNavigateToBadges()
        }
    }

    // MARK: - Sound

  private func playWinSound() {
        // Uses a system sound as fallback — replace "win" with your own .mp3/.wav asset name
        if let url = Bundle.main.url(forResource: "win", withExtension: "mp3") {
            audioPlayer = try? AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } else {
            // Fallback to system sound
            AudioServicesPlaySystemSound(1025) // "Fanfare" system sound
        }
    }
}

// MARK: - Ray Burst Shape

struct RayBurstShape: Shape {
    let rayCount: Int = 16

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.35
        let angleStep = (2 * Double.pi) / Double(rayCount)
        let halfWidth = angleStep * 0.3

        for i in 0..<rayCount {
            let angle = Double(i) * angleStep - Double.pi / 2
            let innerLeft = CGPoint(
                x: center.x + innerRadius * cos(angle - halfWidth),
                y: center.y + innerRadius * sin(angle - halfWidth)
            )
            let outerTip = CGPoint(
                x: center.x + outerRadius * cos(angle),
                y: center.y + outerRadius * sin(angle)
            )
            let innerRight = CGPoint(
                x: center.x + innerRadius * cos(angle + halfWidth),
                y: center.y + innerRadius * sin(angle + halfWidth)
            )
            path.move(to: innerLeft)
            path.addLine(to: outerTip)
            path.addLine(to: innerRight)
            path.closeSubpath()
        }
        return path
    }
}

/// MARK: - Preview

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
