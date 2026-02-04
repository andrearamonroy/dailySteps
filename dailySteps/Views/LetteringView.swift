//
//  LetteringView.swift
//  dailySteps
//
//  Created by Andrea on 2/3/26.
//

import SwiftUI
import AVFoundation

struct LetteringView: View {
    @State private var displayedText = ""
    @State private var audioPlayer: AVAudioPlayer?
    
    let fullText = "Daily Steps"
    let typingSpeed: Double = 0.08 // seconds per character
    
    var body: some View {
        VStack(spacing: 20) {
            
            Image("dailySteps")
                .resizable()
                         .scaledToFill()
                         .frame(width: 120, height: 120)
                         .clipShape(RoundedRectangle(cornerRadius: 25))
                         .shadow(color: .gray.opacity(0.3), radius: 10, x: 0, y: 5)
                   
                   // Typewriter text
                   Text(displayedText)
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
               }
               .onAppear {
                   typeText()
               }
           }

    
    private func typeText() {
        displayedText = ""
        
        for (index, character) in fullText.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * typingSpeed) {
                displayedText.append(character)
                playTypeSound()
            }
        }
    }
    
    private func playTypeSound() {
        // Generate a simple beep sound programmatically
                let systemSoundID: SystemSoundID = 1104
                
                // Unfortunately system sounds can't have volume adjusted
                // So we'll create a louder programmatic sound
                AudioServicesPlaySystemSound(systemSoundID)
                
                // For actual volume control, use AVAudioPlayer with a sound file
                // See the alternative method below
    }
}

#Preview {
    LetteringView()
        .padding()
}
