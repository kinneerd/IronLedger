# Iron Ledger

A minimal, focused iOS fitness tracker app for muscle-building, built with SwiftUI.

## Features

### Workout Management
- **Fixed Workout Rotation**: A → B → C cycle with automatic next workout tracking
- **Manual Workout Selection**: Choose any workout (A/B/C) to override the rotation
- **Real-time Duration Tracking**: Live timer showing workout duration
- **Exercise Logging**: Sets, reps, weight with warm-up/working set distinction
- **Dynamic Set Management**: Add/remove sets on the fly during workout
- **Notes System**: Per-exercise and workout-level notes
- **Smart Pre-filling**: Weights auto-filled from your last session of the same workout type

### Logging Enhancements
- **Previous Workout Comparison**: See last session's numbers inline while logging (e.g., "Last: 225×5")
- **Quick Weight Adjustments**: +5 / -5 lb buttons for fast weight changes without typing
- **Collapsible Exercise Cards**: Minimize exercises you're not working on with progress indicators

### Rest Timer
- **Auto-triggered Timer**: Automatically starts when you complete a set
- **Exercise-specific Defaults**: 2:30 main lifts, 1:30 compounds, 1:00 accessories
- **Quick Adjustments**: +30s button and skip option
- **Visual Feedback**: Circular progress indicator with haptic feedback on completion

### Progress Tracking
- **Automatic PR Detection**: App detects and celebrates new personal records
- **Weight-over-Time Charts**: Visual progress per exercise using Swift Charts
- **Exercise History**: Detailed breakdown of every session for each exercise
- **Top PRs Display**: See your 5 strongest lifts at a glance
- **PR Indicators**: Workout summaries automatically highlight new records

### Workout Completion
- **Context Capture**: Required energy level and sleep quality tracking
- **Optional Tracking**: Bodyweight and workout notes
- **Celebration Screen**: New PRs highlighted with trophy indicators
- **AI Coach Export**: One-tap copy of formatted summary for AI coach consultation

### History & Analytics
- **Complete History Browser**: Browse all past workouts
- **Smart Filtering**: Filter by workout type (A/B/C) or view all
- **Monthly Grouping**: Workouts organized by month for easy navigation
- **Detailed Workout View**: Full exercise breakdown with volume and duration
- **Copy Past Summaries**: Share any historical workout summary

### Template Management
- **Customizable Templates**: Modify the 3 default workout templates (A, B, C)
- **Full Exercise Control**: Add, edit, remove, and reorder exercises
- **Per-exercise Settings**: Set default sets, reps, rest timers, and categories
- **Category System**: Main lifts, compounds, and accessories with color coding
- **Reset Option**: Restore default templates anytime

### Data & Statistics
- **Local Storage**: All data stored locally using UserDefaults (no cloud required)
- **Lifetime Stats**: Total workouts, personal records count, total volume lifted
- **Rotation Indicator**: Visual display of current position in A/B/C cycle
- **Data Management**: Reset all data option with confirmation

### Design & UX
- **Dark Mode First**: High contrast, gym-friendly interface designed for low light
- **Minimal & Focused**: Zero distractions, maximum clarity
- **Custom Theme**: Deep black background with vibrant orange accent
- **Tab Navigation**: Quick access to Home, History, Progress, and Settings
- **Monospaced Numbers**: Easy-to-read digits for weights and reps
- **Color Coding**: Orange (main lifts), blue (compounds), purple (accessories)

## Design Philosophy

> "My notebook, but it remembers everything and nudges me when it matters."

- Never interrupts your lift
- Never nags
- Never requires thinking mid-set
- Preserves program structure
- User stays in control

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

## Roadmap

### Planned Features
- **Rest Timer Auto-start**: Option to automatically start timer when completing a set
- **Bible Verse on Rest Timer**: Display motivating scripture during rest periods
- **Exercise Search Library**: Searchable database when adding exercises

### Future Enhancements
- Cloud sync/backup
- Plate calculator
- Superset grouping UI
- Apple Watch companion
- HealthKit integration
- Export to CSV

## License

MIT License - feel free to modify and use for your own training!
