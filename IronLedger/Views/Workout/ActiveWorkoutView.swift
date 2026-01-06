//
//  ActiveWorkoutView.swift
//  GymTracker
//
//  Main workout logging screen
//

import SwiftUI

struct ActiveWorkoutView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingCancelAlert = false
    @State private var showingCompleteSheet = false
    @State private var expandedExerciseId: UUID?
    @State private var restTimerEndTime: Date?
    @State private var restTimerTotalSeconds: Int = 0

    var workout: WorkoutSession? {
        dataManager.activeWorkout
    }

    var body: some View {
        NavigationStack {
            if let workout = workout {
                VStack(spacing: 0) {
                    // Persistent rest timer banner at top
                    if restTimerEndTime != nil {
                        RestTimerBanner(
                            endTime: $restTimerEndTime,
                            totalSeconds: restTimerTotalSeconds,
                            onDismiss: { restTimerEndTime = nil }
                        )
                    }

                    ScrollView {
                        VStack(spacing: 16) {
                            // Workout header
                            WorkoutHeaderView(workout: workout)
                        
                        // Exercises
                        ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, exercise in
                            ExerciseCard(
                                exercise: binding(for: exercise),
                                exerciseIndex: index,
                                isExpanded: expandedExerciseId == exercise.id,
                                onToggleExpand: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        if expandedExerciseId == exercise.id {
                                            expandedExerciseId = nil
                                        } else {
                                            expandedExerciseId = exercise.id
                                        }
                                    }
                                },
                                onStartRestTimer: { seconds in
                                    startRestTimer(seconds: seconds)
                                }
                            )
                        }
                        
                        // Add exercise button
                        Button(action: {
                            // TODO: Add exercise picker
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Exercise")
                            }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .padding(.top, 8)
                        
                        // Complete workout button
                        Button(action: {
                            showingCompleteSheet = true
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Complete Workout")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.top, 16)
                    }
                    .padding()
                    }
                    .background(Color.gymBackground)
                }
                .navigationTitle(workout.workoutType.shortName)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            showingCancelAlert = true
                        }
                        .foregroundColor(.gymTextSecondary)
                    }
                }
                .alert("Cancel Workout?", isPresented: $showingCancelAlert) {
                    Button("Keep Going", role: .cancel) { }
                    Button("Discard", role: .destructive) {
                        dataManager.cancelWorkout()
                    }
                } message: {
                    Text("Your progress will not be saved.")
                }
                .sheet(isPresented: $showingCompleteSheet) {
                    CompleteWorkoutSheet()
                        .environmentObject(dataManager)
                }
            }
        }
    }
    
    func binding(for exercise: LoggedExercise) -> Binding<LoggedExercise> {
        guard let workoutIndex = dataManager.activeWorkout?.exercises.firstIndex(where: { $0.id == exercise.id }) else {
            return .constant(exercise)
        }
        return Binding(
            get: { dataManager.activeWorkout?.exercises[workoutIndex] ?? exercise },
            set: { dataManager.activeWorkout?.exercises[workoutIndex] = $0 }
        )
    }

    func startRestTimer(seconds: Int) {
        restTimerTotalSeconds = seconds
        restTimerEndTime = Date().addingTimeInterval(TimeInterval(seconds))
    }
}

// MARK: - Workout Header

struct WorkoutHeaderView: View {
    let workout: WorkoutSession
    @State private var elapsedTime: TimeInterval = 0
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.workoutType.name)
                    .font(.gymHeadline)
                    .foregroundColor(.gymTextPrimary)
                
                Text(workout.startTime.formatted(date: .abbreviated, time: .shortened))
                    .font(.gymCaption)
                    .foregroundColor(.gymTextTertiary)
            }
            
            Spacer()
            
            // Timer
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatDuration(elapsedTime))
                    .font(.gymSubheadline)
                    .foregroundColor(.gymTextSecondary)
                    .monospacedDigit()
                
                Text("duration")
                    .font(.gymCaption)
                    .foregroundColor(.gymTextTertiary)
            }
        }
        .padding(16)
        .cardStyle()
        .onReceive(timer) { _ in
            elapsedTime = Date().timeIntervalSince(workout.startTime)
        }
    }
    
    func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Exercise Card

struct ExerciseCard: View {
    @Binding var exercise: LoggedExercise
    let exerciseIndex: Int
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onStartRestTimer: (Int) -> Void

    @EnvironmentObject var dataManager: DataManager

    @State private var showingNotes = false

    var completedSets: Int {
        exercise.sets.filter { $0.isCompleted }.count
    }

    var totalSets: Int {
        exercise.sets.count
    }

    var previousExercise: LoggedExercise? {
        guard let activeWorkout = dataManager.activeWorkout,
              let previousWorkout = dataManager.getPreviousWorkout(for: activeWorkout.workoutType) else {
            return nil
        }
        return previousWorkout.exercises.first { $0.exerciseName == exercise.exerciseName }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header (always visible)
            Button(action: onToggleExpand) {
                HStack(spacing: 12) {
                    // Category indicator
                    RoundedRectangle(cornerRadius: 2)
                        .fill(categoryColor)
                        .frame(width: 4, height: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.exerciseName)
                            .font(.gymSubheadline)
                            .foregroundColor(.gymTextPrimary)
                        
                        Text("\(completedSets)/\(totalSets) sets")
                            .font(.gymCaption)
                            .foregroundColor(.gymTextTertiary)
                    }
                    
                    Spacer()
                    
                    // Progress ring
                    ZStack {
                        Circle()
                            .stroke(Color.gymTextTertiary.opacity(0.3), lineWidth: 3)
                        
                        Circle()
                            .trim(from: 0, to: totalSets > 0 ? CGFloat(completedSets) / CGFloat(totalSets) : 0)
                            .stroke(categoryColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                    .frame(width: 36, height: 36)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gymTextTertiary)
                }
                .padding(16)
            }
            .buttonStyle(.plain)
            
            // Expanded content
            if isExpanded {
                VStack(spacing: 12) {
                    Divider()
                        .background(Color.gymTextTertiary.opacity(0.2))
                    
                    // Sets
                    ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                        SetRow(
                            set: $exercise.sets[index],
                            setNumber: index + 1,
                            category: exercise.category,
                            previousSet: previousSetData(for: index),
                            onComplete: {
                                startRestTimer()
                            }
                        )
                    }
                    
                    // Add set button
                    HStack {
                        Button(action: addSet) {
                            HStack {
                                Image(systemName: "plus")
                                Text("Add Set")
                            }
                            .font(.gymCaption)
                        }
                        .buttonStyle(CompactButtonStyle(color: .gymTextSecondary))
                        
                        Spacer()
                        
                        // Notes button
                        Button(action: { showingNotes = true }) {
                            HStack {
                                Image(systemName: exercise.notes.isEmpty ? "note.text" : "note.text.badge.plus")
                                Text("Notes")
                            }
                            .font(.gymCaption)
                        }
                        .buttonStyle(CompactButtonStyle(color: exercise.notes.isEmpty ? .gymTextSecondary : .gymAccent))
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
        .cardStyle()
        .sheet(isPresented: $showingNotes) {
            NotesSheet(notes: $exercise.notes, exerciseName: exercise.exerciseName)
        }
    }
    
    var categoryColor: Color {
        switch exercise.category {
        case .mainLift: return .mainLiftColor
        case .compound: return .compoundColor
        case .accessory: return .accessoryColor
        }
    }
    
    func addSet() {
        let lastSet = exercise.sets.last
        exercise.sets.append(ExerciseSet(
            reps: lastSet?.reps,
            weight: lastSet?.weight,
            setType: .working
        ))
    }
    
    func startRestTimer() {
        // Dismiss keyboard before showing rest timer
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        onStartRestTimer(exercise.restSeconds)
    }

    func previousSetData(for index: Int) -> ExerciseSet? {
        guard let previousExercise = previousExercise else { return nil }
        let workingSets = previousExercise.workingSets
        let workingSetIndex = exercise.sets.prefix(index + 1).filter { $0.setType == .working }.count - 1
        guard workingSetIndex >= 0 && workingSetIndex < workingSets.count else { return nil }
        return workingSets[workingSetIndex]
    }
}

// MARK: - Set Row

struct SetRow: View {
    @Binding var set: ExerciseSet
    let setNumber: Int
    let category: ExerciseCategory
    let previousSet: ExerciseSet?
    let onComplete: () -> Void

    @State private var repsText: String = ""
    @State private var weightText: String = ""
    @FocusState private var focusedField: Field?

    enum Field {
        case reps, weight
    }

    var previousSetDisplay: String? {
        guard set.setType == .working,
              let prevSet = previousSet,
              let weight = prevSet.weight,
              let reps = prevSet.reps else {
            return nil
        }
        return "Last: \(Int(weight))×\(reps)"
    }
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 12) {
                // Set type badge
                Text(set.setType == .warmup ? "W" : "\(setNumber)")
                    .font(.gymCaption)
                    .foregroundColor(set.setType == .warmup ? .warmupColor : .gymTextPrimary)
                    .frame(width: 28, height: 28)
                    .background(set.setType == .warmup ? Color.warmupColor.opacity(0.2) : Color.gymElevated)
                    .cornerRadius(6)

                // Weight input with adjustment buttons
                VStack(spacing: 2) {
                    HStack(spacing: 4) {
                        // -5 button
                        Button(action: { adjustWeight(by: -5) }) {
                            Image(systemName: "minus")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.gymTextSecondary)
                        }
                        .frame(width: 24, height: 24)
                        .background(Color.gymBackground)
                        .cornerRadius(4)
                        .buttonStyle(.plain)

                        TextField("—", text: $weightText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .font(.gymSubheadline)
                            .foregroundColor(.gymTextPrimary)
                            .frame(width: 48)
                            .focused($focusedField, equals: .weight)
                            .onChange(of: weightText) { _, newValue in
                                set.weight = Double(newValue)
                            }

                        // +5 button
                        Button(action: { adjustWeight(by: 5) }) {
                            Image(systemName: "plus")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.gymTextSecondary)
                        }
                        .frame(width: 24, height: 24)
                        .background(Color.gymBackground)
                        .cornerRadius(4)
                        .buttonStyle(.plain)
                    }

                    Text("lbs")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.gymTextTertiary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.gymElevated)
                .cornerRadius(8)

                // Reps input
                HStack(spacing: 4) {
                    TextField("—", text: $repsText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(.gymSubheadline)
                        .foregroundColor(.gymTextPrimary)
                        .frame(width: 40)
                        .focused($focusedField, equals: .reps)
                        .onChange(of: repsText) { _, newValue in
                            set.reps = Int(newValue)
                        }

                    Text("reps")
                        .font(.gymCaption)
                        .foregroundColor(.gymTextTertiary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.gymElevated)
                .cornerRadius(8)

                Spacer()

                // Complete button
                Button(action: {
                    set.isCompleted.toggle()
                    if set.isCompleted {
                        onComplete()
                    }
                }) {
                    Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(set.isCompleted ? .gymSuccess : .gymTextTertiary)
                }
            }

            // Previous set indicator
            if let previousDisplay = previousSetDisplay {
                HStack {
                    Spacer()
                        .frame(width: 40) // Align with inputs, accounting for badge
                    Text(previousDisplay)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gymTextTertiary)
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 16)
        .onAppear {
            if let weight = set.weight {
                weightText = String(Int(weight))
            }
            if let reps = set.reps {
                repsText = String(reps)
            }
        }
    }

    func adjustWeight(by amount: Double) {
        let currentWeight = set.weight ?? 0
        let newWeight = max(0, currentWeight + amount)
        set.weight = newWeight
        weightText = String(Int(newWeight))
    }
}

// MARK: - Rest Timer Overlay

struct RestTimerOverlay: View {
    @Binding var timeRemaining: Int
    let totalTime: Int
    let onDismiss: () -> Void

    @EnvironmentObject var dataManager: DataManager
    @Environment(\.scenePhase) private var scenePhase

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var verse: BibleVerse = Verses.random()
    @State private var endTime: Date = Date()

    var progress: Double {
        guard totalTime > 0 else { return 0 }
        return Double(totalTime - timeRemaining) / Double(totalTime)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("REST")
                .font(.gymCaption)
                .foregroundColor(.gymTextTertiary)
                .tracking(2)

            ZStack {
                Circle()
                    .stroke(Color.gymTextTertiary.opacity(0.2), lineWidth: 6)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.gymAccent, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)

                Text(formatTime(timeRemaining))
                    .font(.gymLargeNumber)
                    .foregroundColor(.gymTextPrimary)
                    .monospacedDigit()
            }
            .frame(width: 120, height: 120)

            // Bible verse (if enabled)
            if dataManager.appState.showBibleVerses {
                VStack(spacing: 6) {
                    Text(verse.text)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.gymTextSecondary)
                        .multilineTextAlignment(.center)
                        .italic()
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("— \(verse.reference)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gymTextTertiary)
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: 280)
            }

            HStack(spacing: 16) {
                Button(action: { addTime(30) }) {
                    Text("+30s")
                        .font(.gymCaption)
                }
                .buttonStyle(CompactButtonStyle(color: .gymTextSecondary))

                Button(action: onDismiss) {
                    Text("Skip")
                        .font(.gymCaption)
                }
                .buttonStyle(CompactButtonStyle())
            }
        }
        .padding(24)
        .background(Color.gymSurface.opacity(0.95))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.3), radius: 20)
        .onAppear {
            // Set end time when timer first appears
            endTime = Date().addingTimeInterval(TimeInterval(timeRemaining))
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Recalculate time remaining when app becomes active
            if newPhase == .active {
                updateTimeRemaining()
            }
        }
        .onReceive(timer) { _ in
            updateTimeRemaining()
        }
    }

    private func updateTimeRemaining() {
        let remaining = Int(endTime.timeIntervalSinceNow)

        if remaining > 0 {
            timeRemaining = remaining
        } else if timeRemaining > 0 {
            // Timer just finished
            timeRemaining = 0
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            onDismiss()
        }
    }

    private func addTime(_ seconds: Int) {
        endTime = endTime.addingTimeInterval(TimeInterval(seconds))
        timeRemaining += seconds
    }
    
    func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Notes Sheet

struct NotesSheet: View {
    @Binding var notes: String
    let exerciseName: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                TextEditor(text: $notes)
                    .font(.gymBody)
                    .foregroundColor(.gymTextPrimary)
                    .scrollContentBackground(.hidden)
                    .background(Color.gymSurface)
                    .cornerRadius(12)
                    .padding()
            }
            .background(Color.gymBackground)
            .navigationTitle("Notes: \(exerciseName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Rest Timer Banner

struct RestTimerBanner: View {
    @Binding var endTime: Date?
    let totalSeconds: Int
    let onDismiss: () -> Void

    @EnvironmentObject var dataManager: DataManager
    @Environment(\.scenePhase) private var scenePhase

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var timeRemaining: Int = 0
    @State private var verse: BibleVerse = Verses.random()

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - timeRemaining) / Double(totalSeconds)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Circular progress indicator
                ZStack {
                    Circle()
                        .stroke(Color.gymTextTertiary.opacity(0.2), lineWidth: 3)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.gymAccent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: progress)

                    Text(formatTime(timeRemaining))
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(.gymTextPrimary)
                }
                .frame(width: 44, height: 44)

                // Rest label and timer info
                VStack(alignment: .leading, spacing: 2) {
                    Text("REST")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gymTextTertiary)
                        .tracking(1)

                    if !dataManager.appState.showBibleVerses {
                        Text("Rest period in progress")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.gymTextSecondary)
                    }
                }

                Spacer()

                // +30s button
                Button(action: { addTime(30) }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.gymTextSecondary)
                }

                // Skip button
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.gymTextSecondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Bible verse (full text)
            if dataManager.appState.showBibleVerses {
                VStack(spacing: 4) {
                    Text(verse.text)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.gymTextSecondary)
                        .multilineTextAlignment(.center)
                        .italic()
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("— \(verse.reference)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.gymTextTertiary)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .background(Color.gymSurface)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gymTextTertiary.opacity(0.1)),
            alignment: .bottom
        )
        .onAppear {
            updateTimeRemaining()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                updateTimeRemaining()
            }
        }
        .onReceive(timer) { _ in
            updateTimeRemaining()
        }
    }

    private func updateTimeRemaining() {
        guard let endTime = endTime else { return }
        let remaining = Int(endTime.timeIntervalSinceNow)

        if remaining > 0 {
            timeRemaining = remaining
        } else if timeRemaining > 0 {
            // Timer just finished
            timeRemaining = 0
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            onDismiss()
        }
    }

    private func addTime(_ seconds: Int) {
        guard let currentEndTime = endTime else { return }
        endTime = currentEndTime.addingTimeInterval(TimeInterval(seconds))
        timeRemaining += seconds
    }

    func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Preview

#Preview {
    let dm = DataManager()
    dm.startWorkout(type: .benchFocus)
    return ActiveWorkoutView()
        .environmentObject(dm)
        .preferredColorScheme(.dark)
}
