//
//  dailyStepsWidget.swift
//  dailyStepsWidget
//
//  Created by Andrea Monroy on 12/30/25.
//

import WidgetKit
import SwiftUI
import CoreData

struct Provider: AppIntentTimelineProvider {
    //using core data persistence container view context in the widget to display data
    let viewContext = PersistenceController.shared.container.viewContext
    
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
        CalendarEntry(date: Date(), configuration: ConfigurationAppIntent(), days: [])
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> CalendarEntry {
        
        //fetching from core data the old way

        do{
            let days = try viewContext.fetch(dayFetchRequest)
            return  CalendarEntry(date: Date(), configuration: configuration, days: days)
        } catch {
            print("Widget failed to fetch days in the snapshot")
            return  CalendarEntry(date: Date(), configuration: configuration, days: [])
        }
        
        
      
        
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<CalendarEntry> {
      

        do {
           let days = try viewContext.fetch(dayFetchRequest)
            let entry =  CalendarEntry(date: Date(), configuration: configuration, days: days)
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
}

struct dailyStepsWidgetEntryView : View {
    var entry: Provider.Entry
    let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        HStack {
            VStack {
                Text("\(calculateStreakValue())")
                    .font(.system(size: 70, design: .rounded))
                    .bold()
                    .foregroundStyle(.red)
                
                Text("day streak")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
            }
            VStack {
                CalendarHeaderView(font: .caption2)
                
                LazyVGrid(columns: columns, spacing: 7) {
                    ForEach(entry.days) { day in
                        if day.date!.monthInt != Date().monthInt {
                            Text("")
                        } else {
                            Text(day.date!.formatted(.dateTime.day()))
                                .font(.caption2)
                                .bold()
                                .frame(maxWidth: .infinity)
                                .foregroundStyle(day.didSteps ? .pink : .secondary)
                                .background(
                                    Circle()
                                        .foregroundStyle(.pink.opacity(day.didSteps ? 0.4 : 0.0))
                                        .scaleEffect(1.5)
                                )
                        }
                    }
                }
            }
            .padding(.leading)
        }
    }
    
    func calculateStreakValue() -> Int {
        //days is empty return 0 for the streak
        guard !entry.days.isEmpty else {return 0}
        
        let nonFutureDays = entry.days.filter { $0.date!.dayInt <= Date().dayInt }
        
        var streakCount = 0
        
        for day in nonFutureDays.reversed() {
            if day.didSteps {
                streakCount += 1
            } else {
                //this checks if the date is not today then break
                // if we are still on the same day then don't break the streak
                if day.date!.dayInt != Date().dayInt {
                    break
                }
             
            }
        }
        
        
       return streakCount
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
    CalendarEntry(date: .now, configuration: .smiley, days: [])
    CalendarEntry(date: .now, configuration: .starEyes, days: [])
}
