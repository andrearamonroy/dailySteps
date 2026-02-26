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

struct Provider: TimelineProvider {

    
    
    //using core data persistence container view context in the widget to display data
    private var viewContext: NSManagedObjectContext {
        PersistenceController.shared.container.viewContext
    }

    
    // Shared AppStorage for graceDays
    //including the group so that the widget has access to the grace days
    @AppStorage(
        "graceDays",
        store: UserDefaults(suiteName: "group.com.andrearamonroy.dailySteps")
    )
    var graceDays: Int = 0
    
    private func getCurrentStepCount() -> Int {
        guard let defaults = UserDefaults(suiteName: "group.com.andrearamonroy.dailySteps") else {
            print("❌ UserDefaults suite is NIL")
            return 0
        }
        let count = defaults.integer(forKey: "currentStepCount")
        print("✅ UserDefaults suite OK, stepCount = \(count)")
        return count
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
    
    func placeholder(in context: Context) -> CalendarEntry  {
        CalendarEntry(date: Date(),  days: [], streak: 0, theme: WidgetTheme(primary: BackgroundColor.aurora.color),                 stepCount: 0,
                      stepGoal: 100
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CalendarEntry) -> Void) {
        
        //fetching from core data the old way

       
            do {
                let theme = loadWidgetTheme()
                let days = try viewContext.fetch(dayFetchRequest)
                let streak = StreakCalculator.calculate(days: days, maxGraceDays: graceDays)
                let stepCount = getCurrentStepCount()
                let stepGoal = getCurrentGoal()
                completion(CalendarEntry(date: Date(), days: days, streak: streak, theme: theme, stepCount: stepCount, stepGoal: stepGoal))
            } catch {
                completion(CalendarEntry(date: Date(), days: [], streak: 0, theme: WidgetTheme(primary: BackgroundColor.aurora.color), stepCount: 0, stepGoal: 0))
            }
        
        
      
        
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<CalendarEntry>) -> Void) {
        do {
            let theme = loadWidgetTheme()
            let days = try viewContext.fetch(dayFetchRequest)
            let streak = StreakCalculator.calculate(days: days, maxGraceDays: graceDays)
            let stepCount = getCurrentStepCount()
            let stepGoal = getCurrentGoal()
            
            print("🔍 stepCount: \(stepCount)")
            print("🔍 stepGoal: \(stepGoal)")
            
            let entry = CalendarEntry(date: Date(), days: days, streak: streak, theme: theme, stepCount: stepCount, stepGoal: stepGoal)
            let midnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
            completion(Timeline(entries: [entry], policy: .after(midnight)))
        }catch {
            print("❌ Widget failed to fetch days")
            let fallback = CalendarEntry(
                date: Date(),
                days: [],
                streak: 0,
                theme: WidgetTheme(primary: BackgroundColor.aurora.color),
                stepCount: getCurrentStepCount(),
                stepGoal: getCurrentGoal()
            )
            completion(Timeline(entries: [fallback], policy: .atEnd))
        }
    }

//    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

struct CalendarEntry: TimelineEntry {
    let date: Date
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
                .containerBackground(for: .widget) {
                    entry.theme.primary
                }
        case .accessoryInline:
            InlineWidgetView(entry: entry)
        
        default:
            InlineWidgetView(entry: entry)
        }
    }
}

/*
 
 */




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
      
            
            VStack(alignment: .leading, spacing: 8) {
                // Header row
                HStack {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Streak pill
                    HStack(spacing: 3) {
                        Text("🔥")
                            .font(.system(size: 11))
                        Text("\(entry.streak)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.25))
                    .clipShape(Capsule())
                    .fixedSize()
                }
                
                Spacer()
                
                // Big step count
                Text(formatSteps(entry.stepCount))
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                
                // Goal subtitle
                Text("of \(formatSteps(entry.stepGoal))")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Track
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 8)
                        
                        // Fill
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: progress >= 1.0
                                        ? [Color.green.opacity(0.9), Color.mint]
                                        : [Color.white.opacity(0.9), Color.white.opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(geo.size.width * progress, progress > 0 ? 8 : 0), height: 8)
                            .shadow(color: .white.opacity(0.4), radius: 3, x: 0, y: 0)
                    }
                }
                .frame(height: 8)
                
                // Percentage
                HStack(spacing: 4) {
                    Text("\(progressPercent)%")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    if progress >= 1.0 {
                        Text("✓ Goal reached!")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            .padding(14)
        
    }
    
    private func formatSteps(_ steps: Int) -> String {
        if steps >= 1000 {
            let k = Double(steps) / 1000.0
            if k.truncatingRemainder(dividingBy: 1) == 0 {
                return "\(Int(k))k"
            }
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
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            dailyStepsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Daily Steps")
        .description("Your daily step count")
        .supportedFamilies([.accessoryInline, .systemSmall])
    }
}





/*
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
*/
#Preview(as: .systemMedium) {
    dailyStepsWidget()
    
} timeline: {
    CalendarEntry(date: .now, days: [], streak: 0, theme: WidgetTheme(primary: BackgroundColor.aurora.color), stepCount : 0, stepGoal: 0 )
    
}

// MARK: - Medium Widget
struct MediumWidgetView: View {
    let entry: CalendarEntry

    private var currentBackground: BackgroundColor {
        let colorString = UserDefaults(suiteName: "group.com.andrearamonroy.dailySteps")?
            .string(forKey: "backgroundColor") ?? BackgroundColor.aurora.rawValue
        return BackgroundColor(rawValue: colorString) ?? .aurora
    }

    var body : some View {}
}



