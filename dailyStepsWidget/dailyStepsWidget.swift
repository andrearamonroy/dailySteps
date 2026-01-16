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
    let primary: Color
    let secondary: Color
}

func loadWidgetTheme() -> WidgetTheme {
    guard let defaults = UserDefaults(suiteName: "group.com.andrearamonroy.dailySteps") else {
        return WidgetTheme(primary: .blue, secondary: .mint)
    }

    let primaryRaw = defaults.string(forKey: "primaryColor") ?? "blue"
    let secondaryRaw = defaults.string(forKey: "secondaryColor") ?? "mint"

    return WidgetTheme(
        primary: PastelColor(rawValue: primaryRaw)?.color ?? PastelColor.blue.color,
        secondary: PastelColor(rawValue: secondaryRaw)?.color ?? PastelColor.mint.color
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
        CalendarEntry(date: Date(), configuration: ConfigurationAppIntent(), days: [], streak: 0, theme: WidgetTheme(primary: .blue, secondary: .mint))
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> CalendarEntry {
        
        //fetching from core data the old way

        do {
            let theme = loadWidgetTheme()
            let days = try viewContext.fetch(dayFetchRequest)
            let streak = StreakCalculator.calculate(days: days, maxGraceDays: graceDays)
            return  CalendarEntry(date: Date(), configuration: configuration, days: days, streak: streak, theme: theme)
        } catch {
            print("Widget failed to fetch days in the snapshot")
            return  CalendarEntry(date: Date(), configuration: configuration, days: [], streak: 0, theme: WidgetTheme(primary: .blue, secondary: .mint))
        }
        
        
      
        
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<CalendarEntry> {
      

        do {
            let theme = loadWidgetTheme()
           let days = try viewContext.fetch(dayFetchRequest)
            let streak = StreakCalculator.calculate(days: days, maxGraceDays: graceDays)
            
            let entry =  CalendarEntry(date: Date(), configuration: configuration, days: days, streak: streak, theme: theme)
            return Timeline(entries: [entry], policy: .atEnd)
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
}

struct dailyStepsWidgetEntryView : View {
    var entry: Provider.Entry
    let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        HStack {
            VStack {
                Text("\(entry.streak)")
                    .font(.system(size: 70, design: .rounded))
                    .bold()
                    .foregroundStyle(entry.theme.primary)
                
                Text("day streak")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
            }
            VStack {
                CalendarHeaderView(font: .caption2)

                CalendarGridView(days: entry.days, today: entry.date)
            }
            .padding(.leading)
        }
    }
}

struct dailyStepsWidget: Widget {
    let kind: String = "dailyStepsWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            dailyStepsWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Daily Steps Widget")
        .description("Track days you reach your step goal with streaks ⚡️⚡️ ")
        .supportedFamilies([.systemMedium])
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
    CalendarEntry(date: .now, configuration: .smiley, days: [], streak: 0, theme: WidgetTheme(primary: .blue, secondary: .mint) )
    CalendarEntry(date: .now, configuration: .starEyes, days: [], streak: 0, theme: WidgetTheme(primary: .blue, secondary: .mint))
}
