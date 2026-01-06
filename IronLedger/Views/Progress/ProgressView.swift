//
//  ProgressView.swift
//  GymTracker
//
//  Charts and progress tracking per exercise
//

import SwiftUI
import Charts

struct ProgressView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedExercise: String?
    
    var allExerciseNames: [String] {
        var names = Set<String>()
        for workout in dataManager.appState.workoutHistory where workout.isCompleted {
            for exercise in workout.exercises {
                names.insert(exercise.exerciseName)
            }
        }
        return names.sorted()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // PRs Overview
                    PRsOverviewSection()
                    
                    // Exercise selector
                    if !allExerciseNames.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Exercise Progress")
                                .font(.gymHeadline)
                                .foregroundColor(.gymTextPrimary)
                            
                            ExerciseSelector(
                                exercises: allExerciseNames,
                                selected: $selectedExercise
                            )
                            
                            if let exercise = selectedExercise {
                                ExerciseProgressCard(exerciseName: exercise)
                            }
                        }
                    } else {
                        EmptyProgressView()
                    }
                }
                .padding()
            }
            .background(Color.gymBackground)
            .navigationTitle("Progress")
        }
        .onAppear {
            if selectedExercise == nil, let first = allExerciseNames.first {
                selectedExercise = first
            }
        }
    }
}

// MARK: - PRs Overview

struct PRsOverviewSection: View {
    @EnvironmentObject var dataManager: DataManager
    
    var topPRs: [(String, PersonalRecord)] {
        Array(dataManager.appState.personalRecords
            .sorted { $0.value.weight > $1.value.weight }
            .prefix(5))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.gymSuccess)
                
                Text("Personal Records")
                    .font(.gymHeadline)
                    .foregroundColor(.gymTextPrimary)
            }
            
            if topPRs.isEmpty {
                Text("Complete workouts to set PRs")
                    .font(.gymBody)
                    .foregroundColor(.gymTextTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(topPRs, id: \.0) { name, pr in
                        HStack {
                            Text(name)
                                .font(.gymBody)
                                .foregroundColor(.gymTextSecondary)
                            
                            Spacer()
                            
                            Text("\(Int(pr.weight)) lbs × \(pr.reps)")
                                .font(.gymSubheadline)
                                .foregroundColor(.gymSuccess)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.gymElevated)
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(16)
        .cardStyle()
    }
}

// MARK: - Exercise Selector

struct ExerciseSelector: View {
    let exercises: [String]
    @Binding var selected: String?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(exercises, id: \.self) { exercise in
                    Button(action: { selected = exercise }) {
                        Text(exercise)
                            .font(.gymCaption)
                            .foregroundColor(selected == exercise ? .black : .gymTextSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selected == exercise ? Color.gymAccent : Color.gymSurface)
                            .cornerRadius(16)
                    }
                }
            }
        }
    }
}

// MARK: - Exercise Progress Card

struct ExerciseProgressCard: View {
    let exerciseName: String
    @EnvironmentObject var dataManager: DataManager
    
    var history: [(date: Date, weight: Double, reps: Int)] {
        dataManager.exerciseHistory(name: exerciseName)
            .flatMap { date, sets -> [(Date, Double, Int)] in
                sets.compactMap { set in
                    guard let weight = set.weight, let reps = set.reps else { return nil }
                    return (date, weight, reps)
                }
            }
            .sorted { $0.0 < $1.0 }
    }
    
    var bestWeightHistory: [(date: Date, weight: Double)] {
        // Group by date and get max weight per session
        let grouped = Dictionary(grouping: history) { item -> String in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: item.date)
        }
        
        return grouped.compactMap { _, items -> (Date, Double)? in
            guard let maxItem = items.max(by: { $0.weight < $1.weight }) else { return nil }
            return (maxItem.date, maxItem.weight)
        }.sorted { $0.0 < $1.0 }
    }
    
    var pr: PersonalRecord? {
        dataManager.appState.personalRecords[exerciseName]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // PR badge
            if let pr = pr {
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.gymSuccess)
                    
                    Text("PR: \(Int(pr.weight)) lbs × \(pr.reps)")
                        .font(.gymSubheadline)
                        .foregroundColor(.gymSuccess)
                    
                    Spacer()
                    
                    Text(pr.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.gymCaption)
                        .foregroundColor(.gymTextTertiary)
                }
                .padding(12)
                .background(Color.gymSuccess.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Weight over time chart
            if bestWeightHistory.count >= 2 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weight Over Time")
                        .font(.gymCaption)
                        .foregroundColor(.gymTextTertiary)
                    
                    Chart {
                        ForEach(bestWeightHistory, id: \.date) { item in
                            LineMark(
                                x: .value("Date", item.date),
                                y: .value("Weight", item.weight)
                            )
                            .foregroundStyle(Color.gymAccent)
                            .interpolationMethod(.catmullRom)
                            
                            PointMark(
                                x: .value("Date", item.date),
                                y: .value("Weight", item.weight)
                            )
                            .foregroundStyle(Color.gymAccent)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisGridLine()
                                .foregroundStyle(Color.gymTextTertiary.opacity(0.2))
                            AxisValueLabel()
                                .foregroundStyle(Color.gymTextTertiary)
                        }
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel()
                                .foregroundStyle(Color.gymTextTertiary)
                        }
                    }
                    .frame(height: 200)
                }
            } else {
                Text("Complete more workouts to see progress charts")
                    .font(.gymBody)
                    .foregroundColor(.gymTextTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            }
            
            // Recent history
            if !history.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Sessions")
                        .font(.gymCaption)
                        .foregroundColor(.gymTextTertiary)
                    
                    let recentHistory = Array(dataManager.exerciseHistory(name: exerciseName).prefix(5))
                    
                    ForEach(recentHistory, id: \.date) { date, sets in
                        HStack {
                            Text(date.formatted(date: .abbreviated, time: .omitted))
                                .font(.gymCaption)
                                .foregroundColor(.gymTextTertiary)
                                .frame(width: 80, alignment: .leading)
                            
                            Text(sets.map { set in
                                if let reps = set.reps, let weight = set.weight {
                                    return "\(Int(weight))×\(reps)"
                                }
                                return "—"
                            }.joined(separator: ", "))
                            .font(.gymCaption)
                            .foregroundColor(.gymTextSecondary)
                            
                            Spacer()
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .padding(16)
        .cardStyle()
    }
}

// MARK: - Empty State

struct EmptyProgressView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.gymTextTertiary)
            
            Text("No progress data yet")
                .font(.gymHeadline)
                .foregroundColor(.gymTextSecondary)
            
            Text("Complete workouts to track your progress over time")
                .font(.gymBody)
                .foregroundColor(.gymTextTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Preview

#Preview {
    ProgressView()
        .environmentObject(DataManager())
        .preferredColorScheme(.dark)
}
