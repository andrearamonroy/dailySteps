//
//  dailyStepsWidgetBundle.swift
//  dailyStepsWidget
//
//  Created by Andrea Monroy on 12/30/25.
//

import WidgetKit
import SwiftUI

@main
struct dailyStepsWidgetBundle: WidgetBundle {
    var body: some Widget {
        dailyStepsWidget()
        dailyStepsWidgetControl()
        dailyStepsWidgetLiveActivity()
    }
}
