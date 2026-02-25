//
//  dailyStepsWidget.swift
//  dailyStepsWidget
//
//  Created by Andrea Monroy on 12/30/25.
//

import WidgetKit
import SwiftUI
import CoreData


struct WidgetTheme {
    let primary: LinearGradient
}

func loadWidgetTheme() -> WidgetTheme {
    let defaults = UserDefaults(suiteName: "group.com.andrearamonroy.dailySteps")
    let raw = defaults?.string(forKey: "backgroundColor") ?? BackgroundColor.aurora.rawValue
    let gradient = BackgroundColor(rawValue: raw)?.color ?? BackgroundColor.aurora.color
    return WidgetTheme(primary: gradient)
}

struct Provider: AppIntentTimelineProvider {
    //using core data persistence container view context in the widget to display data
    let viewContext = PersistenceController.shared.container.viewContext

    
    // Shared AppStorage for graceDays
        @AppStorage(
            "graceDays",
            store: UserDefaults(suiteName: "group.com.yourapp.streak")
        )
        var graceDays: Int = 0
    
    private func getCurrentStepCount() -> Int {
        guard let defaults = UserDefaults(suiteName: "group.com.andrearamonroy.dailySteps") else { return 0 }
        
        // Check if the saved step count is from today
        let savedDate = defaults.object(forKey: "stepCountDate") as? Date
        let isToday = savedDate.map { Calendar.current.isDateInToday($0) } ?? false
        
        guard isToday else { return 0 } // new day → show 0 until first fetch
        return defaults.integer(forKey: "currentStepCount")
    }
    
    private func getCurrentGoal() -> Int {
        guard let defaults = UserDefaults(suiteName: "group.com.andrearamonroy.dailySteps") else { return 10_000 }
        let goal = defaults.integer(forKey: "stepGoal")
        return goal > 0 ? goal : 10_000 // fallback if never set
    }
    
    
    //fetch request to core data extracted as a variable since it is used in multiple places
    var dayFetchRequest: NSFetchRequest<Day> {
        //fetching from core data the old way
        let request = Day.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Day.date, ascending: true)]
        request.predicate = NSPredicate(format: "(date >= %@) AND (date <= %@)",
                                        Date().startOfCalendarWithPrefixDays as CVarArg,
                                        Date().endOfMonth as CVarArg)
        return request
    }
    
    func placeholder(in context: Context) -> CalendarEntry {
        CalendarEntry(date: Date(), configuration: ConfigurationAppIntent(), days: [], streak: 0, theme: WidgetTheme(primary: BackgroundColor.aurora.color),                 stepCount: 0,
                      stepGoal: 100
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> CalendarEntry {
        
        //fetching from core data the old way

        do {
            let theme = loadWidgetTheme()
            let days = try viewContext.fetch(dayFetchRequest)
            let streak = StreakCalculator.calculate(days: days, maxGraceDays: graceDays)
            let stepCount = getCurrentStepCount()
            let stepGoal = getCurrentGoal()
            return  CalendarEntry(date: Date(), configuration: configuration, days: days, streak: streak, theme: theme,  stepCount : stepCount, stepGoal: stepGoal )
        } catch {
            print("Widget failed to fetch days in the snapshot")
            return  CalendarEntry(date: Date(), configuration: configuration, days: [], streak: 0, theme:  WidgetTheme(primary: BackgroundColor.aurora.color) ,                 stepCount: 0, stepGoal: 0
            )
        }
        
        
      
        
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<CalendarEntry> {
      

        do {
            let theme = loadWidgetTheme()
           let days = try viewContext.fetch(dayFetchRequest)
            let streak = StreakCalculator.calculate(days: days, maxGraceDays: graceDays)
            let stepCount = getCurrentStepCount()
            let stepGoal = getCurrentGoal()
            
            
            let entry =  CalendarEntry(date: Date(), configuration: configuration, days: days, streak: streak, theme: theme,                stepCount: stepCount, stepGoal: stepGoal )
            
           
                    let midnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))

                    return Timeline(entries: [entry], policy: .after(midnight))

        } catch {
            print("Widget failed to fetch days in the snapshot")
            return Timeline(entries: [], policy: .after(.now.endOfDay))
        }

        
    }

//    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

struct CalendarEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let days : [Day]
    let streak : Int
    let theme: WidgetTheme
    let stepCount: Int
    let stepGoal: Int

}

struct dailyStepsWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
                .containerBackground(entry.theme.primary, for: .widget)
        case .accessoryInline:
            InlineWidgetView(entry: entry)
        default:
            InlineWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget
struct SmallWidgetView: View {
    let entry: CalendarEntry
    
    
    private var progress: Double {
        guard entry.stepGoal > 0 else { return 0 }
        return min(Double(entry.stepCount) / Double(entry.stepGoal), 1.0)
    }
    
    private var progressPercent: Int {
        Int(progress * 100)
    }
    
    var body: some View {
        ZStack {
            entry.theme.primary
                .ignoresSafeArea()
            
            VStack(spacing: 10) {
                
                // Progress Ring
                ZStack {
                    // Track
                    Circle()
                        .stroke(Color.black.opacity(0.1), lineWidth: 7)
                        .frame(width: 80, height: 80)
                    
                    // Fill
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            progress >= 1.0 ? Color.green : Color.black.opacity(0.45),
                            style: StrokeStyle(lineWidth: 7, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    // Center text
                    VStack(spacing: 1) {
                        Text(formatSteps(entry.stepCount))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.black.opacity(0.8))
                        Text("\(progressPercent)%")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.black.opacity(0.4))
                    }
                }
                
                // Streak row — flame + number side by side, "day streak" below
                VStack(spacing: 2) {
                    HStack(spacing: 4) {
                        Text("🔥")
                            .font(.system(size: 16))
                        Text("\(entry.streak)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.black.opacity(0.75))
                    }
                    Text("DAY STREAK")
                        .font(.system(size: 8, weight: .semibold))
                        .tracking(1.2)
                        .foregroundColor(.black.opacity(0.35))
                }
            }
            .padding(12)
        }
    }
    
    private func formatSteps(_ steps: Int) -> String {
        if steps >= 1000 {
            let k = Double(steps) / 1000.0
            return String(format: "%.1fk", k)
        }
        return "\(steps)"
    }
}



// MARK: - Inline Widget (Lock Screen)
struct InlineWidgetView: View {
    let entry: CalendarEntry
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "figure.walk")
                .font(.system(size: 12, weight: .semibold))
            Text(formatSteps(entry.stepCount))
                .font(.system(size: 14, weight: .bold, design: .rounded))
        }
    }
    
    private func formatSteps(_ steps: Int) -> String {
        if steps >= 10000 {
            let k = Double(steps) / 1000.0
            return String(format: "%.1fk", k)
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: steps)) ?? "\(steps)"
    }
}
struct dailyStepsWidget: Widget {
    let kind: String = "dailyStepsWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            dailyStepsWidgetEntryView(entry: entry)
               // .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Daily Steps")
        .description("Your daily step count")
        .supportedFamilies([.accessoryInline, .systemSmall])
    }
}

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🤩"
        return intent
    }
}

#Preview(as: .systemMedium) {
    dailyStepsWidget()
    
} timeline: {
    CalendarEntry(date: .now, configuration: .smiley, days: [], streak: 0, theme: WidgetTheme(primary: BackgroundColor.aurora.color), stepCount : 0, stepGoal: 0 )
    
}
