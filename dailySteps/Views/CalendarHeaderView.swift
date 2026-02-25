//
//  CalendarHeaderView.swift
//  dailySteps
//
//  Created by Andrea Monroy on 12/31/25.
//

import SwiftUI

struct CalendarHeaderView: View {
    //create an array that holds the days of the week
    let daysOfWeek = ["S","M","T","W","T","F","S"]
    //adding font to be able to pass it in when we call the view, so that the calendar view and the widget have different fonts
    var font: Font = .body
    
    var body: some View {
        HStack {
            ForEach(daysOfWeek, id: \.self) { dayOfWeek in
                Text(dayOfWeek)
                    .font(font)
                    .fontWeight(.black)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
            }
            
        }
    }
}

#Preview {
    CalendarHeaderView()
}
