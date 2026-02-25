//
//  WeeklyStepsView.swift
//  dailySteps
//
//  Created by Andrea on 1/11/26.
//

import SwiftUI
import CoreData


struct WeeklyStepsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var mainViewModel: MainViewModel
    @AppStorage("stepGoal", store: UserDefaults(suiteName: "group.com.andrearamonroy.dailySteps")) var stepGoal: Int = 10_000

    @FetchRequest private var days: FetchedResults<Day>
    
    private let spacing: CGFloat = 12
      private let dayWidth: CGFloat = 48

    init() {
        let calendar = Calendar(identifier: .iso8601)
        let today = Date()
        let startOfWeek = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        )!
        let startOfNextWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!

        _days = FetchRequest<Day>(
            sortDescriptors: [NSSortDescriptor(keyPath: \Day.date, ascending: true)],
            predicate: NSPredicate(
                format: "date >= %@ AND date < %@",
                startOfWeek as NSDate,
                startOfNextWeek as NSDate
            )
        )
    }

    private let dayFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "EEE"
        return df
    }()

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: spacing) {
                    ForEach(currentWeekDates(), id: \.self) { date in
                        VStack(spacing: 6) {
                            Text(dayFormatter.string(from: date))
                                .font(.caption)
                                .fontWeight(.semibold)

                            DayStepProgressView(
                                date: date,
                                steps: steps(for: date),
                                stepGoal: stepGoal
                            )
                            .frame(width: dayWidth, height: dayWidth)

                            Text("\(steps(for: date))")
                                .font(.caption2)
                                .foregroundColor(isToday(date) ? .blue : .secondary)

                            Text("steps")
                                .font(.caption2)
                                .foregroundColor(isToday(date) ? .blue : .secondary)
                        }
                        .frame(width: dayWidth)
                        .id(Calendar.current.startOfDay(for: date))
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .onAppear {
                // Scroll to today's date using startOfDay
                let today = Calendar.current.startOfDay(for: Date())
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {  // ← Add small delay
                    withAnimation {
                        proxy.scrollTo(today, anchor: .center)
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        )
        .padding(.horizontal)
    }
    
    
    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    private func currentWeekDates() -> [Date] {
        let calendar = Calendar(identifier: .iso8601)
        let startOfWeek = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        )!
        return (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: startOfWeek)
        }
    }

    private func steps(for date: Date) -> Int {
        if Calendar.current.isDateInToday(date) {
            return mainViewModel.healthManager.stepCount
        }

        guard let day = days.first(where: {
            if let savedDate = $0.date {
                return Calendar.current.isDate(savedDate, inSameDayAs: date)
            }
            return false
        }) else { return 0 }

        return Int(day.stepCount)
    }
}



struct DayStepProgressView: View {
    @EnvironmentObject private var mainViewModel: MainViewModel
    let date: Date
    let steps: Int
    let stepGoal: Int
    @ObservedObject var themeManager = ThemeManager.shared
    private var progress: Double {
        min(Double(steps) / Double(stepGoal), 1.0)
    }

    var body: some View {
        ZStack {
            // Background gray circle
            Circle()
                .stroke(lineWidth: 8)
                .foregroundColor(.gray.opacity(0.3))
                .frame(width: 44, height: 44)

            // Progress overlay only if > 0
            if progress > 0 {
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        progress >= 1 ? Color.green :  Color.orange,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 44, height: 44)
            }

            // Optional step count inside circle
            Text("\(Int(progress * 100))%")
                .font(.caption2)
                .bold()
        }
    }
}


struct WeeklyStepsView1: View {

    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var mainViewModel: MainViewModel

    // MARK: - Core Data Fetch (Current Week: Mon → Sun)
    @FetchRequest private var days: FetchedResults<Day>

    init() {
        let calendar = Calendar(identifier: .iso8601)
        let today = Date()

        // Monday 00:00 of current week
        let startOfWeek = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        )!

        // Next Monday 00:00
        let startOfNextWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!

        _days = FetchRequest<Day>(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Day.date, ascending: true)
            ],
            predicate: NSPredicate(
                format: "date >= %@ AND date < %@",
                startOfWeek as NSDate,
                startOfNextWeek as NSDate
            )
        )
    }

    // MARK: - Formatters
    private let dayFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "EEE" // Mon, Tue, Wed
        return df
    }()

    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Weekly Steps")
                .font(.title2)
                .bold()

            ForEach(currentWeekDates(), id: \.self) { date in
                HStack {
                    Text(dayFormatter.string(from: date))
                        .frame(width: 80, alignment: .leading)

                    Spacer()

                    Text("\(steps(for: date)) steps")
                        .bold()
                        .foregroundColor(
                            Calendar.current.isDateInToday(date) ? .blue : .primary
                        )
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .onAppear {
            // Debug – remove later
            print("Fetched days:", days.count)
            days.forEach {
                print($0.date ?? "nil", $0.stepCount)
            }
        }
    }

    // MARK: - Helpers

    /// Returns Monday → Sunday dates for the current week
    private func currentWeekDates() -> [Date] {
        let calendar = Calendar(identifier: .iso8601)
        let startOfWeek = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        )!

        return (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: startOfWeek)
        }
    }

    /// Returns step count for a given date
    private func steps(for date: Date) -> Int {

        // Live steps for today
        if Calendar.current.isDateInToday(date) {
            return mainViewModel.healthManager.stepCount
        }

        // Past days from Core Data
        guard let day = days.first(where: {
            if let savedDate = $0.date {
                return Calendar.current.isDate(savedDate, inSameDayAs: date)
            }
            return false
        }) else {
            return 0
        }

        return Int(day.stepCount)
    }
}





