//
//  HomeView.swift
//  Speedr
//
//  Reference: PROJECT_SPEC.md - "HOME TAB (Default)" section
//

import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    @Environment(\.theme) private var theme

    /// Controls whether the reader is shown
    @State private var showReader = false

    /// Controls whether the file importer is shown
    @State private var showFileImporter = false

    var body: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // App Icon placeholder
                Image(systemName: "bolt.fill")
                    .font(.system(size: 60))
                    .foregroundColor(theme.accentBlue)

                // Headline
                VStack(spacing: 8) {
                    Text("Ready to read")
                        .font(Typography.headline)
                        .foregroundColor(theme.textPrimary)
                    Text("faster?")
                        .font(Typography.headline)
                        .foregroundColor(theme.textPrimary)
                }

                // Subtitle
                Text("Most people read 200 words per minute.\nYou can do 3x that.")
                    .font(Typography.body)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Constants.Layout.standardMargin)

                Spacer()

                // Buttons
                VStack(spacing: 16) {
                    // Primary CTA - Try Demo
                    Button {
                        showReader = true
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Try Demo")
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: Constants.Layout.buttonHeight)
                        .background(theme.accentBlue)
                        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.buttonCornerRadius))
                    }

                    // Secondary CTA - Import Document
                    Button {
                        showFileImporter = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.fill")
                            Text("Import Document")
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: Constants.Layout.buttonHeight)
                        .background(theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.buttonCornerRadius))
                    }
                }
                .padding(.horizontal, Constants.Layout.standardMargin)

                Spacer()
                    .frame(height: 40)
            }
        }
        .fullScreenCover(isPresented: $showReader) {
            ReaderView(
                text: SampleTexts.demo,
                title: SampleTexts.demoTitle
            )
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.plainText, .pdf],
            allowsMultipleSelection: false
        ) { result in
            // TODO: Handle imported file in Phase 3
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    print("Selected file: \(url)")
                }
            case .failure(let error):
                print("File import error: \(error)")
            }
        }
    }
}

#Preview {
    HomeView()
        .speedrTheme()
        .preferredColorScheme(.dark)
}
