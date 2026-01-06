//
//  Models.swift
//  GymTracker
//
//  Core data models
//

import Foundation

// MARK: - Enums

enum WorkoutType: String, Codable, CaseIterable, Identifiable {
    case benchFocus = "A"
    case squatFocus = "B"
    case ohpBack = "C"
    
    var id: String { rawValue }
    
    var name: String {
        switch self {
        case .benchFocus: return "Bench Focus"
        case .squatFocus: return "Squat Focus"
        case .ohpBack: return "OHP + Back"
        }
    }
    
    var shortName: String {
        "Workout \(rawValue)"
    }
    
    var fullName: String {
        "Workout \(rawValue) – \(name)"
    }
    
    func next() -> WorkoutType {
        switch self {
        case .benchFocus: return .squatFocus
        case .squatFocus: return .ohpBack
        case .ohpBack: return .benchFocus
        }
    }
}

enum SetType: String, Codable, CaseIterable {
    case warmup = "Warm-up"
    case working = "Working"
}

enum ExerciseCategory: String, Codable, CaseIterable {
    case mainLift = "Main Lift"
    case compound = "Compound"
    case accessory = "Accessory"
    
    var defaultRestSeconds: Int {
        switch self {
        case .mainLift: return 150  // 2:30
        case .compound: return 90   // 1:30
        case .accessory: return 60  // 1:00
        }
    }
}

enum Rating: String, Codable, CaseIterable {
    case poor = "Poor"
    case ok = "OK"
    case good = "Good"
    
    var emoji: String {
        switch self {
        case .poor: return "😓"
        case .ok: return "😐"
        case .good: return "💪"
        }
    }
}

// MARK: - Exercise Set

struct ExerciseSet: Identifiable, Codable, Equatable {
    let id: UUID
    var reps: Int?
    var weight: Double?
    var timeSeconds: Int?  // For timed sets (planks, etc.)
    var setType: SetType
    var isCompleted: Bool
    
    init(
        id: UUID = UUID(),
        reps: Int? = nil,
        weight: Double? = nil,
        timeSeconds: Int? = nil,
        setType: SetType = .working,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.reps = reps
        self.weight = weight
        self.timeSeconds = timeSeconds
        self.setType = setType
        self.isCompleted = isCompleted
    }
    
    var isTimeBased: Bool {
        timeSeconds != nil
    }
    
    var volume: Double {
        guard setType == .working, let reps = reps, let weight = weight else { return 0 }
        return Double(reps) * weight
    }
    
    var displayString: String {
        if let time = timeSeconds {
            return "\(time)s @ \(Int(weight ?? 0)) lbs"
        } else if let reps = reps, let weight = weight {
            return "\(reps) × \(Int(weight)) lbs"
        }
        return "—"
    }
}

// MARK: - Logged Exercise

struct LoggedExercise: Identifiable, Codable, Equatable {
    let id: UUID
    var exerciseName: String
    var category: ExerciseCategory
    var sets: [ExerciseSet]
    var notes: String
    var supersetPairId: UUID?  // Links two exercises as a superset
    var restSeconds: Int
    
    init(
        id: UUID = UUID(),
        exerciseName: String,
        category: ExerciseCategory,
        sets: [ExerciseSet] = [],
        notes: String = "",
        supersetPairId: UUID? = nil,
        restSeconds: Int? = nil
    ) {
        self.id = id
        self.exerciseName = exerciseName
        self.category = category
        self.sets = sets
        self.notes = notes
        self.supersetPairId = supersetPairId
        self.restSeconds = restSeconds ?? category.defaultRestSeconds
    }
    
    var workingSets: [ExerciseSet] {
        sets.filter { $0.setType == .working }
    }
    
    var completedWorkingSets: [ExerciseSet] {
        workingSets.filter { $0.isCompleted }
    }
    
    var totalVolume: Double {
        workingSets.reduce(0) { $0 + $1.volume }
    }
    
    var bestSet: ExerciseSet? {
        workingSets
            .filter { $0.isCompleted && $0.reps != nil && $0.weight != nil }
            .max { ($0.weight ?? 0) < ($1.weight ?? 0) || 
                   (($0.weight ?? 0) == ($1.weight ?? 0) && ($0.reps ?? 0) < ($1.reps ?? 0)) }
    }
}

// MARK: - Workout Session

struct WorkoutSession: Identifiable, Codable, Equatable {
    let id: UUID
    let workoutType: WorkoutType
    var exercises: [LoggedExercise]
    var startTime: Date
    var endTime: Date?
    var energyLevel: Rating?
    var sleepQuality: Rating?
    var bodyweight: Double?
    var notes: String
    var isCompleted: Bool
    var isSessionOverride: Bool  // True if exercises differ from template
    
    init(
        id: UUID = UUID(),
        workoutType: WorkoutType,
        exercises: [LoggedExercise] = [],
        startTime: Date = Date(),
        endTime: Date? = nil,
        energyLevel: Rating? = nil,
        sleepQuality: Rating? = nil,
        bodyweight: Double? = nil,
        notes: String = "",
        isCompleted: Bool = false,
        isSessionOverride: Bool = false
    ) {
        self.id = id
        self.workoutType = workoutType
        self.exercises = exercises
        self.startTime = startTime
        self.endTime = endTime
        self.energyLevel = energyLevel
        self.sleepQuality = sleepQuality
        self.bodyweight = bodyweight
        self.notes = notes
        self.isCompleted = isCompleted
        self.isSessionOverride = isSessionOverride
    }
    
    var totalVolume: Double {
        exercises.reduce(0) { $0 + $1.totalVolume }
    }
    
    var duration: TimeInterval? {
        guard let end = endTime else { return nil }
        return end.timeIntervalSince(startTime)
    }
    
    var formattedDuration: String {
        guard let duration = duration else { return "—" }
        let minutes = Int(duration) / 60
        return "\(minutes) min"
    }
    
    var mainLift: LoggedExercise? {
        exercises.first { $0.category == .mainLift }
    }
}

// MARK: - Workout Template

struct ExerciseTemplate: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var category: ExerciseCategory
    var defaultSets: Int
    var defaultReps: Int?
    var defaultTimeSeconds: Int?
    var restSeconds: Int
    
    init(
        id: UUID = UUID(),
        name: String,
        category: ExerciseCategory,
        defaultSets: Int = 3,
        defaultReps: Int? = nil,
        defaultTimeSeconds: Int? = nil,
        restSeconds: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.defaultSets = defaultSets
        self.defaultReps = defaultReps
        self.defaultTimeSeconds = defaultTimeSeconds
        self.restSeconds = restSeconds ?? category.defaultRestSeconds
    }
}

struct WorkoutTemplate: Identifiable, Codable, Equatable {
    let id: UUID
    let workoutType: WorkoutType
    var exercises: [ExerciseTemplate]
    
    init(
        id: UUID = UUID(),
        workoutType: WorkoutType,
        exercises: [ExerciseTemplate] = []
    ) {
        self.id = id
        self.workoutType = workoutType
        self.exercises = exercises
    }
}

// MARK: - Personal Record

struct PersonalRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let exerciseName: String
    let weight: Double
    let reps: Int
    let date: Date
    let workoutSessionId: UUID
    
    init(
        id: UUID = UUID(),
        exerciseName: String,
        weight: Double,
        reps: Int,
        date: Date = Date(),
        workoutSessionId: UUID
    ) {
        self.id = id
        self.exerciseName = exerciseName
        self.weight = weight
        self.reps = reps
        self.date = date
        self.workoutSessionId = workoutSessionId
    }
    
    // PR comparison: higher weight wins, then higher reps at same weight
    func beats(_ other: PersonalRecord) -> Bool {
        if weight > other.weight { return true }
        if weight == other.weight && reps > other.reps { return true }
        return false
    }
}

// MARK: - App State

struct AppState: Codable {
    var nextWorkoutType: WorkoutType
    var templates: [WorkoutTemplate]
    var workoutHistory: [WorkoutSession]
    var personalRecords: [String: PersonalRecord]  // exerciseName -> best PR
    
    init(
        nextWorkoutType: WorkoutType = .benchFocus,
        templates: [WorkoutTemplate] = [],
        workoutHistory: [WorkoutSession] = [],
        personalRecords: [String: PersonalRecord] = [:]
    ) {
        self.nextWorkoutType = nextWorkoutType
        self.templates = templates
        self.workoutHistory = workoutHistory
        self.personalRecords = personalRecords
    }
}
