//
//  SpeedHintPopup.swift
//  Speedr
//
//  Reference: PROJECT_SPEC.md - "ONBOARDING POPUP (First Time Speed Hint)"
//  Reference: RESOURCES.md - Section 2 (Liquid Glass)
//

import SwiftUI

/// First-time onboarding popup that appears 3 seconds after reading starts
/// Shows a hint pointing to the speed up button
struct SpeedHintPopup: View {
    @Environment(\.theme) private var theme

    /// Binding to control visibility
    @Binding var isPresented: Bool

    /// Animation state
    @State private var showContent = false
    @State private var arrowOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissPopup()
                }

            // Popup content
            VStack(spacing: 0) {
                Spacer()

                HStack(alignment: .top, spacing: 16) {
                    // Popup card
                    popupCard

                    // Arrow pointing to speed button
                    arrowView
                }
                .padding(.horizontal, Constants.Layout.standardMargin)
                .padding(.bottom, 140) // Position above controls
            }
        }
        .opacity(showContent ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                showContent = true
            }
            startArrowAnimation()
        }
    }

    // MARK: - Popup Card

    private var popupCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with lightbulb icon
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.yellow)

                Text("Pro Tip")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
            }

            // Tip text
            VStack(alignment: .leading, spacing: 4) {
                Text("Tap here to")
                    .font(Typography.body)
                    .foregroundColor(theme.textPrimary)

                Text("speed up!")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(theme.accentBlue)
            }

            // Encouragement
            Text("You can do it. 🚀")
                .font(Typography.body)
                .foregroundColor(theme.textSecondary)
                .padding(.top, 4)

            // Got it button
            Button {
                dismissPopup()
            } label: {
                Text("Got it")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(theme.accentBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.top, 8)
        }
        .padding(Constants.Layout.cardPadding)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius))
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        .frame(maxWidth: 220)
    }

    // MARK: - Arrow View

    private var arrowView: some View {
        VStack(spacing: 4) {
            Spacer()

            // Animated arrow pointing right-down
            Image(systemName: "arrow.turn.right.down")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(theme.accentBlue)
                .offset(x: arrowOffset)

            Spacer()
                .frame(height: 60)
        }
    }

    // MARK: - Animation

    private func startArrowAnimation() {
        withAnimation(
            .easeInOut(duration: 0.6)
            .repeatForever(autoreverses: true)
        ) {
            arrowOffset = 8
        }
    }

    // MARK: - Actions

    private func dismissPopup() {
        withAnimation(.easeIn(duration: 0.2)) {
            showContent = false
        }

        // Delay dismissal to allow animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isPresented = false
        }
    }
}

// MARK: - View Extension for Easy Usage

extension View {
    /// Shows the speed hint popup overlay
    /// - Parameters:
    ///   - isPresented: Binding to control visibility
    /// - Returns: View with popup overlay when presented
    func speedHintPopup(isPresented: Binding<Bool>) -> some View {
        ZStack {
            self

            if isPresented.wrappedValue {
                SpeedHintPopup(isPresented: isPresented)
                    .transition(.opacity)
            }
        }
    }
}

// MARK: - Previews

#Preview("Speed Hint Popup") {
    ZStack {
        Color.black.ignoresSafeArea()

        Text("Reader Content Here")
            .foregroundColor(.white)

        SpeedHintPopup(isPresented: .constant(true))
    }
    .speedrTheme()
}

#Preview("Speed Hint - Light Mode") {
    ZStack {
        Color.white.ignoresSafeArea()

        Text("Reader Content Here")
            .foregroundColor(.black)

        SpeedHintPopup(isPresented: .constant(true))
    }
    .speedrTheme()
    .preferredColorScheme(.light)
}
