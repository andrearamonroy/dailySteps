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
                let calendar = Calendar.current
                let currentMonthDays = days.filter {
                    guard let date = $0.date else { return false }
                    return calendar.isDate(date, equalTo: .now, toGranularity: .month)
                }
                
                // ✅ Check for full month count, not just isEmpty
                if currentMonthDays.count < Date().numberOfDaysInMonth {
                    print("📅 Only \(currentMonthDays.count)/\(Date().numberOfDaysInMonth) days found — rebuilding month")
                    
                    // ✅ Delete incomplete days first to avoid duplicates
                    currentMonthDays.forEach { viewContext.delete($0) }
                    
                   // createMonthDays(for: .now.startOfPreviousMonth)
                    createMonthDays(for: .now)
                    
                    try? viewContext.save()
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




// MARK: - Calendar Grid (widget-safe version)
struct ColorCodedCalendarGrid: View {
    let days: [Day]
    let today: Date
    var compact: Bool = false

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
                            isToday: Calendar.current.isDate(date, inSameDayAs: today),
                            compact: compact
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
    var compact: Bool = false

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                if day.didSteps {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 36, height: 36)
                }

                Text(day.date?.formatted(.dateTime.day()) ?? "")
                    .font(.system(size: 16, weight: day.didSteps ? .bold : .regular))
                    .foregroundStyle(foregroundColor)
            }
            .frame(width: 36, height: 36)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isToday ? Color.blue : Color.clear, lineWidth: 2)
            )
            // Only show step count in non-compact mode
                  if !compact {
                      Text(formatSteps(Int(day.stepCount)))
                          .font(.system(size: 11, weight: .medium))
                          .foregroundColor(day.didSteps ? .green : .secondary)
                          .lineLimit(1)
                  }
        }
        .frame(maxWidth: .infinity, minHeight: 54)
    }

    var foregroundColor: Color {
        if day.didSteps { return .white }
        if isToday { return .blue }
        return .secondary
    }

    private func formatSteps(_ steps: Int) -> String {
        switch steps {
        case 0:
            return ""
        case 1_000..<10_000:
            let value = Double(steps) / 1000.0
            return value.truncatingRemainder(dividingBy: 1) == 0
                ? "\(Int(value))k"
                : String(format: "%.1fk", value)
        case 10_000...:
            let value = Double(steps) / 1000.0
            return value.truncatingRemainder(dividingBy: 1) == 0
                ? "\(Int(value))k"
                : String(format: "%.1fk", value)
        default:
            return "\(steps)"
        }
    }
}

#Preview {
    CalendarView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
