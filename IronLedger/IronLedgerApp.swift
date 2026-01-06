//
//  IronLedgerApp.swift
//  IronLedger
//
//  A minimal, focused gym tracker for muscle-building
//

import SwiftUI

@main
struct IronLedgerApp: App {
    @StateObject private var dataManager = DataManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .preferredColorScheme(.dark)
        }
    }
}
