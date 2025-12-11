//
//  ListView.swift
//  dailySteps
//
//  Created by Andrea Monroy on 12/1/25.
//

import SwiftUI

enum Weekday : String, CaseIterable, Identifiable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday
    
    
    var id : Self {self}
    
    var displayName : String {
        switch self {
        case .monday: return "Every Monday"
        case .tuesday: return "Every Tuesday"
        case .wednesday: return "Every Wednesday"
        case .thursday: return "Every Thursday"
        case .friday: return "Every Friday"
        case .saturday: return "Every Saturday"
        case .sunday: return "Every Sunday"
        }
    }
    
    var shortName : String {
        switch self {
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        case .sunday: return "Sun"
        }
    }
}

struct Habit: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var days: Set<Weekday>
}


struct HabitsListView: View {
    @State private var habits : [Habit] = []
    @State private var isPresentingHabitView = false
    @State private var selectedHabit: Habit? = nil
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 5) {
                    if habits.isEmpty {
                        Button {
                            selectedHabit = Habit(title: "Walk for 20 mins", days: [.friday])
                        } label: {
                            HabitRowView(habit: Habit(title: "Walk for 20 mins", days: [.friday]))
                        }
                        .buttonStyle(.plain)
       
                    } else {
                        ForEach(habits) { habit in
                            
                            Button {
                                selectedHabit = habit
                            } label: {
                                HabitRowView(habit: habit)
                            }
                            .buttonStyle(.plain )

                                
                        }
                    }
                }
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingHabitView = true
                    } label: {
                        Image(systemName: "plus")
                    }

                }
            }
            
            .navigationDestination(isPresented: $isPresentingHabitView) {
                AddHabitView(habits: $habits)
            }
            .navigationDestination(item: $selectedHabit) { habit in
                EmptyView()
            }
        
        }
    }
}

#Preview {
    HabitsListView()
}

struct HabitRowView : View {
    
    let habit : Habit
    
    var body : some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.gray))
            
            
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(.headline)
                
                if !habit.days.isEmpty {
                    Text(habit.days
                        .sorted { $0.rawValue < $1.rawValue }
                        .map { $0.shortName }
                        .joined(separator: ", ")
                    )
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, minHeight: 60)
        .padding(.vertical, 4)
        
    }
}

#Preview {
    HabitRowView(habit: Habit(title: "Walk", days:  [.friday] ))
}

struct AddHabitView: View {
    @Binding var habits: [Habit]
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var selectedDays : Set<Weekday> = []
    
    var body: some View {
        
        Form {
            
            Section("Title") {
                TextField("Enter title: ", text: $title)}
            
            Section("Repeat") {
                NavigationLink {
                    RepeatDaysView(selectedDays: $selectedDays)
                } label: {
                    HStack {
                        Text("Repeat")
                        Spacer()
                        if !selectedDays.isEmpty {
                            Text(selectedDays
                                .sorted { $0.rawValue < $1.rawValue }
                                .map { $0.shortName }
                                .joined(separator: ", ")
                            )
                            .foregroundColor(.secondary)
                        } else {
                            Text("Never")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
                    
        }
        
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                }

            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    let habit = Habit(title: title, days: selectedDays)
                    habits.append(habit)
                    dismiss()
                } label: {
                    Text("Save")
                }
                
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)

            }
        
        }
        
        
    }
}

#Preview {
    AddHabitView(habits: .constant([
        Habit(title: "Walk", days: [.friday]),
        Habit(title: "Read", days: [.monday, .wednesday])
    ]))
}

struct RepeatDaysView: View {
    @Binding var selectedDays: Set<Weekday>
    
    var body: some View {
        List{
            ForEach(Weekday.allCases){ day in
            
                Button {
                    toggle(day)
                } label: {
                    HStack {
                        Text(day.displayName)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        if selectedDays.contains(day) {
                            Image(systemName: "checkmark")
                        }
                    }
                }

                
            }
        }
        
   
    }
    
    private func toggle(_ day : Weekday) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }
}

#Preview {
    RepeatDaysView(selectedDays: .constant([.friday]))
}
