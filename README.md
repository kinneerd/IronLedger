# Iron Ledger

A minimal, focused iOS fitness tracker app for muscle-building, built with SwiftUI.

## Features

### Core Functionality
- **Fixed Workout Rotation**: A → B → C cycle (Bench Focus, Squat Focus, OHP + Back)
- **Exercise Logging**: Sets, reps, weight with warm-up/working set distinction
- **Rest Timer**: One-tap timer with exercise-specific defaults (2:30 main lifts, 1:30 compounds, 1:00 accessories)
- **Progress Tracking**: PR detection, weight-over-time charts, exercise history
- **Workout Summary Export**: One-tap copy for AI coach consultation

### Design Philosophy
> "My notebook, but it remembers everything and nudges me when it matters."

- Never interrupts your lift
- Never nags
- Never requires thinking mid-set
- Preserves program structure
- Dark mode first, high contrast gym-friendly UI

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Installation

1. Open `IronLedger.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Build and run on your device or simulator

## Project Structure

```
IronLedger/
├── IronLedgerApp.swift          # App entry point
├── Models/
│   └── Models.swift             # Data models (WorkoutSession, Exercise, etc.)
├── Services/
│   └── DataManager.swift        # Local persistence & state management
├── Views/
│   ├── ContentView.swift        # Main tab navigation
│   ├── Theme.swift              # Colors, fonts, button styles
│   ├── Home/
│   │   └── HomeView.swift       # Next workout, quick stats, recent history
│   ├── Workout/
│   │   ├── ActiveWorkoutView.swift      # Main logging screen
│   │   └── CompleteWorkoutSheet.swift   # Completion flow & summary
│   ├── History/
│   │   └── HistoryView.swift    # Past workouts browser
│   ├── Progress/
│   │   └── ProgressView.swift   # Charts & PRs
│   └── Settings/
│       └── SettingsView.swift   # Template editing, app config
└── Assets.xcassets/             # App icons, colors
```

## Default Workout Templates

### Workout A – Bench Focus
1. Bench Press (5×5)
2. Incline Dumbbell Press (3×10)
3. Cable Fly (3×12)
4. Tricep Pushdown (3×12)
5. Lateral Raise (3×15)

### Workout B – Squat Focus
1. Squat (5×5)
2. Romanian Deadlift (3×8)
3. Leg Press (3×10)
4. Leg Curl (3×12)
5. Calf Raise (3×15)

### Workout C – OHP + Back
1. Overhead Press (5×5)
2. Barbell Row (3×8)
3. Pull-ups (3×8)
4. Face Pull (3×15)
5. Bicep Curl (3×12)

## Data Storage

All data is stored locally using UserDefaults. The app persists:
- Workout history
- Personal records
- Custom templates
- Current rotation position

## Workout Summary Format

When you complete a workout, you can copy a summary like this:

```
Workout B – Squat Focus | Jan 5, 2026

Squat: 225×5, 225×5, 225×5, 225×4, 225×4 (RPE 8)
RDL: 185×8, 185×8, 185×8
Leg Press: 360×10, 360×10, 360×10
Leg Curl: 90×12, 90×12, 90×12
Calf Raise: 135×15, 135×15, 135×15

Volume: 18,450 lbs | Duration: 52 min
Energy: OK 😐 | Sleep: Good 💪

Notes: Left knee felt tight during warmup, loosened up after squats.
```

## Future Enhancements (Not in v1)

- Cloud sync/backup
- Plate calculator
- Superset grouping UI
- Apple Watch companion
- HealthKit integration
- Export to CSV

## License

MIT License - feel free to modify and use for your own training!
