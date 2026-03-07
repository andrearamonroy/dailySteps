import SwiftUI

// MARK: - Challenge Completed Overlay

struct ChallengeCompletedOverlay: View {
    let challengeName: String
    let totalDays: Int
    let targetSteps: Int
    let challengeIconName: String
    @Binding var isShowing: Bool
    var onViewBadge: () -> Void  // called after dismiss to trigger spotlight

    @State private var cardScale: CGFloat = 0.75
    @State private var cardOpacity: Double = 0
    @State private var badgeScale: CGFloat = 0.4
    @State private var badgeBounce: Bool = false
    @State private var starsVisible: Bool = false

    var body: some View {
        ZStack {
            // Dimmed backdrop
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            // Confetti
            ConfettiView()
                .ignoresSafeArea()

            // Floating star particles behind card
            if starsVisible {
                StarParticlesView()
                    .ignoresSafeArea()
            }

            // Card
            VStack(spacing: 0) {

                // ── Badge / close row ─────────────────────────────────
                ZStack(alignment: .topTrailing) {
                    Button { dismissCard() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(.systemGray2))
                            .frame(width: 30, height: 30)
                            .background(Color(.systemGray5))
                            .clipShape(Circle())
                    }
                    .padding(16)

                    HStack {
                        Spacer()
                        ZStack {
                            // Multi-ring glow for extra celebration
                            ForEach(0..<3) { i in
                                Circle()
                                    .stroke(
                                        Color(red: 1.0, green: 0.72, blue: 0.0)
                                            .opacity(0.15 - Double(i) * 0.04),
                                        lineWidth: 2
                                    )
                                    .frame(
                                        width: CGFloat(90 + i * 22),
                                        height: CGFloat(90 + i * 22)
                                    )
                                    .scaleEffect(badgeBounce ? 1.06 : 1.0)
                            }

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
                                .frame(width: 80, height: 80)
                                .shadow(color: Color.orange.opacity(0.4), radius: 18, x: 0, y: 6)

                            Image(challengeIconName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 46, height: 46)
                        }
                        .scaleEffect(badgeScale)
                        .scaleEffect(badgeBounce ? 1.08 : 1.0)
                        Spacer()
                    }
                    .padding(.top, 28)
                    .padding(.bottom, 4)
                }

                // ── Text ─────────────────────────────────────────────
                VStack(spacing: 6) {
                    Text("Challenge Complete!")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(Color(.label))

                    Text("You crushed the \(challengeName)!")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(.secondaryLabel))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                .padding(.top, 12)
                .padding(.bottom, 20)

                // ── Stats pill ────────────────────────────────────────
                HStack(spacing: 0) {
                    VStack(spacing: 4) {
                        Text("\(totalDays)")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(Color(.label))
                        Text("days completed")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    .frame(maxWidth: .infinity)

                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 1, height: 44)

                    VStack(spacing: 4) {
                        Text(formatSteps(targetSteps))
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(Color(.label))
                        Text("steps/day")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

                // ── Buttons ───────────────────────────────────────────
                VStack(spacing: 10) {
                    // Primary - view badge
                    Button {
                        dismissCard(thenShowBadge: true)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 16))
                            Text("View My Badge")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
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
                            radius: 14, x: 0, y: 6
                        )
                    }

                    // Secondary - dismiss
                    Button {
                        dismissCard()
                        // Post notification to refresh challenges
                        NotificationCenter.default.post(name: NSNotification.Name("ChallengeEnded"), object: nil)
                    } label: {
                        Text(totalDays == 1 ? "Awesome!" : "Keep Going!")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(.secondaryLabel))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
            .frame(maxWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.18), radius: 40, x: 0, y: 20)
            )
            .scaleEffect(cardScale)
            .opacity(cardOpacity)
            .padding(.horizontal, 24)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) {
                cardScale = 1.0
                cardOpacity = 1.0
            }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.55).delay(0.15)) {
                badgeScale = 1.0
            }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true).delay(0.6)) {
                badgeBounce = true
            }
            withAnimation(.easeIn(duration: 0.4).delay(0.3)) {
                starsVisible = true
            }
            // Haptic
            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(.success)
        }
    }

    private func dismissCard(thenShowBadge: Bool = false) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            cardScale = 0.88
            cardOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            isShowing = false
            if thenShowBadge {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    onViewBadge()
                }
            }
        }
    }

    private func formatSteps(_ steps: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: steps)) ?? "\(steps)"
    }
}

// MARK: - Star Particles (extra flair for completion)

struct StarParticlesView: View {
    @State private var particles: [StarParticle] = []

    struct StarParticle: Identifiable {
        let id = UUID()
        let x: CGFloat
        let startY: CGFloat
        let size: CGFloat
        let duration: Double
        let delay: Double
        let opacity: Double
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    Image(systemName: "star.fill")
                        .font(.system(size: p.size))
                        .foregroundColor(.yellow.opacity(p.opacity))
                        .modifier(FloatingStarModifier(
                            startX: p.x,
                            startY: p.startY,
                            screenHeight: geo.size.height,
                            duration: p.duration,
                            delay: p.delay
                        ))
                }
            }
            .onAppear {
                particles = (0..<20).map { _ in
                    StarParticle(
                        x: CGFloat.random(in: 0...geo.size.width),
                        startY: CGFloat.random(in: geo.size.height * 0.3...geo.size.height),
                        size: CGFloat.random(in: 8...20),
                        duration: Double.random(in: 2.5...5.0),
                        delay: Double.random(in: 0...2.0),
                        opacity: Double.random(in: 0.4...0.9)
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct FloatingStarModifier: ViewModifier {
    let startX: CGFloat
    let startY: CGFloat
    let screenHeight: CGFloat
    let duration: Double
    let delay: Double

    @State private var offsetY: CGFloat = 0
    @State private var opacity: Double = 0

    func body(content: Content) -> some View {
        content
            .position(x: startX, y: startY + offsetY)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeOut(duration: duration)
                    .delay(delay)
                    .repeatForever(autoreverses: false)
                ) {
                    offsetY = -screenHeight * 0.8
                    opacity = 0
                }
                withAnimation(.easeIn(duration: 0.3).delay(delay)) {
                    opacity = 1
                }
            }
    }
}
