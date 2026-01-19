//
//  ContentView.swift
//  Speedr
//
//  Reference: PROJECT_SPEC.md - Main tab view with 3 tabs
//

import SwiftUI

/// Main container view with bottom tab navigation
struct ContentView: View {
    @State private var selectedTab: Tab = .home

    enum Tab: String, CaseIterable {
        case library
        case home
        case settings

        var title: String {
            switch self {
            case .library: return "Library"
            case .home: return "Home"
            case .settings: return "Settings"
            }
        }

        var icon: String {
            switch self {
            case .library: return "book.fill"
            case .home: return "house.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            LibraryView()
                .tabItem {
                    Label(Tab.library.title, systemImage: Tab.library.icon)
                }
                .tag(Tab.library)

            HomeView()
                .tabItem {
                    Label(Tab.home.title, systemImage: Tab.home.icon)
                }
                .tag(Tab.home)

            SettingsView()
                .tabItem {
                    Label(Tab.settings.title, systemImage: Tab.settings.icon)
                }
                .tag(Tab.settings)
        }
        .tint(ThemeColors.accentBlue)
    }
}

#Preview {
    ContentView()
        .speedrTheme()
        .preferredColorScheme(.dark)
}
