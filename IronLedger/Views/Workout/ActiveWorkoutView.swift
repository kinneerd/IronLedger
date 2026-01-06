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
    
    var workout: WorkoutSession? {
        dataManager.activeWorkout
    }
    
    var body: some View {
        NavigationStack {
            if let workout = workout {
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
    
    @State private var showingRestTimer = false
    @State private var restTimeRemaining: Int = 0
    @State private var showingNotes = false
    
    var completedSets: Int {
        exercise.sets.filter { $0.isCompleted }.count
    }
    
    var totalSets: Int {
        exercise.sets.count
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
        .overlay(
            // Rest timer overlay
            Group {
                if showingRestTimer {
                    RestTimerOverlay(
                        timeRemaining: $restTimeRemaining,
                        totalTime: exercise.restSeconds,
                        onDismiss: { showingRestTimer = false }
                    )
                }
            }
        )
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
        restTimeRemaining = exercise.restSeconds
        showingRestTimer = true
    }
}

// MARK: - Set Row

struct SetRow: View {
    @Binding var set: ExerciseSet
    let setNumber: Int
    let category: ExerciseCategory
    let onComplete: () -> Void
    
    @State private var repsText: String = ""
    @State private var weightText: String = ""
    @FocusState private var focusedField: Field?
    
    enum Field {
        case reps, weight
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Set type badge
            Text(set.setType == .warmup ? "W" : "\(setNumber)")
                .font(.gymCaption)
                .foregroundColor(set.setType == .warmup ? .warmupColor : .gymTextPrimary)
                .frame(width: 28, height: 28)
                .background(set.setType == .warmup ? Color.warmupColor.opacity(0.2) : Color.gymElevated)
                .cornerRadius(6)
            
            // Weight input
            HStack(spacing: 4) {
                TextField("—", text: $weightText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .font(.gymSubheadline)
                    .foregroundColor(.gymTextPrimary)
                    .frame(width: 60)
                    .focused($focusedField, equals: .weight)
                    .onChange(of: weightText) { _, newValue in
                        set.weight = Double(newValue)
                    }
                
                Text("lbs")
                    .font(.gymCaption)
                    .foregroundColor(.gymTextTertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
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
}

// MARK: - Rest Timer Overlay

struct RestTimerOverlay: View {
    @Binding var timeRemaining: Int
    let totalTime: Int
    let onDismiss: () -> Void
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
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
            
            HStack(spacing: 16) {
                Button(action: { timeRemaining += 30 }) {
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
        .onReceive(timer) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                // Vibrate when done
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                onDismiss()
            }
        }
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

// MARK: - Preview

#Preview {
    let dm = DataManager()
    dm.startWorkout(type: .benchFocus)
    return ActiveWorkoutView()
        .environmentObject(dm)
        .preferredColorScheme(.dark)
}
