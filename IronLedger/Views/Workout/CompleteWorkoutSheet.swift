//
//  CompleteWorkoutSheet.swift
//  GymTracker
//
//  Workout completion with context capture and summary export
//

import SwiftUI

struct CompleteWorkoutSheet: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    
    @State private var energyLevel: Rating?
    @State private var sleepQuality: Rating?
    @State private var bodyweight: String = ""
    @State private var workoutNotes: String = ""
    @State private var showingSummary = false
    
    var workout: WorkoutSession? {
        dataManager.activeWorkout
    }
    
    var canComplete: Bool {
        energyLevel != nil && sleepQuality != nil
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Quick stats
                    if let workout = workout {
                        QuickWorkoutStats(workout: workout)
                    }
                    
                    // Required: Energy Level
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Energy Level")
                                .font(.gymSubheadline)
                                .foregroundColor(.gymTextPrimary)
                            
                            Text("Required")
                                .font(.gymCaption)
                                .foregroundColor(.gymAccent)
                        }
                        
                        RatingSelector(selection: $energyLevel)
                    }
                    .padding(16)
                    .cardStyle()
                    
                    // Required: Sleep Quality
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Sleep Quality")
                                .font(.gymSubheadline)
                                .foregroundColor(.gymTextPrimary)
                            
                            Text("Required")
                                .font(.gymCaption)
                                .foregroundColor(.gymAccent)
                        }
                        
                        RatingSelector(selection: $sleepQuality)
                    }
                    .padding(16)
                    .cardStyle()
                    
                    // Optional: Bodyweight
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Bodyweight")
                            .font(.gymSubheadline)
                            .foregroundColor(.gymTextPrimary)
                        
                        HStack {
                            TextField("Enter weight", text: $bodyweight)
                                .keyboardType(.decimalPad)
                                .font(.gymBody)
                                .foregroundColor(.gymTextPrimary)
                            
                            Text("lbs")
                                .font(.gymCaption)
                                .foregroundColor(.gymTextTertiary)
                        }
                        .padding(12)
                        .background(Color.gymElevated)
                        .cornerRadius(8)
                    }
                    .padding(16)
                    .cardStyle()
                    
                    // Optional: Workout Notes
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Workout Notes")
                            .font(.gymSubheadline)
                            .foregroundColor(.gymTextPrimary)
                        
                        TextEditor(text: $workoutNotes)
                            .font(.gymBody)
                            .foregroundColor(.gymTextPrimary)
                            .frame(minHeight: 100)
                            .scrollContentBackground(.hidden)
                            .padding(12)
                            .background(Color.gymElevated)
                            .cornerRadius(8)
                    }
                    .padding(16)
                    .cardStyle()
                    
                    // Complete button
                    Button(action: completeWorkout) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Complete Workout")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(isEnabled: canComplete))
                    .disabled(!canComplete)
                    .padding(.top, 8)
                }
                .padding()
            }
            .background(Color.gymBackground)
            .navigationTitle("Finish Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") { dismiss() }
                        .foregroundColor(.gymTextSecondary)
                }
            }
            .sheet(isPresented: $showingSummary) {
                if let workout = dataManager.appState.workoutHistory.last {
                    WorkoutSummarySheet(workout: workout)
                        .environmentObject(dataManager)
                }
            }
        }
    }
    
    func completeWorkout() {
        guard canComplete else { return }

        // Validate and update workout with context
        dataManager.activeWorkout?.energyLevel = energyLevel
        dataManager.activeWorkout?.sleepQuality = sleepQuality
        dataManager.activeWorkout?.bodyweight = validateBodyweight(bodyweight)
        dataManager.activeWorkout?.notes = workoutNotes

        // Complete and save
        dataManager.completeWorkout()

        // Show summary
        dismiss()

        // Slight delay to allow dismiss animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showingSummary = true
        }
    }

    func validateBodyweight(_ input: String) -> Double? {
        let trimmed = input.trimmingCharacters(in: .whitespaces)

        // Allow empty
        guard !trimmed.isEmpty else { return nil }

        // Validate numeric
        guard let value = Double(trimmed) else { return nil }

        // Apply reasonable bounds: 50 to 500 lbs
        guard value >= 50 && value <= 500 else { return nil }

        return value
    }
}

// MARK: - Quick Workout Stats

struct QuickWorkoutStats: View {
    let workout: WorkoutSession
    
    var completedExercises: Int {
        workout.exercises.filter { exercise in
            exercise.sets.contains { $0.isCompleted }
        }.count
    }
    
    var completedSets: Int {
        workout.exercises.flatMap { $0.sets }.filter { $0.isCompleted }.count
    }
    
    var body: some View {
        HStack(spacing: 16) {
            StatItem(value: "\(completedExercises)", label: "Exercises")
            
            Divider()
                .frame(height: 40)
                .background(Color.gymTextTertiary.opacity(0.3))
            
            StatItem(value: "\(completedSets)", label: "Sets")
            
            Divider()
                .frame(height: 40)
                .background(Color.gymTextTertiary.opacity(0.3))
            
            StatItem(value: "\(Int(workout.totalVolume).formatted())", label: "lbs")
        }
        .padding(16)
        .cardStyle()
    }
}

struct StatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.gymHeadline)
                .foregroundColor(.gymTextPrimary)
            
            Text(label)
                .font(.gymCaption)
                .foregroundColor(.gymTextTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Rating Selector

struct RatingSelector: View {
    @Binding var selection: Rating?
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(Rating.allCases, id: \.self) { rating in
                Button(action: { selection = rating }) {
                    VStack(spacing: 6) {
                        Text(rating.emoji)
                            .font(.title2)
                        
                        Text(rating.rawValue)
                            .font(.gymCaption)
                            .foregroundColor(selection == rating ? .black : .gymTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selection == rating ? Color.gymAccent : Color.gymElevated)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Workout Summary Sheet

struct WorkoutSummarySheet: View {
    let workout: WorkoutSession
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    
    @State private var copied = false
    
    var summary: String {
        workout.generateSummary(prs: dataManager.appState.personalRecords)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Celebration header
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gymSuccess)
                        
                        Text("Workout Complete!")
                            .font(.gymTitle)
                            .foregroundColor(.gymTextPrimary)
                        
                        Text(workout.workoutType.fullName)
                            .font(.gymSubheadline)
                            .foregroundColor(.gymTextSecondary)
                    }
                    .padding(.top, 20)
                    
                    // Summary card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Summary")
                                .font(.gymSubheadline)
                                .foregroundColor(.gymTextPrimary)
                            
                            Spacer()
                            
                            Button(action: copyToClipboard) {
                                HStack(spacing: 4) {
                                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                    Text(copied ? "Copied!" : "Copy")
                                }
                                .font(.gymCaption)
                            }
                            .buttonStyle(CompactButtonStyle(color: copied ? .gymSuccess : .gymAccent))
                        }
                        
                        Text(summary)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.gymTextSecondary)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gymElevated)
                            .cornerRadius(8)
                    }
                    .padding(16)
                    .cardStyle()
                    
                    // PRs achieved
                    let prsThisWorkout = findNewPRs()
                    if !prsThisWorkout.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "trophy.fill")
                                    .foregroundColor(.gymSuccess)
                                
                                Text("New PRs!")
                                    .font(.gymSubheadline)
                                    .foregroundColor(.gymTextPrimary)
                            }
                            
                            ForEach(prsThisWorkout, id: \.exerciseName) { pr in
                                HStack {
                                    Text(pr.exerciseName)
                                        .font(.gymBody)
                                        .foregroundColor(.gymTextSecondary)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(pr.weight)) lbs × \(pr.reps)")
                                        .font(.gymSubheadline)
                                        .foregroundColor(.gymSuccess)
                                }
                            }
                        }
                        .padding(16)
                        .cardStyle()
                    }
                    
                    // Done button
                    Button(action: { dismiss() }) {
                        Text("Done")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 8)
                }
                .padding()
            }
            .background(Color.gymBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gymTextTertiary)
                    }
                }
            }
        }
    }
    
    func copyToClipboard() {
        UIPasteboard.general.string = summary
        copied = true
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Reset after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copied = false
        }
    }
    
    func findNewPRs() -> [PersonalRecord] {
        workout.exercises.compactMap { exercise -> PersonalRecord? in
            guard let pr = dataManager.appState.personalRecords[exercise.exerciseName],
                  pr.workoutSessionId == workout.id else {
                return nil
            }
            return pr
        }
    }
}

// MARK: - Preview

#Preview {
    let dm = DataManager()
    dm.startWorkout(type: .benchFocus)
    return CompleteWorkoutSheet()
        .environmentObject(dm)
        .preferredColorScheme(.dark)
}
