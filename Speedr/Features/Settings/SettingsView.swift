//
//  SettingsView.swift
//  Speedr
//
//  Reference: PROJECT_SPEC.md - "SETTINGS TAB" section
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.theme) private var theme

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background
                    .ignoresSafeArea()

                List {
                    // Pro Banner Section
                    Section {
                        HStack {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(ThemeColors.highlightRed)
                            VStack(alignment: .leading) {
                                Text("Speedr Pro")
                                    .font(.system(size: 17, weight: .semibold))
                                Text("Unlimited speed & documents")
                                    .font(Typography.caption)
                                    .foregroundColor(theme.textSecondary)
                            }
                            Spacer()
                            Text("GET")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(theme.accentBlue)
                        }
                        .padding(.vertical, 4)
                    }

                    // Reader Section
                    Section("Reader") {
                        NavigationLink {
                            // TODO: Color picker view
                            Text("Color Picker")
                        } label: {
                            Label("Highlight Color", systemImage: "paintpalette.fill")
                        }

                        NavigationLink {
                            // TODO: Font size settings
                            Text("Font Size")
                        } label: {
                            Label("Font Size", systemImage: "textformat.size")
                        }

                        NavigationLink {
                            // TODO: Theme settings
                            Text("Theme")
                        } label: {
                            Label("Theme", systemImage: "moon.fill")
                        }
                    }

                    // Sound Section
                    Section("Sound") {
                        NavigationLink {
                            // TODO: Background music (Pro feature)
                            Text("Background Music")
                        } label: {
                            HStack {
                                Label("Background Music", systemImage: "music.note")
                                Spacer()
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                    .foregroundColor(theme.textSecondary)
                            }
                        }
                    }

                    // Account Section
                    Section("Account") {
                        NavigationLink {
                            // TODO: Statistics view
                            Text("Statistics")
                        } label: {
                            Label("Statistics", systemImage: "chart.bar.fill")
                        }

                        Button {
                            // TODO: Restore purchases
                        } label: {
                            Label("Restore Purchases", systemImage: "arrow.clockwise")
                        }
                    }

                    // About Section
                    Section("About") {
                        NavigationLink {
                            // TODO: Help & FAQ
                            Text("Help & FAQ")
                        } label: {
                            Label("Help & FAQ", systemImage: "questionmark.circle.fill")
                        }

                        Button {
                            // TODO: Rate app
                        } label: {
                            Label("Rate Speedr", systemImage: "star.fill")
                        }

                        Button {
                            // TODO: Share app
                        } label: {
                            Label("Share Speedr", systemImage: "square.and.arrow.up.fill")
                        }
                    }

                    // Version
                    Section {
                        HStack {
                            Spacer()
                            Text("Version 1.0.0")
                                .font(Typography.caption)
                                .foregroundColor(theme.textSecondary)
                            Spacer()
                        }
                    }
                    .listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .speedrTheme()
        .preferredColorScheme(.dark)
}
