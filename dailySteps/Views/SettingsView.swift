//
//  SettingsView.swift
//  dailySteps
//
//  Created by Andrea on 7/27/25.
//

import SwiftUI


struct StepGoalSettingsView: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    
    @State private var showCustomSheet = false
    @State private var customGoalText = ""
    @ObservedObject var themeManager = ThemeManager.shared

    var body: some View {
        ZStack {
            
            
            // Background gradient
            themeManager.backgroundColor
                .ignoresSafeArea()
            Form {
                Section(
                    header: Text("Step Goal")
                ) {
                    Stepper(
                        value: $mainViewModel.stepGoal,
                        in: 1_000...20_000,
                        step: 500
                    ) {
                        Text("Daily step goal: \(mainViewModel.stepGoal.formatted())")
                    }
                    
                    Button("Custom...") {
                        customGoalText = String(mainViewModel.stepGoal)
                        showCustomSheet = true
                    }
                }
                
                
                Section(
                    header: Text("Rest Days"),
                    footer: Text("Rest Days can be used for your personal goal. (NOTE: Rest days don't count towards challenges!)")
                ) {
                    Stepper("Rest Days: \(mainViewModel.graceDays)",
                            value: $mainViewModel.graceDays,
                            in: 0...3)
                }
                
                
                Section(
                    header: Text("Theme"),
                    footer: Text("Choose the colors of your app!")
                ) {
                    
                    ThemePickerView()
                }
                
                
                
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showCustomSheet) {
            CustomStepGoalView(text: $customGoalText) { newGoal in
                mainViewModel.stepGoal = newGoal
            }
        }

    }
}


struct CustomStepGoalView : View {
    
    @Environment(\.dismiss) private var dismiss
    
    @Binding var text: String
    let onSave: (Int) -> Void
    
    @State private var errorMessage: String?
    
    var body : some View  {
        NavigationView {
            Form {
                Section(header: Text("Custom Step Goal")) {
                    TextField("Enter steps: ", text: $text)
                        .keyboardType(.numberPad)
                    
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Custom Goal")
            .toolbar {
                
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        validateAndSave()
                    } label: {
                        Text("Done")
                    }
                    
                }
            }
        }
    }
    
    private func validateAndSave(){
        
        let cleanedText = text.replacingOccurrences(
            of: "[^0-9]",
            with: "",
            options: .regularExpression
        )
        
        guard let value = Int(cleanedText) else {
            errorMessage = "Please enter a valid number"
            return
        }
        
        guard (500 ... 50_000).contains(value) else {
            errorMessage = "Step Goal must be between 500 and 50,000 steps."
            return
        }
        
        onSave(value)
        dismiss()
        
    }
}
