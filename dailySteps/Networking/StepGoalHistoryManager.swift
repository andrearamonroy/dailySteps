//
//  StepGoalHistoryManager.swift
//  dailySteps
//
//  Created by Andrea on 1/5/26.
//

import Foundation


struct StepGoalChange : Codable, Identifiable {
    let id : UUID
    let date : Date
    let stepGoal : Int
}


class StepGoalHistoryManager : ObservableObject {
    
    @Published private(set) var stepGoalHistory : [StepGoalChange] = []
    
    private let stepGoalHistoryKey = "stepGoalHistoryKey"
    
    
    //Add a new step goal change
    func addChange(goal: Int){
        let change = StepGoalChange(id: UUID(), date: Date(), stepGoal: goal)
        stepGoalHistory.append(change)
        
        persistHistory()
    }
    
    
    //save history to user deafults
    private func persistHistory(){
        do {
            let data = try JSONEncoder().encode(stepGoalHistory)
            UserDefaults.standard.set(data, forKey: stepGoalHistoryKey)
            
        } catch {
            print("failed to save step goal history : \(error)")
        }
    }
    
    
    //load history from user defaults
    private func loadHistory(){
        guard let data = UserDefaults.standard.data(forKey: stepGoalHistoryKey) else {
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode([StepGoalChange].self, from: data)
            stepGoalHistory = decoded
        } catch  {
            print("Failed to load step goal history : \(error)")
        }
    }
    
    //clear history
    func clearHistory(){
        stepGoalHistory.removeAll()
        UserDefaults.standard.removeObject(forKey: stepGoalHistoryKey)
    }
    
}
