//
//  LibraryView.swift
//  Speedr
//
//  Reference: PROJECT_SPEC.md - "LIBRARY TAB" section
//

import SwiftUI

struct LibraryView: View {
    @Environment(\.theme) private var theme

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background
                    .ignoresSafeArea()

                VStack {
                    // Placeholder content
                    ContentUnavailableView(
                        "No Documents Yet",
                        systemImage: "doc.text",
                        description: Text("Import a document to start reading")
                    )
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        // TODO: Add document
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

#Preview {
    LibraryView()
        .speedrTheme()
        .preferredColorScheme(.dark)
}
