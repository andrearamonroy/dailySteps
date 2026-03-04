import SwiftUI
import Foundation
import CoreData

//MARK: BADGES VIEW ORIGINAL -- AND WORKING VIEW

struct BadgesView: View {
    @EnvironmentObject var appState: AppState
    @State private var completedBadges: [EnrollmentWithChallenge] = []
    @State private var isLoading = false
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var hasLoadedOnce = false
    @State private var selectedTab: Int = 0  // 0 = Badges, 1 = Calendar
    @State private var sortNewestFirst = true
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Day.date, ascending: true)],
        predicate: NSPredicate(format: "(date >= %@) AND (date <= %@)",
                               Date().startOfCalendarWithPrefixDays as CVarArg,
                               Date().endOfMonth as CVarArg))
    private var days: FetchedResults<Day>
    
    private var sortedBadges: [EnrollmentWithChallenge] {
        completedBadges.sorted {
            guard let a = $0.completedAt, let b = $1.completedAt else { return false }
            return sortNewestFirst ? a > b : a < b
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Segmented Control
                    Picker("View", selection: $selectedTab) {
                        Text("Badges").tag(0)
                        Text("Calendar").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    // Content
                    if selectedTab == 1 {
                        ScrollView {
                            VStack(spacing: 0) {
                                HStack(spacing: 12) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(LinearGradient(
                                            colors: [Color(red: 0.45, green: 0.55, blue: 1.0), Color(red: 0.75, green: 0.45, blue: 1.0)],
                                            startPoint: .top, endPoint: .bottom
                                        ))
                                        .frame(width: 5, height: 36)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Personal Goal Tracker")
                                            .font(.system(size: 20, weight: .bold, design: .rounded))
                                            .foregroundColor(Color(.label))
                                        Text("Your monthly progress")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                                .padding(.bottom, 8)
                                
                                CalendarView()
                                    .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(16)
                                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                                    .padding(16)
                            }
                        }
                    } else {
                        ScrollView {
                            VStack {
                                if isLoading {
                                    ProgressView("Loading badges...")
                                } else if completedBadges.isEmpty {
                                    VStack(spacing: 24) {
                                        ZStack {
                                            Circle()
                                                .fill(
                                                    LinearGradient(
                                                        colors: [
                                                            Color(red: 0.45, green: 0.55, blue: 1.0).opacity(0.15),
                                                            Color(red: 0.75, green: 0.45, blue: 1.0).opacity(0.15)
                                                        ],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .frame(width: 110, height: 110)
                                            Image(systemName: "rosette")
                                                .font(.system(size: 48))
                                                .foregroundStyle(
                                                    LinearGradient(
                                                        colors: [
                                                            Color(red: 0.45, green: 0.55, blue: 1.0),
                                                            Color(red: 0.75, green: 0.45, blue: 1.0)
                                                        ],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                        }
                                        .padding(.top, 8)
                                        
                                        VStack(spacing: 8) {
                                            Text("No Badges Yet")
                                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                                .foregroundColor(Color(.label))
                                            Text("Enroll in a challenge and\nearn your first badge!")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                                .multilineTextAlignment(.center)
                                        }
                                        
                                        Button(action: {
                                            appState.selectedTab = 2
                                        }) {
                                            HStack(spacing: 6) {
                                                Image(systemName: "trophy.fill")
                                                    .font(.system(size: 14, weight: .semibold))
                                                Text("Browse Challenges")
                                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                            }
                                            .foregroundColor(.white)
                                            .padding(.vertical, 12)
                                            .padding(.horizontal, 24)
                                            .background(
                                                LinearGradient(
                                                    colors: [
                                                        Color(red: 0.45, green: 0.55, blue: 1.0),
                                                        Color(red: 0.75, green: 0.45, blue: 1.0)
                                                    ],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .clipShape(Capsule())
                                            .shadow(
                                                color: Color(red: 0.55, green: 0.45, blue: 1.0).opacity(0.35),
                                                radius: 10, x: 0, y: 4
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .padding(.bottom, 8)
                                    }
                                    .padding(.horizontal, 40)
                                    .padding(.vertical, 40)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color(.systemBackground))
                                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                                    )
                                    .padding(.horizontal, 24)
                                    .padding(.top, 16)
                                } else {
                                    VStack(spacing: 20) {
                                        HStack(spacing: 20) {
                                            StatBadge(
                                                icon: "trophy.fill",
                                                value: "\(completedBadges.count)",
                                                label: "Badges",
                                                color: .orange
                                            )
                                            StatBadge(
                                                icon: "flame.fill",
                                                value: "\(totalDaysCompleted)",
                                                label: "Days",
                                                color: .red
                                            )
                                        }
                                        .padding(.horizontal)
                                        .padding(.top, 8)
                                        
                                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 16) {
                                            ForEach(sortedBadges, id: \.enrollmentID) { badge in
                                                BadgeCard(badge: badge)
                                            }
                                        }
                                        .padding()
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(selectedTab == 0 ? "Badges" : "Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .id(selectedTab)
            .onAppear {
                
                
                
                if !hasLoadedOnce {
                    loadBadges()
                    hasLoadedOnce = true
                }
                
                print("days: Days fetched: \(days.count)")
                print("days: startOfCalendarWithPrefixDays: \(Date().startOfCalendarWithPrefixDays)")
                print("days: endOfMonth: \(Date().endOfMonth)")
                print("days: startOfMonth: \(Date().startOfMonth)")
                print("days: numberOfDaysInMonth: \(Date().numberOfDaysInMonth)")
            }
        
            .toolbar {
                //only show if there's badges
                if selectedTab == 0 && !completedBadges.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                sortNewestFirst.toggle()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: sortNewestFirst ? "arrow.down" : "arrow.up")
                                    .font(.caption)
                                Text(sortNewestFirst ? "New" : "Old")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                         
                            .background(Color(.systemGray6).opacity(0.1))
                            .foregroundColor(.blue)
                        }
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ChallengeCompleted"))) { _ in
                hasLoadedOnce = false
                loadBadges()
            }
        }
    }
    
    private var totalDaysCompleted: Int {
        completedBadges.reduce(0) { $0 + $1.duration }
    }
    
    private func loadBadges() {
        isLoading = true
        CloudKitManager.shared.fetchAllEnrollmentsWithChallengeDetails { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let enrollments):
                    self.completedBadges = enrollments
                        .filter { $0.completedAt != nil }
                        .sorted { $0.completedAt! > $1.completedAt! }
                    print("✅ Loaded \(self.completedBadges.count) badges")
                case .failure(let error):
                    print("❌ Error loading badges: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview("Empty State") {
    BadgesView()
        .environmentObject(AppState())
}

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

//MARK: WORKING BADGE CARD
struct BadgeCard1: View {
    let badge: EnrollmentWithChallenge
    
    var body: some View {
        VStack(spacing: 14) {
            // Badge icon with gradient background
            Image(badge.challengeIconName)
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .padding(.top, 8)
            
            VStack(spacing: 6) {
                Text(badge.challengeName)
                    .font(.system(size: 16, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                
                // Duration badge
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text("\(badge.duration) day\(badge.duration > 1 ? "s" : "")")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
            }
            
            Divider()
                .padding(.horizontal, 8)
            
            VStack(spacing: 6) {
                // Steps per day
                HStack(spacing: 4) {
                    Image(systemName: "figure.walk")
                        .font(.caption)
                    Text("\(formatSteps(badge.targetSteps))/day")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.secondary)
                
                // Completion date
                if let completedDate = badge.completedAt {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text(formatDate(completedDate))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
    
    private var gradientColors: [Color] {
        // Different gradient based on duration
        switch badge.duration {
        case 1...3:
            return [.green, .mint]
        case 4...7:
            return [.blue, .cyan]
        case 8...14:
            return [.purple, .pink]
        default:
            return [.orange, .red]
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatSteps(_ steps: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: steps)) ?? "\(steps)"
    }
}

struct BadgeCard: View {
    let badge: EnrollmentWithChallenge
    @State private var isFlipped = false

    var body: some View {
        ZStack {
            cardFront
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))

            cardBack
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
        }
        .frame(height: 220)
        .onTapGesture {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isFlipped.toggle()
            }
        }
    }

    // MARK: - Front

    private var cardFront: some View {
        VStack(spacing: 0) {
            // Gradient header with icon
            ZStack {
                badge.challengeCardGradient
                Image(badge.challengeIconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 54, height: 54)
            }
            .frame(height: 110)

            // White body
            VStack(alignment: .leading, spacing: 4) {
                Text("COMPLETED")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(accentColor)

                Text(badge.challengeName)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                HStack {
                    Text("\(badge.duration) day\(badge.duration == 1 ? "" : "s")")
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(accentColor.opacity(0.1))
                        .foregroundColor(accentColor)
                        .clipShape(Capsule())

                    Spacer()

                    if let completed = badge.completedAt {
                        Text(shortDate(completed))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(minHeight: 115) 
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.systemGray5), lineWidth: 1))
    }

    // MARK: - Back

    private var cardBack: some View {
        VStack(spacing: 0) {
            // Thin color strip
            badge.challengeCardGradient
                .frame(height: 5)

            VStack(spacing: 0) {
                // Title row
                HStack(spacing: 8) {
                    Image(badge.challengeIconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                    Text(badge.challengeName)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 8)

                Divider().padding(.horizontal, 12)

                // Stats
                VStack(spacing: 7) {
                    statRow(label: "Days Completed", value: "\(badge.duration) / \(badge.duration)")
                    statRow(label: "Steps Per Day",  value: formatSteps(badge.targetSteps))
                    statRow(label: "Total Steps",    value: formatSteps(badge.targetSteps * badge.duration))
                    statRow(label: "Started", value: mediumDate(badge.startDate))
                    statRow(label: "Ended",   value: badge.completedAt.map { mediumDate($0) } ?? "—")
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)

                Spacer()

                // Progress bar
                VStack(spacing: 4) {
                    HStack {
                        Text("Completion")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("100%")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(accentColor)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(.systemGray5))
                                .frame(height: 5)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(badge.challengeCardGradient)
                                .frame(width: geo.size.width, height: 5)
                        }
                    }
                    .frame(height: 5)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            }
            .frame(maxHeight: .infinity)
            .background(Color(.systemBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.systemGray5), lineWidth: 1))
    }

    // MARK: - Helpers

    @ViewBuilder
    private func statRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(accentColor)
                .multilineTextAlignment(.trailing)
        }
    }

    private var accentColor: Color {
        switch badge.cardGradient.lowercased() {
        case "redorange":    return .red
        case "yelloworange": return .orange
        case "greenteal":    return .green
        case "purplepink":   return .purple
        case "pinkred":      return .pink
        default:             return .blue
        }
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }

    private func mediumDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: date)
    }

    private func formatSteps(_ steps: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f.string(from: NSNumber(value: steps)) ?? "\(steps)"
    }
}



