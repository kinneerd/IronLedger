//
//  HistoryView.swift
//  GymTracker
//
//  Browse past workouts with filtering
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedFilter: WorkoutType?
    @State private var selectedWorkout: WorkoutSession?
    
    var filteredWorkouts: [WorkoutSession] {
        let workouts = dataManager.appState.workoutHistory
            .filter { $0.isCompleted }
            .sorted { $0.startTime > $1.startTime }
        
        if let filter = selectedFilter {
            return workouts.filter { $0.workoutType == filter }
        }
        return workouts
    }
    
    var groupedWorkouts: [(String, [WorkoutSession])] {
        let grouped = Dictionary(grouping: filteredWorkouts) { workout -> String in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: workout.startTime)
        }
        
        return grouped.sorted { pair1, pair2 in
            guard let date1 = filteredWorkouts.first(where: { 
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                return formatter.string(from: $0.startTime) == pair1.0
            })?.startTime,
            let date2 = filteredWorkouts.first(where: {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                return formatter.string(from: $0.startTime) == pair2.0
            })?.startTime else {
                return false
            }
            return date1 > date2
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Filter chips
                    FilterChipsView(selectedFilter: $selectedFilter)
                    
                    if filteredWorkouts.isEmpty {
                        EmptyHistoryView()
                    } else {
                        // Grouped workouts
                        ForEach(groupedWorkouts, id: \.0) { month, workouts in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(month)
                                    .font(.gymCaption)
                                    .foregroundColor(.gymTextTertiary)
                                    .tracking(1)
                                    .padding(.horizontal, 4)
                                
                                VStack(spacing: 1) {
                                    ForEach(workouts) { workout in
                                        HistoryWorkoutRow(workout: workout)
                                            .onTapGesture {
                                                selectedWorkout = workout
                                            }
                                    }
                                }
                                .cornerRadius(16)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color.gymBackground)
            .navigationTitle("History")
            .sheet(item: $selectedWorkout) { workout in
                WorkoutDetailSheet(workout: workout)
                    .environmentObject(dataManager)
            }
        }
    }
}

// MARK: - Filter Chips

struct FilterChipsView: View {
    @Binding var selectedFilter: WorkoutType?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: "All",
                    isSelected: selectedFilter == nil,
                    action: { selectedFilter = nil }
                )
                
                ForEach(WorkoutType.allCases) { type in
                    FilterChip(
                        title: type.shortName,
                        isSelected: selectedFilter == type,
                        action: { selectedFilter = type }
                    )
                }
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.gymCaption)
                .foregroundColor(isSelected ? .black : .gymTextSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.gymAccent : Color.gymSurface)
                .cornerRadius(20)
        }
    }
}

// MARK: - History Workout Row

struct HistoryWorkoutRow: View {
    let workout: WorkoutSession
    
    var body: some View {
        HStack(spacing: 16) {
            // Date stack
            VStack(spacing: 2) {
                Text(dayOfMonth)
                    .font(.gymHeadline)
                    .foregroundColor(.gymTextPrimary)
                
                Text(dayOfWeek)
                    .font(.gymCaption)
                    .foregroundColor(.gymTextTertiary)
            }
            .frame(width: 44)
            
            // Workout type indicator
            Text(workout.workoutType.rawValue)
                .font(.gymSubheadline)
                .foregroundColor(.gymAccent)
                .frame(width: 32, height: 32)
                .background(Color.gymAccent.opacity(0.15))
                .cornerRadius(8)
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.workoutType.name)
                    .font(.gymSubheadline)
                    .foregroundColor(.gymTextPrimary)
                
                HStack(spacing: 8) {
                    if let energy = workout.energyLevel {
                        Text(energy.emoji)
                    }
                    
                    Text("\(workout.exercises.count) exercises")
                        .font(.gymCaption)
                        .foregroundColor(.gymTextTertiary)
                }
            }
            
            Spacer()
            
            // Volume
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(workout.totalVolume).formatted())")
                    .font(.gymSubheadline)
                    .foregroundColor(.gymTextSecondary)
                
                Text("lbs")
                    .font(.gymCaption)
                    .foregroundColor(.gymTextTertiary)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gymTextTertiary)
        }
        .padding(16)
        .background(Color.gymSurface)
    }
    
    var dayOfMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: workout.startTime)
    }
    
    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: workout.startTime)
    }
}

// MARK: - Empty State

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 48))
                .foregroundColor(.gymTextTertiary)
            
            Text("No workouts yet")
                .font(.gymHeadline)
                .foregroundColor(.gymTextSecondary)
            
            Text("Complete your first workout to see it here")
                .font(.gymBody)
                .foregroundColor(.gymTextTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Workout Detail Sheet

struct WorkoutDetailSheet: View {
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
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text(workout.workoutType.fullName)
                            .font(.gymHeadline)
                            .foregroundColor(.gymTextPrimary)
                        
                        Text(workout.startTime.formatted(date: .complete, time: .shortened))
                            .font(.gymCaption)
                            .foregroundColor(.gymTextTertiary)
                    }
                    .padding(.top, 8)
                    
                    // Stats row
                    HStack(spacing: 16) {
                        DetailStat(value: "\(Int(workout.totalVolume).formatted())", label: "Volume (lbs)")
                        DetailStat(value: workout.formattedDuration, label: "Duration")
                        if let bw = workout.bodyweight {
                            DetailStat(value: "\(Int(bw))", label: "Bodyweight")
                        }
                    }
                    .padding(16)
                    .cardStyle()
                    
                    // Context
                    if workout.energyLevel != nil || workout.sleepQuality != nil {
                        HStack(spacing: 24) {
                            if let energy = workout.energyLevel {
                                HStack(spacing: 8) {
                                    Text("Energy")
                                        .font(.gymCaption)
                                        .foregroundColor(.gymTextTertiary)
                                    Text("\(energy.emoji) \(energy.rawValue)")
                                        .font(.gymSubheadline)
                                        .foregroundColor(.gymTextSecondary)
                                }
                            }
                            
                            if let sleep = workout.sleepQuality {
                                HStack(spacing: 8) {
                                    Text("Sleep")
                                        .font(.gymCaption)
                                        .foregroundColor(.gymTextTertiary)
                                    Text("\(sleep.emoji) \(sleep.rawValue)")
                                        .font(.gymSubheadline)
                                        .foregroundColor(.gymTextSecondary)
                                }
                            }
                        }
                        .padding(16)
                        .cardStyle()
                    }
                    
                    // Exercises
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Exercises")
                            .font(.gymSubheadline)
                            .foregroundColor(.gymTextPrimary)
                        
                        ForEach(workout.exercises) { exercise in
                            ExerciseDetailRow(exercise: exercise)
                        }
                    }
                    .padding(16)
                    .cardStyle()
                    
                    // Workout notes
                    if !workout.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.gymSubheadline)
                                .foregroundColor(.gymTextPrimary)
                            
                            Text(workout.notes)
                                .font(.gymBody)
                                .foregroundColor(.gymTextSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .cardStyle()
                    }
                    
                    // Copy summary button
                    Button(action: copyToClipboard) {
                        HStack {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            Text(copied ? "Copied!" : "Copy Summary for AI Coach")
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding()
            }
            .background(Color.gymBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    func copyToClipboard() {
        UIPasteboard.general.string = summary
        copied = true
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copied = false
        }
    }
}

struct DetailStat: View {
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

struct ExerciseDetailRow: View {
    let exercise: LoggedExercise
    
    var completedWorkingSets: [ExerciseSet] {
        exercise.workingSets.filter { $0.isCompleted }
    }
    
    var setsString: String {
        completedWorkingSets.map { set in
            if let time = set.timeSeconds {
                return "\(time)s"
            } else if let reps = set.reps, let weight = set.weight {
                return "\(Int(weight))×\(reps)"
            }
            return "—"
        }.joined(separator: ", ")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(categoryColor)
                    .frame(width: 8, height: 8)
                
                Text(exercise.exerciseName)
                    .font(.gymSubheadline)
                    .foregroundColor(.gymTextPrimary)
                
                Spacer()
                
                Text("\(Int(exercise.totalVolume).formatted()) lbs")
                    .font(.gymCaption)
                    .foregroundColor(.gymTextTertiary)
            }
            
            Text(setsString)
                .font(.gymCaption)
                .foregroundColor(.gymTextSecondary)
            
            if !exercise.notes.isEmpty {
                Text("→ \(exercise.notes)")
                    .font(.gymCaption)
                    .foregroundColor(.gymTextTertiary)
                    .italic()
            }
        }
        .padding(12)
        .background(Color.gymElevated)
        .cornerRadius(8)
    }
    
    var categoryColor: Color {
        switch exercise.category {
        case .mainLift: return .mainLiftColor
        case .compound: return .compoundColor
        case .accessory: return .accessoryColor
        }
    }
}

// MARK: - Preview

#Preview {
    HistoryView()
        .environmentObject(DataManager())
        .preferredColorScheme(.dark)
}
