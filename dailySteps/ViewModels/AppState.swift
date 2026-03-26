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
    private let defaults = UserDefaults(suiteName: "group.com.andrearamonroy.dailySteps")!

    @Published var showChallengeCompletedOverlay: Bool {
        didSet { defaults.set(showChallengeCompletedOverlay, forKey: "showChallengeCompletedOverlay") }
    }

    @Published var showBadgeSpotlight: Bool {
        didSet { defaults.set(showBadgeSpotlight, forKey: "showBadgeSpotlight") }
    }

    @Published var completedChallengeName: String {
        didSet { defaults.set(completedChallengeName, forKey: "completedChallengeName") }
    }

    @Published var completedChallengeIconName: String {
        didSet { defaults.set(completedChallengeIconName, forKey: "completedChallengeIconName") }
    }

    @Published var completedChallengeDays: Int {
        didSet { defaults.set(completedChallengeDays, forKey: "completedChallengeDays") }
    }

    @Published var completedChallengeSteps: Int {
        didSet { defaults.set(completedChallengeSteps, forKey: "completedChallengeSteps") }
    }
    
    init() {
        let defaults = UserDefaults(suiteName: "group.com.andrearamonroy.dailySteps")!
        
        self.showChallengeCompletedOverlay = defaults.bool(forKey: "showChallengeCompletedOverlay")
        self.showBadgeSpotlight = defaults.bool(forKey: "showBadgeSpotlight")
        self.completedChallengeName = defaults.string(forKey: "completedChallengeName") ?? ""
        self.completedChallengeIconName = defaults.string(forKey: "completedChallengeIconName") ?? ""
        self.completedChallengeDays = defaults.integer(forKey: "completedChallengeDays")
        self.completedChallengeSteps = defaults.integer(forKey: "completedChallengeSteps")
        
    }
}
