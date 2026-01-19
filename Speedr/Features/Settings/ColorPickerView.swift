//
//  ColorPickerView.swift
//  Speedr
//
//  Reference: PROJECT_SPEC.md - "SETTINGS TAB" section
//

import SwiftUI

/// View for selecting the highlight color for the ORP character
struct ColorPickerView: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    /// Preferences manager
    @State private var preferences = PreferencesManager.shared

    /// Currently selected color hex
    @State private var selectedColorHex: String

    /// Show custom color picker
    @State private var showCustomPicker = false

    /// Custom color from system picker
    @State private var customColor: Color

    init() {
        let currentHex = PreferencesManager.shared.highlightColorHex
        _selectedColorHex = State(initialValue: currentHex)
        _customColor = State(initialValue: Color(hex: currentHex))
    }

    var body: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Preview section
                    previewSection

                    // Preset colors
                    presetColorsSection

                    // Custom color option
                    customColorSection
                }
                .padding(Constants.Layout.standardMargin)
            }
        }
        .navigationTitle("Highlight Color")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveColor()
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
        .sheet(isPresented: $showCustomPicker) {
            CustomColorPickerSheet(
                selectedColor: $customColor,
                onSave: { color in
                    if let hex = color.toHex() {
                        selectedColorHex = hex
                    }
                }
            )
        }
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        VStack(spacing: 16) {
            Text("Preview")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Word preview with focal point
            ZStack {
                FocalPointOverlay()

                Text(previewWord)
                    .font(Typography.readerWord(size: 48))
            }
            .frame(height: FocalPointConfig().totalHeight)
            .padding()
            .background(theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius))
        }
    }

    private var previewWord: AttributedString {
        TextProcessor.createStyledWord(
            "Speedr",
            highlightColor: Color(hex: selectedColorHex),
            baseColor: theme.textPrimary
        )
    }

    // MARK: - Preset Colors Section

    private var presetColorsSection: some View {
        VStack(spacing: 16) {
            Text("Preset Colors")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(PresetHighlightColor.allCases) { preset in
                    ColorSwatch(
                        color: preset.color,
                        isSelected: selectedColorHex.uppercased() == preset.rawValue.uppercased(),
                        name: preset.name
                    ) {
                        selectedColorHex = preset.rawValue
                    }
                }
            }
        }
    }

    // MARK: - Custom Color Section

    private var customColorSection: some View {
        VStack(spacing: 16) {
            Text("Custom Color")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                customColor = Color(hex: selectedColorHex)
                showCustomPicker = true
            } label: {
                HStack {
                    // Current custom color preview
                    Circle()
                        .fill(Color(hex: selectedColorHex))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(theme.textSecondary.opacity(0.3), lineWidth: 1)
                        )

                    Text("Choose Custom Color")
                        .font(Typography.body)
                        .foregroundColor(theme.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                }
                .padding(16)
                .background(theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Actions

    private func saveColor() {
        preferences.highlightColorHex = selectedColorHex
    }
}

// MARK: - Color Swatch

struct ColorSwatch: View {
    let color: Color
    let isSelected: Bool
    let name: String
    let onSelect: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 48, height: 48)

                    if isSelected {
                        Circle()
                            .stroke(theme.textPrimary, lineWidth: 3)
                            .frame(width: 56, height: 56)

                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                Text(name)
                    .font(Typography.caption)
                    .foregroundColor(theme.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Custom Color Picker Sheet

struct CustomColorPickerSheet: View {
    @Binding var selectedColor: Color
    let onSave: (Color) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Color picker
                ColorPicker("Select Color", selection: $selectedColor, supportsOpacity: false)
                    .labelsHidden()
                    .scaleEffect(1.5)
                    .frame(height: 100)

                // Preview
                VStack(spacing: 8) {
                    Text("Preview")
                        .font(Typography.caption)
                        .foregroundColor(theme.textSecondary)

                    Circle()
                        .fill(selectedColor)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .stroke(theme.textSecondary.opacity(0.3), lineWidth: 1)
                        )
                }

                Spacer()
            }
            .padding(32)
            .background(theme.background)
            .navigationTitle("Custom Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Select") {
                        onSave(selectedColor)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Previews

#Preview("Color Picker") {
    NavigationStack {
        ColorPickerView()
    }
    .speedrTheme()
    .preferredColorScheme(.dark)
}
