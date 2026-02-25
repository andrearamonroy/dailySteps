//
//  CalendarView.swift
//  dailySteps
//
//  Created by Andrea on 2/24/26.
//

import SwiftUI
import CoreData

struct CalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Day.date, ascending: true)],
        predicate: NSPredicate(format: "(date >= %@) AND (date <= %@)",
                               Date().startOfCalendarWithPrefixDays as CVarArg,
                               Date().endOfMonth as CVarArg))
    private var days: FetchedResults<Day>

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(Date().formatted(.dateTime.month(.wide)))
                        .font(.title2)
                        .fontWeight(.bold)

                    CalendarHeaderView()

                    TimelineView(.everyMinute) { context in
                        ColorCodedCalendarGrid(
                            days: Array(days),
                            today: context.date
                        )
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if days.isEmpty {
                    createMonthDays(for: .now.startOfPreviousMonth)
                    createMonthDays(for: .now)
                } else if days.count < 10 {
                    createMonthDays(for: .now)
                }
            }
        }
    }

    func createMonthDays(for date: Date) {
        for dayOffset in 0..<date.numberOfDaysInMonth {
            let newDay = Day(context: viewContext)
            newDay.date = Calendar.current.date(byAdding: .day, value: dayOffset, to: date.startOfMonth)
            newDay.didSteps = false
        }
        do {
            try viewContext.save()
            print("✅ \(date.monthFullName) days created")
        } catch {
            print("❌ Failed to save context")
        }
    }
}



// MARK: - Calendar Grid
// MARK: - Calendar Grid (widget-safe version)
struct ColorCodedCalendarGrid: View {
    let days: [Day]
    let today: Date

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(days) { day in
                if let date = day.date {
                    if date.monthInt != today.monthInt {  // use today not Date()
                        Text("")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    } else {
                        DayCell(
                            day: day,
                            isToday: Calendar.current.isDate(date, inSameDayAs: today)
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Day Cell
struct DayCell: View {
    let day: Day
    let isToday: Bool

    var body: some View {
        ZStack {
            if day.didSteps {
                Circle()
                    .fill(Color.green)
            }

            Text(day.date?.formatted(.dateTime.day()) ?? "")
                .font(.system(size: 16, weight: day.didSteps ? .bold : .regular))
                .foregroundStyle(foregroundColor)
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isToday ? Color.blue : Color.clear, lineWidth: 2)
        )
    }

    var foregroundColor: Color {
        if day.didSteps { return .white }
        if isToday { return .blue }
        return .secondary
    }
}

#Preview {
    CalendarView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
