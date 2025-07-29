//
//  Date+Ext.swift
//  dailySteps
//
//  Created by Andrea on 5/4/25.
//

import Foundation


extension Date {

    var startOfMonth: Date {
        Calendar.current.dateInterval(of: .month, for: self)!.start
    }

    var endOfMonth: Date {
        Calendar.current.dateInterval(of: .month, for: self)!.end
    }

    var endOfDay: Date {
        Calendar.current.dateInterval(of: .day, for: self)!.end
    }

    var startOfPreviousMonth: Date {
        let dayInPreviousMonth = Calendar.current.date(byAdding: .month, value: -1, to: self)!
        return dayInPreviousMonth.startOfMonth
    }

    var startOfNextMonth: Date {
        let dayInNextMonth = Calendar.current.date(byAdding: .month, value: 1, to: self)!
        return dayInNextMonth.startOfMonth
    }

    var numberOfDaysInMonth: Int {
        // endOfMonth returns the 1st of next month at midnight.
        // An adjustment of -1 is necessary to get last day of current month
        let endDateAdjustment = Calendar.current.date(byAdding: .day, value: -1, to: self.endOfMonth)!
        return Calendar.current.component(.day, from: endDateAdjustment)
    }

    var dayInt: Int {
        Calendar.current.component(.day, from: self)
    }

    var monthInt: Int {
        Calendar.current.component(.month, from: self)
    }

    var monthFullName: String {
        self.formatted(.dateTime.month(.wide))
    }
    
    //prefix for calendar view
    //do you want to add previous days lets say new month starts on a tuesday
    //do you want to include the last day of the last month? ex. Monday 30 --in our case NO!
//    var startOfCalendarWithPrefixDays: Date {
//        let startOfMonthWeekday = Calendar.current.component(.weekday, from: startOfMonth)
//        let numberOfPrefixDays = startOfMonthWeekday - 1
//        let startDate = Calendar.current.date(byAdding: .day, value: -numberOfPrefixDays, to: startOfMonth)!
//        return startDate
//    }
    var startOfCalendarWithPrefixDays: Date {
        let start = self.startOfMonth
        let weekday = Calendar.current.component(.weekday, from: start)

        // In Calendar, Sunday = 1, Monday = 2, ..., Saturday = 7
        let daysToSubtract = (weekday + 5) % 7  // Converts Sunday-start to Monday-start
        return Calendar.current.date(byAdding: .day, value: -daysToSubtract, to: start)!
    }
    
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    var yesterday: Date {
        Calendar.current.date(byAdding: .day, value: -1, to: self.startOfDay)!
    }
    
    var nextDay: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: self.startOfDay)!
    }
}
