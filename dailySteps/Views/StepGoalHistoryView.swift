//
//  StepGoalHistoryView.swift
//  dailySteps
//
//  Created by Andrea on 1/5/26.
//

import SwiftUI
import Charts

import SwiftUI
import Charts

struct StepGoalHistoryView: View {
    @EnvironmentObject private var mainViewModel: MainViewModel

    var history: [StepGoalChange] {
        mainViewModel.stepGoalHistoyManager.stepGoalHistory
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                Section {
                    ZStack {
                        // MARK: Chart (always visible)
                        Chart {
                            ForEach(history.sorted { $0.date < $1.date }) { change in
                                LineMark(
                                    x: .value("Date", change.date),
                                    y: .value("Step Goal", change.stepGoal)
                                )

                                PointMark(
                                    x: .value("Date", change.date),
                                    y: .value("Step Goal", change.stepGoal)
                                )
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day, count: 5)) { value in 
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel {
                                if let date = value.as(Date.self)
                                {
                                    Text(date, format : .dateTime.month().day())
                                }
                            }
                        }
                        }
                        .frame(height: 200)
                        .padding(.horizontal)

                        // MARK: Empty State Overlay
                        if history.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.title2)
                                    .foregroundColor(.secondary)

                                Text("No step goal history yet")
                                    .font(.headline)

                                Text("Your changes will appear here over time.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                        }
                    }
                } header: {
                    Text("Step Goal Trend")
                        .font(.headline)
                }
            }
        }
    }
}


#Preview {
    StepGoalHistoryView()
        .environmentObject(MainViewModel())
}

