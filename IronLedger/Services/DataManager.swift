//
//  DataManager.swift
//  GymTracker
//
//  Handles local persistence and state management
//

import Foundation
import SwiftUI

@MainActor
class DataManager: ObservableObject {
    @Published var appState: AppState
    @Published var activeWorkout: WorkoutSession?
    
    private let saveKey = "IronLedgerAppState"
    
    init() {
        // Load saved state or create default
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode(AppState.self, from: data) {
            self.appState = decoded
        } else {
            self.appState = AppState(templates: Self.defaultTemplates())
        }
    }
    
    // MARK: - Persistence
    
    func save() {
        if let encoded = try? JSONEncoder().encode(appState) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    // MARK: - Workout Management
    
    func startWorkout(type: WorkoutType) {
        guard let template = appState.templates.first(where: { $0.workoutType == type }) else {
            return
        }
        
        // Create exercises from template, pre-filling from last workout of same type
        let lastWorkout = appState.workoutHistory
            .filter { $0.workoutType == type && $0.isCompleted }
            .sorted { $0.startTime > $1.startTime }
            .first
        
        var exercises: [LoggedExercise] = []
        
        for templateExercise in template.exercises {
            // Find this exercise in last workout to copy weights
            let lastExercise = lastWorkout?.exercises.first { $0.exerciseName == templateExercise.name }
            let lastWorkingSets = lastExercise?.workingSets ?? []
            
            var sets: [ExerciseSet] = []
            
            // Add warm-up sets for main lifts
            if templateExercise.category == .mainLift {
                sets.append(ExerciseSet(setType: .warmup))
                sets.append(ExerciseSet(setType: .warmup))
            }
            
            // Add working sets, pre-filled from last workout
            for i in 0..<templateExercise.defaultSets {
                let lastSet = i < lastWorkingSets.count ? lastWorkingSets[i] : nil
                sets.append(ExerciseSet(
                    reps: templateExercise.defaultReps ?? lastSet?.reps,
                    weight: lastSet?.weight,
                    timeSeconds: templateExercise.defaultTimeSeconds,
                    setType: .working
                ))
            }
            
            exercises.append(LoggedExercise(
                exerciseName: templateExercise.name,
                category: templateExercise.category,
                sets: sets,
                restSeconds: templateExercise.restSeconds
            ))
        }
        
        activeWorkout = WorkoutSession(
            workoutType: type,
            exercises: exercises
        )
    }
    
    func completeWorkout() {
        guard var workout = activeWorkout else { return }
        
        workout.endTime = Date()
        workout.isCompleted = true
        
        // Check for PRs
        checkForPRs(in: workout)
        
        // Save to history
        appState.workoutHistory.append(workout)
        
        // Advance rotation
        appState.nextWorkoutType = workout.workoutType.next()
        
        save()
        activeWorkout = nil
    }
    
    func cancelWorkout() {
        activeWorkout = nil
    }

    func setNextWorkout(type: WorkoutType) {
        appState.nextWorkoutType = type
        save()
    }

    // MARK: - PR Tracking
    
    private func checkForPRs(in workout: WorkoutSession) {
        for exercise in workout.exercises {
            guard let bestSet = exercise.bestSet,
                  let weight = bestSet.weight,
                  let reps = bestSet.reps else { continue }
            
            let newPR = PersonalRecord(
                exerciseName: exercise.exerciseName,
                weight: weight,
                reps: reps,
                workoutSessionId: workout.id
            )
            
            if let existingPR = appState.personalRecords[exercise.exerciseName] {
                if newPR.beats(existingPR) {
                    appState.personalRecords[exercise.exerciseName] = newPR
                }
            } else {
                appState.personalRecords[exercise.exerciseName] = newPR
            }
        }
    }
    
    func isPR(exercise: LoggedExercise, set: ExerciseSet) -> Bool {
        guard set.setType == .working,
              set.isCompleted,
              let weight = set.weight,
              let reps = set.reps,
              let existingPR = appState.personalRecords[exercise.exerciseName] else {
            return false
        }
        
        return weight > existingPR.weight || 
               (weight == existingPR.weight && reps > existingPR.reps)
    }
    
    // MARK: - History & Stats
    
    func exerciseHistory(name: String) -> [(date: Date, sets: [ExerciseSet])] {
        appState.workoutHistory
            .filter { $0.isCompleted }
            .sorted { $0.startTime > $1.startTime }
            .compactMap { workout -> (Date, [ExerciseSet])? in
                guard let exercise = workout.exercises.first(where: { $0.exerciseName == name }) else {
                    return nil
                }
                return (workout.startTime, exercise.workingSets.filter { $0.isCompleted })
            }
    }
    
    func workoutHistory(type: WorkoutType) -> [WorkoutSession] {
        appState.workoutHistory
            .filter { $0.workoutType == type && $0.isCompleted }
            .sorted { $0.startTime > $1.startTime }
    }
    
    func recentWorkouts(limit: Int = 10) -> [WorkoutSession] {
        Array(appState.workoutHistory
            .filter { $0.isCompleted }
            .sorted { $0.startTime > $1.startTime }
            .prefix(limit))
    }
    
    // MARK: - Template Management
    
    func updateTemplate(_ template: WorkoutTemplate) {
        if let index = appState.templates.firstIndex(where: { $0.workoutType == template.workoutType }) {
            appState.templates[index] = template
            save()
        }
    }
    
    func getTemplate(for type: WorkoutType) -> WorkoutTemplate? {
        appState.templates.first { $0.workoutType == type }
    }
    
    // MARK: - Default Templates
    
    static func defaultTemplates() -> [WorkoutTemplate] {
        [
            WorkoutTemplate(
                workoutType: .benchFocus,
                exercises: [
                    ExerciseTemplate(name: "Bench Press", category: .mainLift, defaultSets: 5, defaultReps: 5),
                    ExerciseTemplate(name: "Incline Dumbbell Press", category: .compound, defaultSets: 3, defaultReps: 10),
                    ExerciseTemplate(name: "Cable Fly", category: .accessory, defaultSets: 3, defaultReps: 12),
                    ExerciseTemplate(name: "Tricep Pushdown", category: .accessory, defaultSets: 3, defaultReps: 12),
                    ExerciseTemplate(name: "Lateral Raise", category: .accessory, defaultSets: 3, defaultReps: 15)
                ]
            ),
            WorkoutTemplate(
                workoutType: .squatFocus,
                exercises: [
                    ExerciseTemplate(name: "Squat", category: .mainLift, defaultSets: 5, defaultReps: 5),
                    ExerciseTemplate(name: "Romanian Deadlift", category: .compound, defaultSets: 3, defaultReps: 8),
                    ExerciseTemplate(name: "Leg Press", category: .compound, defaultSets: 3, defaultReps: 10),
                    ExerciseTemplate(name: "Leg Curl", category: .accessory, defaultSets: 3, defaultReps: 12),
                    ExerciseTemplate(name: "Calf Raise", category: .accessory, defaultSets: 3, defaultReps: 15)
                ]
            ),
            WorkoutTemplate(
                workoutType: .ohpBack,
                exercises: [
                    ExerciseTemplate(name: "Overhead Press", category: .mainLift, defaultSets: 5, defaultReps: 5),
                    ExerciseTemplate(name: "Barbell Row", category: .compound, defaultSets: 3, defaultReps: 8),
                    ExerciseTemplate(name: "Pull-ups", category: .compound, defaultSets: 3, defaultReps: 8),
                    ExerciseTemplate(name: "Face Pull", category: .accessory, defaultSets: 3, defaultReps: 15),
                    ExerciseTemplate(name: "Bicep Curl", category: .accessory, defaultSets: 3, defaultReps: 12)
                ]
            )
        ]
    }
}

// MARK: - Summary Export

extension WorkoutSession {
    func generateSummary(prs: [String: PersonalRecord]) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        var summary = "\(workoutType.fullName) | \(dateFormatter.string(from: startTime))\n\n"
        
        // Exercises
        for exercise in exercises {
            let workingSets = exercise.workingSets.filter { $0.isCompleted }
            guard !workingSets.isEmpty else { continue }
            
            let setsString = workingSets.map { set -> String in
                if let time = set.timeSeconds {
                    return "\(time)s"
                } else if let reps = set.reps, let weight = set.weight {
                    return "\(Int(weight))×\(reps)"
                }
                return "—"
            }.joined(separator: ", ")
            
            var line = "\(exercise.exerciseName): \(setsString)"
            
            // Check for PR
            if let bestSet = exercise.bestSet,
               let pr = prs[exercise.exerciseName],
               let weight = bestSet.weight,
               let reps = bestSet.reps,
               weight >= pr.weight && reps >= pr.reps {
                line += " 🏆 PR"
            }
            
            summary += line + "\n"
            
            // Exercise notes
            if !exercise.notes.isEmpty {
                summary += "  → \(exercise.notes)\n"
            }
        }
        
        // Stats
        summary += "\nVolume: \(Int(totalVolume).formatted()) lbs"
        if formattedDuration != "—" {
            summary += " | Duration: \(formattedDuration)"
        }
        summary += "\n"
        
        // Context
        if let energy = energyLevel {
            summary += "Energy: \(energy.rawValue) \(energy.emoji)"
        }
        if let sleep = sleepQuality {
            summary += " | Sleep: \(sleep.rawValue) \(sleep.emoji)"
        }
        if energyLevel != nil || sleepQuality != nil {
            summary += "\n"
        }
        
        if let bw = bodyweight {
            summary += "Bodyweight: \(Int(bw)) lbs\n"
        }
        
        // Workout notes
        if !notes.isEmpty {
            summary += "\nNotes: \(notes)\n"
        }
        
        return summary
    }
}
