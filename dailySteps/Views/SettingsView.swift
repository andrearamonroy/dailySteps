//
//  SettingsView.swift
//  dailySteps
//
//  Created by Andrea on 7/27/25.
//

import SwiftUI

import SwiftUI

struct StepGoalSettingsView: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    @State private var isEditing = false
    @State private var tempGoal: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Step Goal")) {
                    if isEditing {
                        HStack {
                            TextField("Enter step goal", text: $tempGoal)
                                .keyboardType(.numberPad)
                            Spacer()
                        }

                        HStack {
                            Button("Cancel") {
                                isEditing = false
                            }
                            .foregroundColor(.red)

                            Spacer()

                            Button("Done") {
                                if let newGoal = Double(tempGoal), newGoal > 0 {
                                    mainViewModel.stepGoal = newGoal
                                }
                                isEditing = false
                            }
                            .foregroundColor(.blue)
                        }
                    } else {
                        HStack {
                            Text("Current Goal")
                            Spacer()
                            Text("\(Int(mainViewModel.stepGoal)) steps")
                                .foregroundColor(.gray)
                        }
                        .contentShape(Rectangle()) // Makes the row tappable
                        .onTapGesture {
                            tempGoal = String(Int(mainViewModel.stepGoal))
                            isEditing = true
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

