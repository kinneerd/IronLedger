//
//  SettingsView.swift
//  GymTracker
//
//  Template editing and app settings
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedTemplate: WorkoutTemplate?
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Workout Templates
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Workout Templates")
                            .font(.gymHeadline)
                            .foregroundColor(.gymTextPrimary)
                        
                        Text("Customize exercises for each workout type")
                            .font(.gymCaption)
                            .foregroundColor(.gymTextTertiary)
                        
                        ForEach(dataManager.appState.templates) { template in
                            TemplateRow(template: template)
                                .onTapGesture {
                                    selectedTemplate = template
                                }
                        }
                    }
                    .padding(16)
                    .cardStyle()
                    
                    // Current Rotation
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Current Rotation")
                            .font(.gymHeadline)
                            .foregroundColor(.gymTextPrimary)
                        
                        HStack(spacing: 16) {
                            ForEach(WorkoutType.allCases) { type in
                                RotationIndicator(
                                    type: type,
                                    isNext: type == dataManager.appState.nextWorkoutType
                                )
                            }
                        }
                        
                        Text("Next: \(dataManager.appState.nextWorkoutType.fullName)")
                            .font(.gymCaption)
                            .foregroundColor(.gymTextTertiary)
                    }
                    .padding(16)
                    .cardStyle()
                    
                    // Stats
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Statistics")
                            .font(.gymHeadline)
                            .foregroundColor(.gymTextPrimary)
                        
                        HStack {
                            Text("Total Workouts")
                                .font(.gymBody)
                                .foregroundColor(.gymTextSecondary)
                            Spacer()
                            Text("\(dataManager.appState.workoutHistory.filter { $0.isCompleted }.count)")
                                .font(.gymSubheadline)
                                .foregroundColor(.gymTextPrimary)
                        }
                        
                        HStack {
                            Text("Personal Records")
                                .font(.gymBody)
                                .foregroundColor(.gymTextSecondary)
                            Spacer()
                            Text("\(dataManager.appState.personalRecords.count)")
                                .font(.gymSubheadline)
                                .foregroundColor(.gymSuccess)
                        }
                        
                        HStack {
                            Text("Total Volume Lifted")
                                .font(.gymBody)
                                .foregroundColor(.gymTextSecondary)
                            Spacer()
                            Text("\(totalVolume.formatted()) lbs")
                                .font(.gymSubheadline)
                                .foregroundColor(.gymTextPrimary)
                        }
                    }
                    .padding(16)
                    .cardStyle()
                    
                    // Reset Data
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Data Management")
                            .font(.gymHeadline)
                            .foregroundColor(.gymTextPrimary)
                        
                        Button(action: { showingResetAlert = true }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Reset All Data")
                            }
                            .font(.gymBody)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        Text("This will delete all workout history, PRs, and reset templates to defaults.")
                            .font(.gymCaption)
                            .foregroundColor(.gymTextTertiary)
                    }
                    .padding(16)
                    .cardStyle()
                    
                    // App Info
                    VStack(spacing: 8) {
                        Text("Iron Ledger")
                            .font(.gymCaption)
                            .foregroundColor(.gymTextTertiary)
                        
                        Text("v1.0")
                            .font(.gymCaption)
                            .foregroundColor(.gymTextTertiary)
                    }
                    .padding(.top, 20)
                }
                .padding()
            }
            .background(Color.gymBackground)
            .navigationTitle("Settings")
            .sheet(item: $selectedTemplate) { template in
                TemplateEditorSheet(template: template)
                    .environmentObject(dataManager)
            }
            .alert("Reset All Data?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("This cannot be undone. All your workout history and PRs will be permanently deleted.")
            }
        }
    }
    
    var totalVolume: Int {
        Int(dataManager.appState.workoutHistory
            .filter { $0.isCompleted }
            .reduce(0) { $0 + $1.totalVolume })
    }
    
    func resetAllData() {
        dataManager.appState = AppState(templates: DataManager.defaultTemplates())
        dataManager.save()
    }
}

// MARK: - Template Row

struct TemplateRow: View {
    let template: WorkoutTemplate
    
    var body: some View {
        HStack(spacing: 16) {
            Text(template.workoutType.rawValue)
                .font(.gymHeadline)
                .foregroundColor(.gymAccent)
                .frame(width: 40, height: 40)
                .background(Color.gymAccent.opacity(0.15))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(template.workoutType.name)
                    .font(.gymSubheadline)
                    .foregroundColor(.gymTextPrimary)
                
                Text("\(template.exercises.count) exercises")
                    .font(.gymCaption)
                    .foregroundColor(.gymTextTertiary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gymTextTertiary)
        }
        .padding(12)
        .background(Color.gymElevated)
        .cornerRadius(12)
    }
}

// MARK: - Rotation Indicator

struct RotationIndicator: View {
    let type: WorkoutType
    let isNext: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Text(type.rawValue)
                .font(.gymHeadline)
                .foregroundColor(isNext ? .black : .gymTextSecondary)
                .frame(width: 44, height: 44)
                .background(isNext ? Color.gymAccent : Color.gymElevated)
                .cornerRadius(10)
            
            if isNext {
                Circle()
                    .fill(Color.gymAccent)
                    .frame(width: 6, height: 6)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 6, height: 6)
            }
        }
    }
}

// MARK: - Template Editor Sheet

struct TemplateEditorSheet: View {
    let template: WorkoutTemplate
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    
    @State private var exercises: [ExerciseTemplate]
    @State private var showingAddExercise = false
    @State private var editingExercise: ExerciseTemplate?
    
    init(template: WorkoutTemplate) {
        self.template = template
        _exercises = State(initialValue: template.exercises)
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(exercises) { exercise in
                        ExerciseTemplateRow(exercise: exercise)
                            .onTapGesture {
                                editingExercise = exercise
                            }
                    }
                    .onDelete(perform: deleteExercise)
                    .onMove(perform: moveExercise)
                    
                    Button(action: { showingAddExercise = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.gymAccent)
                            Text("Add Exercise")
                                .foregroundColor(.gymAccent)
                        }
                    }
                } header: {
                    Text("Exercises")
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.gymBackground)
            .navigationTitle(template.workoutType.fullName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTemplate()
                    }
                    .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingAddExercise) {
                ExerciseEditorSheet(
                    exercise: nil,
                    onSave: { newExercise in
                        exercises.append(newExercise)
                    }
                )
            }
            .sheet(item: $editingExercise) { exercise in
                ExerciseEditorSheet(
                    exercise: exercise,
                    onSave: { updatedExercise in
                        if let index = exercises.firstIndex(where: { $0.id == exercise.id }) {
                            exercises[index] = updatedExercise
                        }
                    }
                )
            }
        }
    }
    
    func deleteExercise(at offsets: IndexSet) {
        exercises.remove(atOffsets: offsets)
    }
    
    func moveExercise(from source: IndexSet, to destination: Int) {
        exercises.move(fromOffsets: source, toOffset: destination)
    }
    
    func saveTemplate() {
        var updatedTemplate = template
        updatedTemplate.exercises = exercises
        dataManager.updateTemplate(updatedTemplate)
        dismiss()
    }
}

struct ExerciseTemplateRow: View {
    let exercise: ExerciseTemplate
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(categoryColor)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.gymBody)
                    .foregroundColor(.gymTextPrimary)
                
                Text("\(exercise.category.rawValue) • \(exercise.defaultSets)×\(exercise.defaultReps ?? 0)")
                    .font(.gymCaption)
                    .foregroundColor(.gymTextTertiary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    var categoryColor: Color {
        switch exercise.category {
        case .mainLift: return .mainLiftColor
        case .compound: return .compoundColor
        case .accessory: return .accessoryColor
        }
    }
}

// MARK: - Exercise Editor Sheet

struct ExerciseEditorSheet: View {
    let exercise: ExerciseTemplate?
    let onSave: (ExerciseTemplate) -> Void
    
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var category: ExerciseCategory = .compound
    @State private var defaultSets: Int = 3
    @State private var defaultReps: Int = 10
    @State private var restSeconds: Int = 90
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise Name") {
                    TextField("e.g., Bench Press", text: $name)
                }
                
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(ExerciseCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: category) { _, newValue in
                        restSeconds = newValue.defaultRestSeconds
                    }
                }
                
                Section("Defaults") {
                    Stepper("Sets: \(defaultSets)", value: $defaultSets, in: 1...10)
                    Stepper("Reps: \(defaultReps)", value: $defaultReps, in: 1...30)
                }
                
                Section("Rest Timer") {
                    Picker("Rest Time", selection: $restSeconds) {
                        Text("0:45").tag(45)
                        Text("1:00").tag(60)
                        Text("1:30").tag(90)
                        Text("2:00").tag(120)
                        Text("2:30").tag(150)
                        Text("3:00").tag(180)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.gymBackground)
            .navigationTitle(exercise == nil ? "Add Exercise" : "Edit Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let newExercise = ExerciseTemplate(
                            id: exercise?.id ?? UUID(),
                            name: name.trimmingCharacters(in: .whitespaces),
                            category: category,
                            defaultSets: defaultSets,
                            defaultReps: defaultReps,
                            restSeconds: restSeconds
                        )
                        onSave(newExercise)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                if let exercise = exercise {
                    name = exercise.name
                    category = exercise.category
                    defaultSets = exercise.defaultSets
                    defaultReps = exercise.defaultReps ?? 10
                    restSeconds = exercise.restSeconds
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(DataManager())
        .preferredColorScheme(.dark)
}
