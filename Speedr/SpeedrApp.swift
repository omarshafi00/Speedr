//
//  SpeedrApp.swift
//  Speedr
//
//  Reference: PROJECT_SPEC.md - App entry point
//

import SwiftUI

@main
struct SpeedrApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .speedrTheme()
                .preferredColorScheme(.dark) // Default to dark theme
        }
    }
}
