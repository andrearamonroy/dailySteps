import SwiftUI
import CoreData

// MARK: - Core Data helpers
// Assumes Codegen = "Class Definition" for all three entities.

extension WorkoutDay {
    var exerciseArray: [Exercise] {
        (exercises as? Set<Exercise> ?? []).sorted { $0.order < $1.order }
    }
    /// A workout is "in progress" while activeSessionID is set
    var isActive: Bool { activeSessionID != nil }
}

extension ExerciseLog {
    /// One set: reps x weight (lb)
    var volume: Double { Double(reps) * weight }
}

extension Sequence where Element == ExerciseLog {
    var totalVolume: Double { reduce(0) { $0 + $1.volume } }
}

extension Exercise {
    /// Every set ever logged, oldest first
    var allLogs: [ExerciseLog] {
        (logs as? Set<ExerciseLog> ?? []).sorted {
            ($0.date ?? .distantPast) < ($1.date ?? .distantPast)
        }
    }

    /// Sets logged in one specific workout session
    func sets(in session: UUID?) -> [ExerciseLog] {
        guard let session else { return [] }
        return allLogs.filter { $0.sessionID == session }
    }

    /// Sets from the most recent finished session (ignores the active one)
    func lastSessionSets(excluding active: UUID?) -> [ExerciseLog] {
        let previous = allLogs.filter { $0.sessionID != nil && $0.sessionID != active }
        guard let latest = previous.last?.sessionID else { return [] }
        return previous.filter { $0.sessionID == latest }
    }
}

extension Double {
    /// 100 -> "100", 102.5 -> "102.5"
    var lbString: String {
        formatted(.number.grouping(.never).precision(.fractionLength(0...1)))
    }
}

// MARK: - Home

struct WorkOutView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WorkoutDay.order, ascending: true)]
    ) private var days: FetchedResults<WorkoutDay>

    @State private var showSetup = false

    var body: some View {
        NavigationStack {
            Group {
                if days.isEmpty {
                    ContentUnavailableView {
                        Label("No routine yet", systemImage: "dumbbell")
                    } description: {
                        Text("Set up your workout days to get started.")
                    } actions: {
                        Button("Build my routine") { showSetup = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List(days) { day in
                        NavigationLink {
                            DayDetailView(day: day)
                        } label: {
                            DayRow(day: day)
                        }
                    }
                }
            }
            .navigationTitle("My Routine")
            .toolbar {
                if !days.isEmpty {
                    Button("Edit Routine") { showSetup = true }
                }
            }
            .sheet(isPresented: $showSetup) { SetupView() }
        }
    }
}

struct DayRow: View {
    @ObservedObject var day: WorkoutDay

    var body: some View {
        HStack {
            Text(day.name ?? "Day")
            Spacer()
            if day.isActive {
                Text("In progress")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
    }
}

// MARK: - Setup (pick # of days, name them, add exercises)

struct DayDraft: Identifiable {
    let id = UUID()
    var name = ""
    var exercises = Array(repeating: "", count: 4)
}

struct SetupView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var dayCount = 3
    @State private var drafts = (0..<3).map { _ in DayDraft() }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper("Workout days: \(dayCount)", value: $dayCount, in: 1...7)
                }

                ForEach($drafts) { $draft in
                    Section {
                        TextField("Day name (e.g. Back & Arms)", text: $draft.name)

                        ForEach(draft.exercises.indices, id: \.self) { i in
                            TextField("Exercise \(i + 1) (e.g. Pull-down)",
                                      text: $draft.exercises[i])
                        }

                        Button("Add exercise") { draft.exercises.append("") }
                    } header: {
                        Text("Day \((drafts.firstIndex { $0.id == draft.id } ?? 0) + 1)")
                    }
                }
            }
            .navigationTitle("Build Routine")
            .onChange(of: dayCount) { _, newValue in
                if newValue > drafts.count {
                    drafts += (0..<(newValue - drafts.count)).map { _ in DayDraft() }
                } else {
                    drafts = Array(drafts.prefix(newValue))
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
        }
    }

    private func save() {
        // Replace any existing routine (history is deleted with it via cascade)
        let request: NSFetchRequest<WorkoutDay> = WorkoutDay.fetchRequest()
        (try? context.fetch(request))?.forEach(context.delete)

        for (dayIndex, draft) in drafts.enumerated() {
            let day = WorkoutDay(context: context)
            day.id = UUID()
            day.name = draft.name.isEmpty ? "Day \(dayIndex + 1)" : draft.name
            day.order = Int16(dayIndex)

            let names = draft.exercises.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            for (i, name) in names.enumerated() {
                let ex = Exercise(context: context)
                ex.id = UUID()
                ex.name = name
                ex.order = Int16(i)
                ex.day = day
            }
        }
        try? context.save()
        dismiss()
    }
}

// MARK: - Day detail (exercise list + Start/End)

struct DayDetailView: View {
    @Environment(\.managedObjectContext) private var context
    @ObservedObject var day: WorkoutDay

    var body: some View {
        List {
            ForEach(day.exerciseArray) { exercise in
                NavigationLink {
                    ExerciseDetailView(exercise: exercise, day: day)
                } label: {
                    ExerciseSummaryRow(exercise: exercise, session: day.activeSessionID)
                }
                .disabled(!day.isActive)
            }

            if !day.isActive {
                Text("Tap Start to begin logging this workout.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(day.name ?? "Workout")
        .safeAreaInset(edge: .bottom) {
            Button {
                toggleWorkout()
            } label: {
                Text(day.isActive ? "End Workout" : "Start Workout")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(day.isActive ? .red : .green)
            .padding()
        }
    }

    private func toggleWorkout() {
        if let session = day.activeSessionID {
            // End: clean up sets that were added but left empty
            for exercise in day.exerciseArray {
                for log in exercise.sets(in: session) where log.reps == 0 && log.weight == 0 {
                    context.delete(log)
                }
            }
            day.activeSessionID = nil
        } else {
            // Start: a new session id groups all sets logged from now until End
            day.activeSessionID = UUID()
        }
        try? context.save()
    }
}

struct ExerciseSummaryRow: View {
    @ObservedObject var exercise: Exercise
    let session: UUID?

    var body: some View {
        let today = exercise.sets(in: session)
        let last = exercise.lastSessionSets(excluding: session)

        VStack(alignment: .leading, spacing: 2) {
            Text(exercise.name ?? "Exercise").font(.headline)

            if !today.isEmpty {
                Text("Today: \(today.count) sets • \(today.totalVolume, specifier: "%.0f") lb")
                    .font(.caption)
                    .foregroundStyle(.green)
            } else if !last.isEmpty {
                Text("Last: \(last.count) sets • \(last.totalVolume, specifier: "%.0f") lb")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("No history yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Exercise detail (add as many sets as you want)

struct ExerciseDetailView: View {
    @Environment(\.managedObjectContext) private var context
    @ObservedObject var exercise: Exercise
    @ObservedObject var day: WorkoutDay

    var body: some View {
        let current = exercise.sets(in: day.activeSessionID)
        let last = exercise.lastSessionSets(excluding: day.activeSessionID)

        List {
            Section {
                if last.isEmpty {
                    Text("No history yet").foregroundStyle(.secondary)
                } else {
                    ForEach(Array(last.enumerated()), id: \.element) { index, log in
                        Text("Set \(index + 1): \(log.reps) reps × \(log.weight.lbString) lb")
                    }
                }
            } header: {
                Text("Last time")
            }

            Section {
                ForEach(Array(current.enumerated()), id: \.element) { index, log in
                    SetRow(log: log, number: index + 1)
                }
                .onDelete { offsets in
                    offsets.map { current[$0] }.forEach(context.delete)
                    try? context.save()
                }

                Button {
                    addSet(current: current, last: last)
                } label: {
                    Label("Add Set", systemImage: "plus.circle.fill")
                }
            } header: {
                Text("Today")
            } footer: {
                if !current.isEmpty {
                    Text("Total volume: \(current.totalVolume, specifier: "%.0f") lb")
                }
            }
        }
        .navigationTitle(exercise.name ?? "Exercise")
    }

    private func addSet(current: [ExerciseLog], last: [ExerciseLog]) {
        guard let session = day.activeSessionID else { return }

        // Pre-fill from the previous set (or last session) so you only tweak numbers
        let template = current.last ?? last.first

        let log = ExerciseLog(context: context)
        log.id = UUID()
        log.date = .now
        log.sessionID = session
        log.reps = template?.reps ?? 0
        log.weight = template?.weight ?? 0
        log.exercise = exercise
        try? context.save()
    }
}

/// One set: only reps and weight (lb)
struct SetRow: View {
    @Environment(\.managedObjectContext) private var context
    @ObservedObject var log: ExerciseLog
    let number: Int

    @State private var reps: String
    @State private var weight: String

    init(log: ExerciseLog, number: Int) {
        self.log = log
        self.number = number
        _reps = State(initialValue: log.reps == 0 ? "" : String(log.reps))
        _weight = State(initialValue: log.weight == 0 ? "" : log.weight.lbString)
    }

    var body: some View {
        HStack(spacing: 8) {
            Text("Set \(number)")
                .frame(width: 56, alignment: .leading)

            TextField("Reps", text: $reps)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)

            Text("×").foregroundStyle(.secondary)

            TextField("Weight", text: $weight)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)

            Text("lb").foregroundStyle(.secondary)
        }
        .onChange(of: reps) { _, new in
            log.reps = Int16(new) ?? 0
            try? context.save()
        }
        .onChange(of: weight) { _, new in
            log.weight = Double(new.replacingOccurrences(of: ",", with: ".")) ?? 0
            try? context.save()
        }
    }
}
