import SwiftUI

// MARK: - Confetti View

struct ConfettiView: View {
    let confettiColors: [Color] = [
        Color(red: 1.0, green: 0.8, blue: 0.2),
        Color(red: 0.4, green: 0.8, blue: 1.0),
        Color(red: 1.0, green: 0.4, blue: 0.7),
        Color(red: 0.5, green: 1.0, blue: 0.6),
        Color(red: 0.9, green: 0.5, blue: 1.0),
        Color(red: 1.0, green: 0.6, blue: 0.3),
    ]

    struct PieceData: Identifiable {
        let id = UUID()
        let startX: CGFloat
        let color: Color
        let size: CGFloat
        let isCircle: Bool
        let duration: Double
        let delay: Double
        let drift: CGFloat
        let startRotation: Double
        let endRotation: Double
        let opacity: Double
    }

    @State private var pieces: [PieceData] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    ConfettiPiece(data: piece, screenHeight: geo.size.height)
                }
            }
            .onAppear {
                pieces = (0..<90).map { _ in
                    PieceData(
                        startX: CGFloat.random(in: 0...geo.size.width),
                        color: confettiColors.randomElement()!,
                        size: CGFloat.random(in: 6...14),
                        isCircle: Bool.random(),
                        duration: Double.random(in: 2.2...5.0),
                        delay: Double.random(in: 0...2.0),
                        drift: CGFloat.random(in: -80...80),
                        startRotation: Double.random(in: 0...360),
                        endRotation: Double.random(in: 360...1440),
                        opacity: Double.random(in: 0.75...1.0)
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .clipped()
    }
}

private struct ConfettiPiece: View {
    let data: ConfettiView.PieceData
    let screenHeight: CGFloat

    @State private var posY: CGFloat = -20
    @State private var posX: CGFloat = 0
    @State private var rot: Double = 0
    @State private var opa: Double = 0

    var body: some View {
        Group {
            if data.isCircle {
                Circle()
                    .fill(data.color)
                    .frame(width: data.size, height: data.size)
            } else {
                RoundedRectangle(cornerRadius: 2)
                    .fill(data.color)
                    .frame(width: data.size, height: data.size * 0.45)
            }
        }
        .opacity(opa)
        .rotationEffect(.degrees(rot))
        .position(x: data.startX + posX, y: posY)
        .onAppear {
            posY = -20
            posX = 0
            rot = data.startRotation
            opa = 0
            withAnimation(
                .linear(duration: data.duration)
                .delay(data.delay)
                .repeatForever(autoreverses: false)
            ) {
                posY = screenHeight + 60
                posX = data.drift
                rot = data.endRotation
                opa = data.opacity
            }
        }
    }
}

// MARK: - Goal Reached Overlay

struct GoalReachedOverlay: View {
    let challengeName: String
    let targetSteps: Int
    let challengeIconName: String
    @Binding var isShowing: Bool

    @State private var cardScale: CGFloat = 0.75
    @State private var cardOpacity: Double = 0
    @State private var badgeScale: CGFloat = 0.4
    @State private var badgeBounce: Bool = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()

            ConfettiView()
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // Badge + close button
                ZStack(alignment: .topTrailing) {
                    Button { dismiss() } label: {
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
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color(red: 1.0, green: 0.65, blue: 0.0).opacity(0.25),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 20,
                                        endRadius: 60
                                    )
                                )
                                .frame(width: 120, height: 120)

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
                                .shadow(color: Color.orange.opacity(0.35), radius: 16, x: 0, y: 6)

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

                // Text
                VStack(spacing: 6) {
                    Text("Congrats!")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(Color(.label))

                    Text("You reached today's goal")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(.secondaryLabel))
                }
                .padding(.top, 12)
                .padding(.bottom, 20)

                // Steps pill
                VStack(spacing: 4) {
                    Text(challengeName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(red: 0.35, green: 0.50, blue: 1.0))
                        .tracking(0.3)

                    Text(formatSteps(targetSteps))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(Color(.label))

                    Text("steps completed")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(.secondaryLabel))
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
                .padding(.bottom, 24)

                // Button
                Button { dismiss() } label: {
                    Text("Keep Going!")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
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
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(0.6)) {
                badgeBounce = true
            }
            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(.success)
        }
    }

    private func dismiss() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            cardScale = 0.88
            cardOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            isShowing = false
        }
    }

    private func formatSteps(_ steps: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: steps)) ?? "\(steps)"
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        GoalReachedOverlay(
            challengeName: "Turbo Tuesday",
            targetSteps: 12000,
            challengeIconName: "turboTuesday",
            isShowing: .constant(true)
        )
    }
}
