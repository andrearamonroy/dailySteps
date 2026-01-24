//
//  WelcomeView.swift
//  dailySteps
//
//  Created by Andrea on 1/23/26.
//

import SwiftUI
// MARK: - Welcome Screen

struct UserProfile {
    static let username = "username"
    static let deviceID = "deviceID"
}

struct WelcomeView: View {
    @State private var username = ""
    @State private var showError = false
    @Binding var hasCompletedOnboarding: Bool
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [Color.blue, Color.purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // App icon/logo
                VStack(spacing: 16) {
                    Text("👟")
                        .font(.system(size: 100))
                    
                    Text("Step Challenge")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Track your steps, challenge yourself")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                // Username input
                VStack(alignment: .leading, spacing: 12) {
                    Text("What should we call you?")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    TextField("Enter your name", text: $username)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .autocorrectionDisabled()
                    
                    if showError {
                        Text("Please enter a name")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 32)
                
                // Get started button
                Button(action: {
                    saveUsername()
                }) {
                    Text("Get Started")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
        }
    }
    
    private func saveUsername() {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedUsername.isEmpty else {
            showError = true
            return
        }
        
        // Save username to UserDefaults
        UserDefaults.standard.set(trimmedUsername, forKey: UserProfile.username)
        
        // Save device ID
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        UserDefaults.standard.set(deviceID, forKey: UserProfile.deviceID)
        
        // Mark onboarding as complete
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        
        // Animate transition
        withAnimation {
            hasCompletedOnboarding = true
        }
    }
}
