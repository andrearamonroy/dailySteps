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
    @Published var dismissChallengeListView = false

    //for confetti view
    @Published var showChallengeCompletedOverlay = false
    @Published var showBadgeSpotlight = false
    @Published var completedChallengeName: String = ""
    @Published var completedChallengeIconName: String = ""
    @Published var completedChallengeDays: Int = 0
    @Published var completedChallengeSteps: Int = 0
}
