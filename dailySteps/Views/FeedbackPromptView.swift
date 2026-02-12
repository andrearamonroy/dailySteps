import SwiftUI
import StoreKit

struct FeedbackPromptView: View {
    @Binding var isShowing: Bool
    @Environment(\.requestReview) private var requestReview
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        isShowing = false
                    }
                }
            
            VStack(spacing: 20) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.45, green: 0.55, blue: 1.0).opacity(0.2),
                                    Color(red: 0.75, green: 0.45, blue: 1.0).opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.45, green: 0.55, blue: 1.0),
                                    Color(red: 0.75, green: 0.45, blue: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                // Title
                Text("Enjoying Daily Steps?")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Message
                Text("Your feedback helps us improve and motivates us to keep building!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Buttons
                VStack(spacing: 12) {
                    // Rate on App Store
                    Button(action: {
                        requestReview()
                        withAnimation {
                            isShowing = false
                        }
                        // Mark that user was prompted
                        UserDefaults.standard.set(Date(), forKey: "lastFeedbackPromptDate")
                    }) {
                        HStack {
                            Image(systemName: "star.fill")
                            Text("Rate on App Store")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
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
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    // Send Feedback
                    Button(action: {
                        // Open email or feedback form
                        sendFeedbackEmail()
                        withAnimation {
                            isShowing = false
                        }
                        UserDefaults.standard.set(Date(), forKey: "lastFeedbackPromptDate")
                    }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("Send Feedback")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                    
                    // Not Now
                    Button(action: {
                        withAnimation {
                            isShowing = false
                        }
                    }) {
                        Text("Maybe Later")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 40)
        }
    }
    
    private func sendFeedbackEmail() {
        let email = "your.email@example.com" // Replace with your email
        let subject = "Daily Steps Feedback"
        let body = "Hi there,\n\nI'd like to share some feedback:\n\n"
        
        if let url = URL(string: "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()
        
        FeedbackPromptView(isShowing: .constant(true))
    }
}
