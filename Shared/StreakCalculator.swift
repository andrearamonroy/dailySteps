//
//  StreakCalculator.swift
//  dailySteps
//
//  Created by Andrea on 1/14/26.
//

import Foundation


enum StreakCalculator {

    static func calculate(
        days: [Day],
        maxGraceDays: Int,
        today: Date = Date()
    ) -> Int {

        guard !days.isEmpty else { return 0 }

        let todayInt = today.dayInt

        let nonFutureDays = days
            .filter { $0.date!.dayInt <= todayInt }
            .sorted { $0.date!.dayInt < $1.date!.dayInt }

        var streakCount = 0
        var missedDays = 0

        for day in nonFutureDays.reversed() {
            guard let dayInt = day.date?.dayInt else { continue }

            if day.didSteps {
                streakCount += 1
            } else {
                // Allow current day to be incomplete
                if dayInt == todayInt {
                    continue
                }

                missedDays += 1
                if missedDays > maxGraceDays {
                    break
                }
            }
        }

        return streakCount
    }
}
/* old streak func
func calculateStreakValue(maxGraceDays: Int) -> Int {
    guard !days.isEmpty else { return 0 }

    let todayInt = Date().dayInt

    let nonFutureDays = days
        .filter { $0.date!.dayInt <= todayInt }
        .sorted { $0.date!.dayInt < $1.date!.dayInt }

    var streakCount = 0
    var missedDays = 0

    for day in nonFutureDays.reversed() {
        if day.didSteps {
            streakCount += 1
        } else {
            // Skip today if we are still on the current day
            if day.date!.dayInt == todayInt {
                continue
            }

            missedDays += 1

            if missedDays > maxGraceDays {
                break
            }
        }
    }

    return streakCount
}
*/
