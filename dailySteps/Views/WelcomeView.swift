import SwiftUI

// MARK: - Welcome View

struct WelcomeView: View {
    @State private var username = ""
    @State private var showError = false
    @State private var step: OnboardingStep = .name
    @State private var stepGoal: Double = 10000
    @State private var nameCardVisible = true
    @State private var goalCardVisible = false
    @State private var headerScale: CGFloat = 1.0
    @State private var headerOffset: CGFloat = 0
    @Binding var hasCompletedOnboarding: Bool

    enum OnboardingStep { case name, goal }

    var body: some View {
        ZStack {
            // ── Background ────────────────────────────────────────
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            // Soft top tint
            VStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.3, green: 0.5, blue: 0.9).opacity(0.08),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 320)
                Spacer()
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // ── Shared header (stays in place) ────────────────
                VStack(spacing: 14) {
                    Image("dailySteps")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 110, height: 110)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(color: Color(red: 0.3, green: 0.5, blue: 0.9).opacity(0.25),
                                radius: 18, x: 0, y: 8)

                    Text("Daily Steps")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.3, green: 0.5, blue: 0.9),
                                    Color(red: 0.9, green: 0.5, blue: 0.6)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .scaleEffect(headerScale)
                .offset(y: headerOffset)
                .animation(.spring(response: 0.55, dampingFraction: 0.75), value: headerScale)
                .animation(.spring(response: 0.55, dampingFraction: 0.75), value: headerOffset)

                // ── Step 1: Name ──────────────────────────────────
                if nameCardVisible {
                    NameStepCard(
                        username: $username,
                        showError: $showError,
                        onContinue: advanceToGoalStep
                    )
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity.combined(with: .move(edge: .bottom))
                        )
                    )
                }

                // ── Step 2: Step Goal ─────────────────────────────
                if goalCardVisible {
                    GoalStepCard(
                        username: username,
                        stepGoal: $stepGoal,
                        onFinish: { saveAndFinish() }
                    )
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity.combined(with: .move(edge: .bottom))
                        )
                    )
                }

                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Actions

    private func advanceToGoalStep() {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            showError = true
            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(.error)
            return
        }
        showError = false

        withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
            nameCardVisible = false
        }

        // Slight header shrink to signal progression
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.05)) {
            headerScale = 0.92
            headerOffset = -8
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                goalCardVisible = true
            }
        }

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }

    private func saveAndFinish() {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)

        UserDefaults.standard.set(trimmed, forKey: FieldKey.UserProfile.username)
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        UserDefaults.standard.set(deviceID, forKey: FieldKey.UserProfile.deviceID)
        UserDefaults.standard.set(stepGoal, forKey: "stepGoal")
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")

        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            hasCompletedOnboarding = true
        }
    }
}

// MARK: - Name Step Card

struct NameStepCard: View {
    @Binding var username: String
    @Binding var showError: Bool
    var onContinue: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Text("What should we call you?")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(Color(.label))

                Text("This is how we'll greet you every day")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(.secondaryLabel))
            }
            .multilineTextAlignment(.center)

            // Text field
            VStack(alignment: .leading, spacing: 6) {
                TextField("Your name", text: $username)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color(.systemBackground))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                showError
                                    ? Color.red.opacity(0.6)
                                    : (isFocused
                                        ? Color(red: 0.3, green: 0.5, blue: 0.9).opacity(0.5)
                                        : Color(.systemGray4)),
                                lineWidth: 1.5
                            )
                    )
                    .focused($isFocused)
                    .autocorrectionDisabled()
                    .submitLabel(.continue)
                    .onSubmit { onContinue() }
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)

                if showError {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption)
                        Text("Please enter your name")
                            .font(.caption)
                    }
                    .foregroundColor(.red)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            // Continue button
            Button(action: onContinue) {
                Text("Continue")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.3, green: 0.5, blue: 0.9),
                                Color(red: 0.6, green: 0.4, blue: 0.9)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(
                        color: Color(red: 0.3, green: 0.5, blue: 0.9).opacity(0.35),
                        radius: 12, x: 0, y: 5
                    )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.07), radius: 20, x: 0, y: 8)
        )
        .padding(.top, 32)
        .onAppear { isFocused = true }
    }
}

// MARK: - Goal Step Card

struct GoalStepCard: View {
    let username: String
    @Binding var stepGoal: Double
    var onFinish: () -> Void

    // Preset options
    let presets: [(label: String, value: Double)] = [
        ("5K",  5_000),
        ("7.5K", 7_500),
        ("10K", 10_000),
        ("15K", 15_000),
        ("20K", 20_000),
    ]

    var body: some View {
        VStack(spacing: 24) {
            // Greeting
            VStack(spacing: 6) {
                Text("Hey \(username)! 👋")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(Color(.label))

                Text("Set your daily step goal")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(.secondaryLabel))
            }
            .multilineTextAlignment(.center)

            // Big goal display
            VStack(spacing: 2) {
                Text(formatSteps(Int(stepGoal)))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.3, green: 0.5, blue: 0.9),
                                Color(red: 0.9, green: 0.5, blue: 0.6)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: stepGoal)

                Text("steps per day")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(.secondaryLabel))
            }

            // Preset chips
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5),
                spacing: 10
            ) {
                ForEach(presets, id: \.value) { preset in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            stepGoal = preset.value
                        }
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    } label: {
                        Text(preset.label)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(
                                stepGoal == preset.value
                                    ? .white
                                    : Color(red: 0.3, green: 0.5, blue: 0.9)
                            )
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        stepGoal == preset.value
                                            ? Color(red: 0.3, green: 0.5, blue: 0.9)
                                            : Color(red: 0.3, green: 0.5, blue: 0.9).opacity(0.1)
                                    )
                            )
                    }
                }
            }

            // Fine-tune stepper
            HStack {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        stepGoal = max(1_000, stepGoal - 500)
                    }
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 0.3, green: 0.5, blue: 0.9))
                        .frame(width: 44, height: 44)
                        .background(Color(red: 0.3, green: 0.5, blue: 0.9).opacity(0.1))
                        .clipShape(Circle())
                }

                Text("Fine-tune by 500")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(.secondaryLabel))
                    .frame(maxWidth: .infinity)

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        stepGoal = min(20_000, stepGoal + 500)
                    }
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 0.3, green: 0.5, blue: 0.9))
                        .frame(width: 44, height: 44)
                        .background(Color(red: 0.3, green: 0.5, blue: 0.9).opacity(0.1))
                        .clipShape(Circle())
                }
            }

            // Let's go button
            Button(action: onFinish) {
                HStack(spacing: 8) {
                    Text("Let's Go!")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.3, green: 0.5, blue: 0.9),
                            Color(red: 0.6, green: 0.4, blue: 0.9)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(
                    color: Color(red: 0.3, green: 0.5, blue: 0.9).opacity(0.35),
                    radius: 12, x: 0, y: 5
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.07), radius: 20, x: 0, y: 8)
        )
        .padding(.top, 32)
    }

    private func formatSteps(_ steps: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: steps)) ?? "\(steps)"
    }
}

// MARK: - Preview

#Preview("Name step") {
    WelcomeView(hasCompletedOnboarding: .constant(false))
}
