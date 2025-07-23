//
//  HomeView.swift
//  dailySteps
//
//  Created by Andrea Monroy on 7/23/25.
//
import SwiftUI

struct HomeView: View {
    @StateObject private var mainViewModel = MainViewModel()
    
    var body: some View {
        VStack {
            Text("Steps today")
                .font(.largeTitle)
                .bold()
            Text("\(Int(mainViewModel.steps)) steps")
                            .font(.title)

            if mainViewModel.steps >= 1000 {
                Text("Goal Reached")
                    .foregroundStyle(.green)
            } else {
                Text( "Keep going")
                    .foregroundStyle(.orange)
            }

        }
    }
}

#Preview {
    HomeView()
}
