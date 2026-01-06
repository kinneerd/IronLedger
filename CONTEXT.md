# Iron Ledger — Project Context

## Overview

Iron Ledger is a minimal, focused iOS gym tracker app built with SwiftUI for muscle-building. It follows a specific design philosophy:

> "My notebook, but it remembers everything and nudges me when it matters."

**Core Principles:**
- Never interrupt a lift
- Never nag
- Never require thinking mid-set
- Preserve program structure
- User stays in control

---

## Workout Structure

The app supports a 3-workout rotation:
- **Workout A** — Bench Focus
- **Workout B** — Squat Focus
- **Workout C** — OHP + Back

Each workout has ~5 exercises: 1 main lift, 2–3 compounds, 1–2 accessories. The app tracks which workout is next in the rotation but should allow manual override.

---

## Project Structure

```
IronLedger/
├── IronLedgerApp.swift           # App entry point
├── Models/
│   └── Models.swift              # Data types: WorkoutSession, LoggedExercise, ExerciseSet, WorkoutTemplate, PersonalRecord, etc.
├── Services/
│   └── DataManager.swift         # State management, local persistence (UserDefaults), PR tracking, workout history
├── Views/
│   ├── ContentView.swift         # Tab navigation (Home, History, Progress, Settings)
│   ├── Theme.swift               # Colors, fonts, button styles (dark mode first)
│   ├── Home/
│   │   └── HomeView.swift        # Next workout card, quick stats, recent history
│   ├── Workout/
│   │   ├── ActiveWorkoutView.swift      # Main logging screen, exercise cards, set rows, rest timer
│   │   └── CompleteWorkoutSheet.swift   # Workout completion flow, summary export
│   ├── History/
│   │   └── HistoryView.swift     # Past workouts browser with filtering
│   ├── Progress/
│   │   └── ProgressView.swift    # PR list, exercise charts (using Swift Charts)
│   └── Settings/
│       └── SettingsView.swift    # Template editing, rotation display, data reset
```

---

## Key Technical Details

- **iOS 17+**, **SwiftUI**, **Swift Charts**
- **Local storage only** via UserDefaults (key: `IronLedgerAppState`)
- **Dark mode first** — high contrast, gym-friendly UI
- **Color palette**: `Color.gymBackground`, `Color.gymSurface`, `Color.gymAccent` (orange), `Color.gymSuccess` (green for PRs)

---

## Data Model Summary

- `WorkoutSession` — A single logged workout (exercises, start/end time, energy, sleep, notes)
- `LoggedExercise` — Exercise within a workout (name, category, sets, notes)
- `ExerciseSet` — Individual set (reps, weight, setType: warmup/working, isCompleted)
- `WorkoutTemplate` — Default exercises for each workout type (A/B/C)
- `PersonalRecord` — Best weight × reps for an exercise

---

## Current Features

### Workout Management
- Fixed A → B → C rotation with automatic next workout tracking
- Manual workout selection (choose any workout A/B/C to override the rotation)
- Real-time workout duration timer
- Exercise logging with warm-up/working set distinction
- Add/remove sets dynamically during workout
- Per-exercise notes
- Workout-level notes
- Cancel workout with confirmation

### Logging Enhancements
- Previous workout comparison (shows last session's numbers inline while logging, e.g., "Last: 225×5")
- Quick weight adjustments (+5 / -5 lb buttons for fast weight changes)
- Pre-filled weights from previous workout of same type
- Collapsible exercise cards with progress indicators

### Rest Timer
- Auto-triggered rest timer when completing sets
- Exercise-specific defaults (2:30 main lifts, 1:30 compounds, 1:00 accessories)
- +30s quick adjustment
- Skip rest option
- Circular progress indicator
- Haptic feedback on completion
- Bible verse display during rest (30 curated motivational verses, can be toggled off in Settings)

### Progress Tracking
- Automatic PR detection and tracking
- Weight-over-time charts per exercise (using Swift Charts)
- Exercise history with per-session breakdown
- Top 5 PRs display
- PR indicators in workout summaries

### Workout Completion
- Required context capture (energy level, sleep quality)
- Optional bodyweight tracking
- Optional workout notes
- Celebration screen with new PRs highlighted
- One-tap summary copy for AI coach consultation

### History & Analytics
- Complete workout history browser
- Filter by workout type (A/B/C) or view all
- Grouped by month display
- Workout detail view with full exercise breakdown
- Total volume, duration, energy, and sleep tracking
- Copy past workout summaries

### Template Management
- Customizable workout templates (3 default: A, B, C)
- Add/edit/remove exercises from templates
- Reorder exercises
- Set default sets, reps, and rest timers per exercise
- Category assignment (main lift, compound, accessory)
- Reset to default templates option

### Data & Settings
- Local persistence via UserDefaults
- Total workout count
- Personal records count
- Total volume lifted (lifetime)
- Current rotation indicator
- Bible verse toggle (enable/disable during rest)
- Reset all data option

### UI/UX
- Dark mode first, high contrast gym-friendly design
- Custom theme (deep black background, orange accent)
- Tab-based navigation (Home, History, Progress, Settings)
- Minimal, distraction-free interface
- Monospaced digits for numbers
- Category color coding (orange for main lifts, blue for compounds, purple for accessories)

---

## Feature Backlog (To Implement)

| Priority | Feature | Description |
|----------|---------|-------------|
| 5 | Exercise search library | Searchable database when adding exercises |

---

## Code Style Notes

- Views use custom modifiers: `.cardStyle()`, `.elevatedCardStyle()`
- Button styles: `PrimaryButtonStyle`, `SecondaryButtonStyle`, `CompactButtonStyle`
- Fonts: `.gymTitle`, `.gymHeadline`, `.gymSubheadline`, `.gymBody`, `.gymCaption`
- DataManager is passed via `.environmentObject(dataManager)`

---

## Units

- All weights are in **lbs** (no kg toggle needed)
- Rest timer defaults:
  - Main lifts: 2:30 (150 seconds)
  - Compounds: 1:30 (90 seconds)
  - Accessories: 1:00 (60 seconds)

---

## Summary Export Format

When a workout is completed, users can copy a plain-text summary for their AI coach:

```
Workout B – Squat Focus | Jan 5, 2026

Squat: 225×5, 225×5, 225×5, 225×4, 225×4
RDL: 185×8, 185×8, 185×8
Leg Press: 360×10, 360×10, 360×10
Leg Curl: 90×12, 90×12, 90×12
Calf Raise: 135×15, 135×15, 135×15

Volume: 18,450 lbs | Duration: 52 min
Energy: OK 😐 | Sleep: Good 💪

Notes: Left knee felt tight during warmup, loosened up after squats.
```

---

## Design Philosophy Reminders

When implementing new features, always ask:
1. Does this interrupt the user mid-lift? (Don't)
2. Does this require thinking during a set? (Simplify)
3. Does this preserve program structure? (Keep it clean)
4. Is this the minimal UI needed? (No clutter)

The app should feel like a smart notebook — always ready, never in the way.
