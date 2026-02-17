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
    let secondary: LinearGradient
}

func loadWidgetTheme() -> WidgetTheme {
    guard let defaults = UserDefaults(suiteName: "group.com.andrearamonroy.dailySteps") else {
        return WidgetTheme(
                    primary: BackgroundColor.aurora.color,
                    secondary: BackgroundColor.aurora.color
                )
    }

    let primaryRaw = defaults.string(forKey: "primaryColor") ?? "blue"
    let secondaryRaw = defaults.string(forKey: "secondaryColor") ?? "mint"

    return WidgetTheme(
        primary: BackgroundColor(rawValue: primaryRaw)?.color ?? BackgroundColor.aurora.color,
        secondary: BackgroundColor(rawValue: secondaryRaw)?.color ?? BackgroundColor.aurora.color
    )
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
            guard let defaults = UserDefaults(suiteName: "group.com.andrearamonroy.dailySteps") else {
                return 0
            }
            return defaults.integer(forKey: "currentStepCount")
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
        CalendarEntry(date: Date(), configuration: ConfigurationAppIntent(), days: [], streak: 0, theme:
                        WidgetTheme(
                            primary: BackgroundColor.aurora.color,
                            secondary: BackgroundColor.aurora.color,
                        ) ,                 stepCount: 0
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> CalendarEntry {
        
        //fetching from core data the old way

        do {
            let theme = loadWidgetTheme()
            let days = try viewContext.fetch(dayFetchRequest)
            let streak = StreakCalculator.calculate(days: days, maxGraceDays: graceDays)
            let stepCount = getCurrentStepCount()
            return  CalendarEntry(date: Date(), configuration: configuration, days: days, streak: streak, theme: theme,  stepCount : stepCount )
        } catch {
            print("Widget failed to fetch days in the snapshot")
            return  CalendarEntry(date: Date(), configuration: configuration, days: [], streak: 0, theme: WidgetTheme(
                primary: BackgroundColor.aurora.color,
                secondary: BackgroundColor.aurora.color
            ) ,                 stepCount: 0
            )
        }
        
        
      
        
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<CalendarEntry> {
      

        do {
            let theme = loadWidgetTheme()
           let days = try viewContext.fetch(dayFetchRequest)
            let streak = StreakCalculator.calculate(days: days, maxGraceDays: graceDays)
            let stepCount = getCurrentStepCount()
            
            
            
            let entry =  CalendarEntry(date: Date(), configuration: configuration, days: days, streak: streak, theme: theme,                stepCount: stepCount )
            
           
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

}

struct dailyStepsWidgetEntryView: View {
    var entry: Provider.Entry
    
    var body: some View {
        InlineWidgetView(entry: entry)
    }
}

// MARK: - Small Widget
struct SmallWidgetView: View {
    let entry: CalendarEntry
 
    
    var body: some View {
        ZStack {
          
            
            VStack(spacing: 8) {
                // Step count
               // Text("\(entry.stepCount)")
                Text("\(0)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.5)
                
                Text("steps")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Divider()
                    .padding(.horizontal)
                
                // Streak
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Text("0")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                
                Text("day streak")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
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
        .supportedFamilies([.accessoryInline])
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
    CalendarEntry(date: .now, configuration: .smiley, days: [], streak: 0, theme: WidgetTheme(
        primary: BackgroundColor.aurora.color,
        secondary: BackgroundColor.aurora.color
    ), stepCount : 0  )
    CalendarEntry(date: .now, configuration: .starEyes, days: [], streak: 0, theme:  WidgetTheme(
        primary: BackgroundColor.aurora.color,
        secondary: BackgroundColor.aurora.color
    ), stepCount : 0  )
}
