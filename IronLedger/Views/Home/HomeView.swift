//
//  HomeView.swift
//  GymTracker
//
//  Shows next workout in rotation and recent history
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showWorkoutPicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Next Workout Card
                    NextWorkoutCard(
                        workoutType: dataManager.appState.nextWorkoutType,
                        onStart: {
                            dataManager.startWorkout(type: dataManager.appState.nextWorkoutType)
                        },
                        onChangeWorkout: {
                            showWorkoutPicker = true
                        }
                    )

                    // Quick Stats
                    QuickStatsView()

                    // Recent Workouts
                    RecentWorkoutsSection()
                }
                .padding()
            }
            .background(Color.gymBackground)
            .navigationTitle("Iron Ledger")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showWorkoutPicker) {
                WorkoutPickerSheet()
            }
        }
    }
}

// MARK: - Next Workout Card

struct NextWorkoutCard: View {
    let workoutType: WorkoutType
    let onStart: () -> Void
    let onChangeWorkout: () -> Void

    @EnvironmentObject var dataManager: DataManager

    var template: WorkoutTemplate? {
        dataManager.getTemplate(for: workoutType)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("NEXT UP")
                        .font(.gymCaption)
                        .foregroundColor(.gymTextTertiary)
                        .tracking(1.5)

                    Text(workoutType.fullName)
                        .font(.gymHeadline)
                        .foregroundColor(.gymTextPrimary)
                }

                Spacer()

                // Workout letter badge
                Text(workoutType.rawValue)
                    .font(.gymMediumNumber)
                    .foregroundColor(.gymAccent)
                    .frame(width: 56, height: 56)
                    .background(Color.gymAccent.opacity(0.15))
                    .cornerRadius(12)
            }

            // Change workout button
            Button(action: onChangeWorkout) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 12, weight: .medium))
                    Text("Change Workout")
                        .font(.gymCaption)
                }
                .foregroundColor(.gymTextSecondary)
            }
            .buttonStyle(.plain)
            
            // Exercise preview
            if let template = template {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(template.exercises.prefix(3)) { exercise in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(categoryColor(exercise.category))
                                .frame(width: 6, height: 6)
                            
                            Text(exercise.name)
                                .font(.gymBody)
                                .foregroundColor(.gymTextSecondary)
                            
                            Spacer()
                            
                            Text("\(exercise.defaultSets)×\(exercise.defaultReps ?? 0)")
                                .font(.gymCaption)
                                .foregroundColor(.gymTextTertiary)
                        }
                    }
                    
                    if template.exercises.count > 3 {
                        Text("+\(template.exercises.count - 3) more")
                            .font(.gymCaption)
                            .foregroundColor(.gymTextTertiary)
                            .padding(.leading, 14)
                    }
                }
                .padding(.top, 4)
            }
            
            // Start Button
            Button(action: onStart) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start Workout")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.top, 8)
        }
        .padding(20)
        .cardStyle()
    }
    
    func categoryColor(_ category: ExerciseCategory) -> Color {
        switch category {
        case .mainLift: return .mainLiftColor
        case .compound: return .compoundColor
        case .accessory: return .accessoryColor
        }
    }
}

// MARK: - Quick Stats

struct QuickStatsView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var thisWeekWorkouts: Int {
        let calendar = Calendar.current
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) else {
            return 0
        }
        return dataManager.appState.workoutHistory.filter {
            $0.isCompleted && $0.startTime >= startOfWeek
        }.count
    }
    
    var totalWorkouts: Int {
        dataManager.appState.workoutHistory.filter { $0.isCompleted }.count
    }
    
    var totalPRs: Int {
        dataManager.appState.personalRecords.count
    }
    
    var body: some View {
        HStack(spacing: 12) {
            StatBox(title: "This Week", value: "\(thisWeekWorkouts)", subtitle: "workouts")
            StatBox(title: "Total", value: "\(totalWorkouts)", subtitle: "sessions")
            StatBox(title: "PRs", value: "\(totalPRs)", subtitle: "records", valueColor: .gymSuccess)
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let subtitle: String
    var valueColor: Color = .gymTextPrimary
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.gymCaption)
                .foregroundColor(.gymTextTertiary)
            
            Text(value)
                .font(.gymMediumNumber)
                .foregroundColor(valueColor)
            
            Text(subtitle)
                .font(.gymCaption)
                .foregroundColor(.gymTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .cardStyle()
    }
}

// MARK: - Recent Workouts Section

struct RecentWorkoutsSection: View {
    @EnvironmentObject var dataManager: DataManager
    
    var recentWorkouts: [WorkoutSession] {
        dataManager.recentWorkouts(limit: 5)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Workouts")
                .font(.gymHeadline)
                .foregroundColor(.gymTextPrimary)
            
            if recentWorkouts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 40))
                        .foregroundColor(.gymTextTertiary)
                    
                    Text("No workouts yet")
                        .font(.gymBody)
                        .foregroundColor(.gymTextSecondary)
                    
                    Text("Start your first workout to see your history here")
                        .font(.gymCaption)
                        .foregroundColor(.gymTextTertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .cardStyle()
            } else {
                VStack(spacing: 1) {
                    ForEach(recentWorkouts) { workout in
                        RecentWorkoutRow(workout: workout)
                    }
                }
                .cornerRadius(16)
            }
        }
    }
}

struct RecentWorkoutRow: View {
    let workout: WorkoutSession
    
    var body: some View {
        HStack(spacing: 16) {
            // Workout type badge
            Text(workout.workoutType.rawValue)
                .font(.gymHeadline)
                .foregroundColor(.gymAccent)
                .frame(width: 44, height: 44)
                .background(Color.gymAccent.opacity(0.15))
                .cornerRadius(10)
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.workoutType.name)
                    .font(.gymSubheadline)
                    .foregroundColor(.gymTextPrimary)
                
                Text(workout.startTime.formatted(date: .abbreviated, time: .omitted))
                    .font(.gymCaption)
                    .foregroundColor(.gymTextTertiary)
            }
            
            Spacer()
            
            // Volume
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(workout.totalVolume).formatted()) lbs")
                    .font(.gymSubheadline)
                    .foregroundColor(.gymTextSecondary)
                
                if workout.formattedDuration != "—" {
                    Text(workout.formattedDuration)
                        .font(.gymCaption)
                        .foregroundColor(.gymTextTertiary)
                }
            }
        }
        .padding(16)
        .background(Color.gymSurface)
    }
}

// MARK: - Workout Picker Sheet

struct WorkoutPickerSheet: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Choose Workout")
                        .font(.gymTitle)
                        .foregroundColor(.gymTextPrimary)

                    Text("Select any workout to override the rotation")
                        .font(.gymBody)
                        .foregroundColor(.gymTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)
                .padding(.bottom, 32)

                // Workout options
                VStack(spacing: 12) {
                    ForEach(WorkoutType.allCases) { workoutType in
                        WorkoutPickerRow(
                            workoutType: workoutType,
                            isNext: workoutType == dataManager.appState.nextWorkoutType,
                            onSelect: {
                                dataManager.setNextWorkout(type: workoutType)
                                dismiss()
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .background(Color.gymBackground)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gymTextSecondary)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct WorkoutPickerRow: View {
    let workoutType: WorkoutType
    let isNext: Bool
    let onSelect: () -> Void

    @EnvironmentObject var dataManager: DataManager

    var template: WorkoutTemplate? {
        dataManager.getTemplate(for: workoutType)
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Workout letter badge
                Text(workoutType.rawValue)
                    .font(.gymHeadline)
                    .foregroundColor(isNext ? .gymAccent : .gymTextSecondary)
                    .frame(width: 48, height: 48)
                    .background((isNext ? Color.gymAccent : Color.gymTextSecondary).opacity(0.15))
                    .cornerRadius(10)

                // Workout details
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(workoutType.name)
                            .font(.gymSubheadline)
                            .foregroundColor(.gymTextPrimary)

                        if isNext {
                            Text("NEXT")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.gymAccent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gymAccent.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }

                    if let template = template {
                        Text(template.exercises.map { $0.name }.prefix(3).joined(separator: ", "))
                            .font(.gymCaption)
                            .foregroundColor(.gymTextTertiary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gymTextTertiary)
            }
            .padding(16)
            .background(Color.gymSurface)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .environmentObject(DataManager())
        .preferredColorScheme(.dark)
}
