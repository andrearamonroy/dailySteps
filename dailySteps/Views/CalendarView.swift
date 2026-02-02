//
//  ContentView.swift
//  dailySteps
//
//  Created by Andrea on 4/20/25.
//
import SwiftUI
import CoreData
import CloudKit

struct CalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var cloudKitManager = CloudKitManager.shared
    
    @State private var allEnrollments: [EnrollmentWithChallenge] = []
    @State private var isLoadingChallenges = false
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Day.date, ascending: true)],
        predicate: NSPredicate(format: "(date >= %@) AND (date <= %@)",
                               Date().startOfCalendarWithPrefixDays as CVarArg,
                               Date().endOfMonth as CVarArg))
    private var days: FetchedResults<Day>
    
    var activeEnrollment: EnrollmentWithChallenge? {
        allEnrollments.first { $0.isActive }
    }
    
    var completedEnrollments: [(EnrollmentWithChallenge, Color)] {
        let colors: [Color] = [.blue, .purple, .orange, .pink, .green, .cyan, .indigo]
        
        return allEnrollments
            .filter { !$0.isActive && $0.endReason == "completed" }
            .enumerated()
            .map { (index, enrollment) in
                (enrollment, colors[index % colors.count])
            }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Active Challenge Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Active")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if isLoadingChallenges {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if let active = activeEnrollment {
                            ActiveChallengeCard(enrollmentData: active)
                        } else {
                            NoActiveChallengeCard()
                        }
                    }
                    .padding(.horizontal)
                    
                    // Past Challenges Section
                    if !completedEnrollments.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Past Challenges")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            VStack(spacing: 8) {
                                ForEach(completedEnrollments, id: \.0.enrollmentID) { item in
                                    PastChallengeRow(
                                        enrollmentData: item.0,
                                        color: item.1
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Calendar Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text(Date().formatted(.dateTime.month(.wide)))
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        CalendarHeaderView()
                        
                        TimelineView(.everyMinute) { context in
                            ColorCodedCalendarGrid(
                                days: Array(days),
                                today: context.date,
                                enrollments: allEnrollments,
                                completedWithColors: completedEnrollments
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if days.isEmpty {
                    createMonthDays(for: .now.startOfPreviousMonth)
                    createMonthDays(for: .now)
                } else if days.count < 10 {
                    createMonthDays(for: .now)
                }
                loadChallengeData()
            }
            .refreshable {
                loadChallengeData()
            }
        }
    }
    
    private func loadChallengeData() {
        isLoadingChallenges = true
        
        cloudKitManager.fetchAllEnrollmentsWithChallengeDetails { result in
            DispatchQueue.main.async {
                isLoadingChallenges = false
                
                switch result {
                case .success(let enrollments):
                    self.allEnrollments = enrollments
                    print("✅ Loaded \(enrollments.count) enrollments")
                    if let active = enrollments.first(where: { $0.isActive }) {
                        print("✅ Found active challenge: \(active.challengeName)")
                    }
                case .failure(let error):
                    print("❌ Error loading enrollments: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func createMonthDays(for date: Date) {
        for dayOffset in 0..<date.numberOfDaysInMonth {
            let newDay = Day(context: viewContext)
            newDay.date = Calendar.current.date(byAdding: .day, value: dayOffset, to: date.startOfMonth)
            newDay.didSteps = false
        }
        
        do {
            try viewContext.save()
            print("✅\(date.monthFullName) days created")
        } catch {
            print("Failed to save context")
        }
    }
}

// MARK: - Enrollment Data Model
struct EnrollmentWithChallenge: Identifiable {
    let id = UUID()
    let enrollmentID: String
    let challengeName: String
    let challengeID: String
    let startDate: Date
    let endDate: Date?
    let currentStreak: Int
    let totalDaysCompleted: Int
    let isActive: Bool
    let endReason: String?
    
    init(from enrollment: CKRecord, challenge: CKRecord) {
        self.enrollmentID = enrollment.recordID.recordName
        self.challengeName = challenge["name"] as? String ?? "Challenge"
        self.challengeID = challenge["challengeID"] as? String ?? ""
        self.startDate = enrollment["startDate"] as? Date ?? Date()
        self.endDate = enrollment["endedAt"] as? Date
        self.currentStreak = enrollment["currentStreak"] as? Int ?? 0
        self.totalDaysCompleted = enrollment["totalDaysCompleted"] as? Int ?? 0
        self.isActive = enrollment["isActive"] as? Bool ?? false
        self.endReason = enrollment["endReason"] as? String
    }
}

// MARK: - Active Challenge Card
struct ActiveChallengeCard: View {
    let enrollmentData: EnrollmentWithChallenge
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Text("🏃")
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(enrollmentData.challengeName)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 12) {
                    if enrollmentData.currentStreak > 0 {
                        Label("\(enrollmentData.currentStreak) day streak", systemImage: "flame.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    Label("Started \(enrollmentData.startDate.formatted(.dateTime.month().day()))", systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - No Active Challenge Card
struct NoActiveChallengeCard: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("No active challenge")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Visit the Challenges tab to get started!")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Past Challenge Row
struct PastChallengeRow: View {
    let enrollmentData: EnrollmentWithChallenge
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            // Color indicator
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 4, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(enrollmentData.challengeName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 8) {
                    if let endDate = enrollmentData.endDate {
                        Text("\(enrollmentData.startDate.formatted(.dateTime.month().day())) - \(endDate.formatted(.dateTime.month().day()))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text("\(enrollmentData.totalDaysCompleted) days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Color Coded Calendar Grid
struct ColorCodedCalendarGrid: View {
    let days: [Day]
    let today: Date
    let enrollments: [EnrollmentWithChallenge]
    let completedWithColors: [(EnrollmentWithChallenge, Color)]
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(days) { day in
                if let date = day.date {
                    if date.monthInt != Date().monthInt {
                        Text("")
                    } else {
                        ColorCodedDayCell(
                            day: day,
                            isToday: Calendar.current.isDate(date, inSameDayAs: today),
                            completedChallenges: completedWithColors,
                            activeEnrollment: enrollments.first { $0.isActive }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Color Coded Day Cell
struct ColorCodedDayCell: View {
    let day: Day
    let isToday: Bool
    let completedChallenges: [(EnrollmentWithChallenge, Color)]
    let activeEnrollment: EnrollmentWithChallenge?
    
    var challengeColorForDay: Color? {
        guard let date = day.date else { return nil }
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        
        // Check active challenge first
        if let active = activeEnrollment {
            let challengeStart = calendar.startOfDay(for: active.startDate)
            if dayStart >= challengeStart {
                return Color.blue.opacity(0.5) // Active challenge color
            }
        }
        
        // Check completed challenges
        for (enrollment, color) in completedChallenges {
            guard let endDate = enrollment.endDate else { continue }
            
            let challengeStart = calendar.startOfDay(for: enrollment.startDate)
            let challengeEnd = calendar.startOfDay(for: endDate)
            
            if dayStart >= challengeStart && dayStart <= challengeEnd {
                return color
            }
        }
        
        return nil
    }
    
    var body: some View {
        ZStack {
            // Background color for challenge period
            if let color = challengeColorForDay {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.3))
            }
            
            // Green circle for completed step goal
            if day.didSteps {
                Circle()
                    .fill(Color.green)
                    .padding(8)
            }
            
            // Day number
            Text(day.date?.formatted(.dateTime.day()) ?? "")
                .font(.system(size: 16, weight: day.didSteps ? .bold : .regular))
                .foregroundStyle(foregroundColor)
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isToday ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
    
    var foregroundColor: Color {
        if day.didSteps {
            return .white
        } else if isToday {
            return .blue
        } else if challengeColorForDay != nil {
            return .primary
        } else {
            return .secondary
        }
    }
}

#Preview {
    CalendarView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
