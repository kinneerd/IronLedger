//
//  ContentView.swift
//  GymTracker
//
//  Main tab-based navigation
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(1)
            
            ProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(Color.gymAccent)
        .fullScreenCover(item: $dataManager.activeWorkout) { _ in
            ActiveWorkoutView()
                .environmentObject(dataManager)
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(DataManager())
        .preferredColorScheme(.dark)
}
