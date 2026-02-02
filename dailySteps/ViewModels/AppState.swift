//
//  AppState.swift
//  dailySteps
//
//  Created by Andrea on 1/28/26.
//

import Foundation

class AppState: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var shouldNavigateToStepView = false
}
