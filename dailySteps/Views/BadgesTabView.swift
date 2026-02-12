import SwiftUI
import CloudKit

// MARK: - Earned Badge Model

struct EarnedBadge: Identifiable {
    let id: CKRecord.ID
    let challengeName: String
    let challengeID: String
    let iconName: String
    let completedAt: Date
    let totalDays: Int
    let targetSteps: Int

    var completionYear: Int {
        Calendar.current.component(.year, from: completedAt)
    }

    // e.g. "Feb 3 - 4" for a 30-day challenge ending Feb 4
    var dateRangeLabel: String {
        let cal = Calendar.current
        let end = completedAt
        guard let start = cal.date(byAdding: .day, value: -(totalDays - 1), to: end) else {
            return formattedDate(end)
        }
        let startMonth = monthAbbrev(start)
        let endMonth = monthAbbrev(end)
        let startDay = cal.component(.day, from: start)
        let endDay = cal.component(.day, from: end)

        if startMonth == endMonth {
            return "\(startMonth) \(startDay) - \(endDay)"
        } else {
            return "\(startMonth) \(startDay) - \(endMonth) \(endDay)"
        }
    }

    private func monthAbbrev(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f.string(from: date)
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }
}

// MARK: - CloudKit fetch extension

extension CloudKitManager {
    /// Fetches all completed enrollments for the current user, sorted newest first.
    func fetchCompletedBadges(completion: @escaping (Result<[EarnedBadge], Error>) -> Void) {
        // Changed to publicDatabase to match where enrollments are saved
        let predicate = NSPredicate(format: "completedAt != nil")
        let query = CKQuery(recordType: "Enrollment", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "completedAt", ascending: false)]

        publicDatabase.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                print("❌ fetchCompletedBadges error: \(error.localizedDescription)")
                // If field doesn't exist yet, just return empty instead of erroring
                DispatchQueue.main.async {
                    completion(.success([]))
                }
                return
            }

            let badges = (records ?? []).compactMap { record -> EarnedBadge? in
                guard
                    let completedAt = record["completedAt"] as? Date,
                    let challengeName = record["challengeName"] as? String,
                    let challengeID = record["challengeID"] as? String
                else { return nil }

                return EarnedBadge(
                    id: record.recordID,
                    challengeName: challengeName,
                    challengeID: challengeID,
                    iconName: self.iconName(for: challengeID),
                    completedAt: completedAt,
                    totalDays: record["duration"] as? Int ?? 30,
                    targetSteps: record["targetSteps"] as? Int ?? 10000
                )
            }

            DispatchQueue.main.async {
                completion(.success(badges))
            }
        }
    }

    func markChallengeCompleted(enrollment: CKRecord, completion: @escaping (Result<Void, Error>) -> Void) {
        enrollment["completedAt"] = Date() as CKRecordValue

        publicDatabase.save(enrollment) { _, error in  // changed from privateDatabase
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ChallengeCompleted"),
                        object: nil
                    )
                }
            }
        }
    }

    private func iconName(for challengeID: String) -> String {
        let id = challengeID.lowercased()
        if id.contains("10k-monday")        { return "10kMonday" }
        if id.contains("weekend-warrior")   { return "weekendWarrior" }
        if id.contains("freedom-friday")    { return "freedomFriday" }
        if id.contains("steady-sunday")     { return "steadySunday" }
        if id.contains("super-saturday")    { return "superSaturday" }
        if id.contains("thirsty-thursday")  { return "thursday" }
        if id.contains("turbo-tuesday")     { return "turboTuesday" }
        if id.contains("10k-everyday")      { return "10kEveryday" }
        if id.contains("7k-everyday")       { return "7kEveryday" }
        if id.contains("wellness-wednesday"){ return "wellnesWed" }
        return "challenge-10k-daily"
    }
}

// MARK: - Badges Tab View

struct BadgesTabView: View {
    @StateObject private var cloudKitManager = CloudKitManager.shared
    @State private var badges: [EarnedBadge] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedBadge: EarnedBadge?
    @ObservedObject var themeManager = ThemeManager.shared
    // Group badges by year, newest year first
    var badgesByYear: [(year: Int, badges: [EarnedBadge])] {
        let grouped = Dictionary(grouping: badges, by: { $0.completionYear })
        return grouped.sorted { $0.key > $1.key }.map { (year: $0.key, badges: $0.value) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()

                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(error)
                } else if badges.isEmpty {
                    emptyStateView
                } else {
                    badgesScrollView
                }
            }
            .navigationTitle("My Badges")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text("\(badges.count) earned")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                }
            }
        }
        .onAppear { loadBadges() }
        .onReceive(
            NotificationCenter.default.publisher(for: NSNotification.Name("ChallengeCompleted"))
        ) { _ in
            loadBadges()
        }
        .sheet(item: $selectedBadge) { badge in
            BadgeDetailSheet(badge: badge)
        }
    }

    // MARK: - Subviews

    private var badgesScrollView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                ForEach(badgesByYear, id: \.year) { group in
                    YearSection(year: group.year, badges: group.badges) { badge in
                        selectedBadge = badge
                    }
                }
            }
            .padding(.vertical, 20)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.3)
            Text("Loading badges...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Retry") { loadBadges() }
                .buttonStyle(.borderedProminent)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
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
            VStack(spacing: 8) {
                Text("No Badges Yet")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Color(.label))
                Text("Enroll in a challenge and\nearn your first badge!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            NavigationLink(destination: ChallengesListView()) {
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
        }
        .padding(32)
    }

    // MARK: - Load

    private func loadBadges() {
        isLoading = true
        errorMessage = nil
        cloudKitManager.fetchCompletedBadges { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let fetched):
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        self.badges = fetched
                    }
                case .failure(let error):
                    self.errorMessage = "Couldn't load badges.\n\(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Year Section

struct YearSection: View {
    let year: Int
    let badges: [EarnedBadge]
    var onTap: (EarnedBadge) -> Void

    // 3-column grid
    let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Year header
            HStack {
                Text("\(year)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(Color(.label))
                    .padding(.horizontal, 20)

                Spacer()

                Text("\(badges.count) badge\(badges.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
            }

            // Badge grid
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(badges) { badge in
                    BadgeTileView(badge: badge)
                        .onTapGesture { onTap(badge) }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Badge Tile

struct BadgeTileView: View {
    let badge: EarnedBadge
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 8) {
            // Badge circle
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.78, blue: 0.1),
                                Color(red: 1.0, green: 0.45, blue: 0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                    .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 4)

                Image(badge.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 42, height: 42)
            }
            .scaleEffect(appeared ? 1.0 : 0.5)
            .opacity(appeared ? 1.0 : 0)

            // Date range label
            Text(badge.dateRangeLabel)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .opacity(appeared ? 1.0 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65).delay(Double.random(in: 0...0.3))) {
                appeared = true
            }
        }
    }
}

// MARK: - Badge Detail Sheet

struct BadgeDetailSheet: View {
    let badge: EarnedBadge
    @Environment(\.dismiss) private var dismiss
    @State private var badgeScale: CGFloat = 0.6
    @State private var glow: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 24)

            // Badge
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.orange.opacity(glow ? 0.35 : 0.15),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 90
                        )
                    )
                    .frame(width: 180, height: 180)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.78, blue: 0.1),
                                Color(red: 1.0, green: 0.45, blue: 0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 110, height: 110)
                    .shadow(color: .orange.opacity(0.4), radius: 20, x: 0, y: 8)

                Image(badge.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
            }
            .scaleEffect(badgeScale)
            .padding(.bottom, 24)

            // Name
            Text(badge.challengeName)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(Color(.label))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text("Challenge Completed")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 4)
                .padding(.bottom, 28)

            // Stats row
            HStack(spacing: 0) {
                DetailStatBox(value: "\(badge.totalDays)", label: "Days")
                Divider().frame(height: 40)
                DetailStatBox(value: formatSteps(badge.targetSteps), label: "Steps/day")
                Divider().frame(height: 40)
                DetailStatBox(value: badge.dateRangeLabel, label: "Completed")
            }
            .padding(.vertical, 20)
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .padding(.horizontal, 24)

            Spacer()

            Button { dismiss() } label: {
                Text("Close")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 32)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.65).delay(0.1)) {
                badgeScale = 1.0
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.5)) {
                glow = true
            }
        }
    }

    private func formatSteps(_ steps: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f.string(from: NSNumber(value: steps)) ?? "\(steps)"
    }
}

struct DetailStatBox: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(Color(.label))
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    BadgesTabView()
}
