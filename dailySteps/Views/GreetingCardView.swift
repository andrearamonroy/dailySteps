import SwiftUI

// MARK: - Greeting Card View

struct GreetingCardView: View {
    @AppStorage("username") private var username: String = ""

    // Rotates every time the view appears
    @State private var messageIndex: Int = 0

    private let messages: [String] = [
        "Every step counts. Keep moving! 🚶",
        "You showed up today — that's already a win! 🏆",
        "Small steps lead to big results! 💪",
        "Consistency is your superpower! ⚡️",
        "Let's make today count! 🔥",
        "One step at a time, you've got this! 👟",
        "Your future self will thank you! 🌟",
        "Progress, not perfection! Keep going! 🎯",
        "Another day, another opportunity to crush it! 💥",
        "You're stronger than you think! 🦾",
    ]

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        default:      return "Good evening"
        }
    }

    private var firstName: String {
        username.components(separatedBy: " ").first ?? username
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Greeting + name
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(greeting),")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)

                    Text(firstName.isEmpty ? "Champion 👋" : "\(firstName)! 👋")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
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

                Spacer()

//                // Animated emoji pulse
//                Text("🏃")
//                    .font(.system(size: 36))
            }

            Divider()
                .padding(.vertical, 2)

            // Encouraging message
            Text(messages[messageIndex])
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(Color(.secondaryLabel))
                .fixedSize(horizontal: false, vertical: true)
                .id(messageIndex) // triggers transition on change
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
        .onAppear {
            // Pick a random message each time the view appears
            withAnimation(.easeInOut(duration: 0.4)) {
                messageIndex = Int.random(in: 0..<messages.count)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        GreetingCardView()
            .padding(.top, 20)
    }
}
