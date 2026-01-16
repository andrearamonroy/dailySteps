//
//  CalendarGridView.swift
//  dailySteps
//
//  Created by Andrea on 1/14/26.
//

import SwiftUI

import SwiftUI

struct CalendarGridView: View {
    let days: [Day]
    let today: Date
    let columns: [GridItem]
    
    init(days: [Day], today: Date = Date(), columns: [GridItem]? = nil) {
        self.days = days
        self.today = today
        self.columns = columns ?? Array(repeating: GridItem(.flexible()), count: 7)
    }
    
    var body: some View {
        LazyVGrid(columns: columns) {
            ForEach(days) { day in
                if day.date!.monthInt != today.monthInt {
                    Text("")
                } else {
                    let isToday = Calendar.current.isDate(day.date!, inSameDayAs: today)
                    
                    Text(day.date!.formatted(.dateTime.day()))
                        .fontWeight(.bold)
                        .foregroundStyle(day.didSteps ? .circlePink : .secondary)
                        .frame(maxWidth: .infinity, minHeight: 20)
                        .background(
                            Circle()
                                .foregroundStyle(backgroundColor(isToday: isToday, didSteps: day.didSteps))
                        )
                }
            }
        }
    }
    
    private func backgroundColor(isToday: Bool, didSteps: Bool) -> Color {
        if didSteps {
            return .circlePink.opacity(0.4) //pink if completed
        } else if isToday {
            return .gray.opacity(0.25) //gray for today's date
        } else {
            return .clear //clear nothing happened
        }
    }
}


/* old
 
 @ViewBuilder
 func calendarGrid(today: Date) -> some View {
     LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
         ForEach(days) { day in

             if day.date!.monthInt != today.monthInt {
                 Text("")
             } else {
                 let isToday = Calendar.current.isDate(day.date!, inSameDayAs: today)

                 Text(day.date!.formatted(.dateTime.day()))
                     .fontWeight(.bold)
                     .foregroundStyle(day.didSteps ? .circlePink : .secondary)
                     .frame(maxWidth: .infinity, minHeight: 80)
                     .background(
                         Circle()
                             .foregroundStyle(backgroundColor(isToday: isToday, didSteps: day.didSteps))
                     )
             }
         }
     }
 }

 
 func backgroundColor(isToday: Bool, didSteps: Bool) -> Color {
     if didSteps {
         return .circlePink.opacity(0.4)      // overrides today
     } else if isToday {
         return .gray.opacity(0.25)           // today highlight
     } else {
         return .clear
     }
 }
 
 */
