//
//  PaywallView.swift
//  Speedr
//
//  Reference: PROJECT_SPEC.md - "PAYWALL VIEW" section
//  Reference: RESOURCES.md - Section 3 (StoreKit 2)
//

import SwiftUI
import StoreKit

/// Subscription paywall view
struct PaywallView: View {
    /// The trigger that caused the paywall to appear
    var trigger: PaywallTrigger = .proBanner

    /// Dismiss action
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    /// StoreKit manager
    @State private var storeKit = StoreKitManager.shared

    /// Selected product
    @State private var selectedProduct: Product?

    /// Purchase in progress
    @State private var isPurchasing = false

    /// Show error alert
    @State private var showError = false

    var body: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Close button
                    closeButton

                    // Header
                    headerSection

                    // Features list
                    featuresSection

                    // Product options
                    productsSection

                    // Purchase button
                    purchaseButton

                    // Footer links
                    footerLinks
                }
                .padding(.horizontal, Constants.Layout.standardMargin)
                .padding(.bottom, 32)
            }

            // Loading overlay
            if isPurchasing || storeKit.isLoading {
                loadingOverlay
            }
        }
        .onAppear {
            // Select yearly by default (recommended)
            selectedProduct = storeKit.yearlyProduct ?? storeKit.monthlyProduct
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(storeKit.errorMessage ?? "An error occurred")
        }
        .onChange(of: storeKit.errorMessage) { _, newValue in
            if newValue != nil {
                showError = true
            }
        }
    }

    // MARK: - Close Button

    private var closeButton: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(theme.surface)
                    .clipShape(Circle())
            }
            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Icon
            Image(systemName: "bolt.fill")
                .font(.system(size: 48))
                .foregroundColor(ThemeColors.highlightRed)

            // Title
            Text("Unlock Speedr Pro")
                .font(Typography.headline)
                .foregroundColor(theme.textPrimary)

            // Subtitle based on trigger
            Text(trigger.message)
                .font(Typography.body)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 16)
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FeatureRow(icon: "doc.on.doc.fill", text: "Unlimited documents")
            FeatureRow(icon: "speedometer", text: "Speed up to 1500+ WPM")
            FeatureRow(icon: "paintpalette.fill", text: "Custom highlight colors")
            FeatureRow(icon: "music.note", text: "Background music & sounds")
            FeatureRow(icon: "chart.bar.fill", text: "Reading statistics")
            FeatureRow(icon: "books.vertical.fill", text: "Future: Full book library")
        }
        .padding(.vertical, 16)
    }

    // MARK: - Products Section

    private var productsSection: some View {
        VStack(spacing: 12) {
            // Yearly option (recommended)
            if let yearly = storeKit.yearlyProduct {
                ProductOptionCard(
                    product: yearly,
                    isSelected: selectedProduct?.id == yearly.id,
                    isRecommended: true,
                    savingsText: savingsText(for: yearly)
                ) {
                    selectedProduct = yearly
                }
            }

            // Monthly option
            if let monthly = storeKit.monthlyProduct {
                ProductOptionCard(
                    product: monthly,
                    isSelected: selectedProduct?.id == monthly.id,
                    isRecommended: false,
                    savingsText: nil
                ) {
                    selectedProduct = monthly
                }
            }

            // Loading state
            if storeKit.products.isEmpty && storeKit.isLoading {
                ProgressView()
                    .padding()
            }
        }
    }

    private func savingsText(for yearly: Product) -> String? {
        guard let monthly = storeKit.monthlyProduct,
              let savings = yearly.savingsPercentage(comparedTo: monthly) else {
            return nil
        }
        return "Save \(savings)%"
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        Button {
            Task {
                await handlePurchase()
            }
        } label: {
            Text("Continue")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: Constants.Layout.buttonHeight)
                .background(selectedProduct != nil ? theme.accentBlue : theme.textSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.buttonCornerRadius))
        }
        .disabled(selectedProduct == nil || isPurchasing)
        .padding(.top, 8)
    }

    // MARK: - Footer Links

    private var footerLinks: some View {
        HStack(spacing: 16) {
            Button("Restore Purchases") {
                Task {
                    await storeKit.restorePurchases()
                    if storeKit.isPro {
                        dismiss()
                    }
                }
            }
            .font(Typography.caption)
            .foregroundColor(theme.textSecondary)

            Text("•")
                .foregroundColor(theme.textSecondary)

            Button("Terms") {
                // TODO: Open terms URL
            }
            .font(Typography.caption)
            .foregroundColor(theme.textSecondary)

            Text("•")
                .foregroundColor(theme.textSecondary)

            Button("Privacy") {
                // TODO: Open privacy URL
            }
            .font(Typography.caption)
            .foregroundColor(theme.textSecondary)
        }
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("Processing...")
                    .font(Typography.body)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Actions

    private func handlePurchase() async {
        guard let product = selectedProduct else { return }

        isPurchasing = true
        let success = await storeKit.purchase(product)
        isPurchasing = false

        if success {
            dismiss()
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let text: String

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.green)

            Text(text)
                .font(Typography.body)
                .foregroundColor(theme.textPrimary)

            Spacer()
        }
    }
}

// MARK: - Product Option Card

struct ProductOptionCard: View {
    let product: Product
    let isSelected: Bool
    let isRecommended: Bool
    let savingsText: String?
    let onSelect: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: onSelect) {
            HStack {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? theme.accentBlue : theme.textSecondary, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(theme.accentBlue)
                            .frame(width: 14, height: 14)
                    }
                }

                // Product info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(product.id.contains("yearly") ? "YEARLY" : "MONTHLY")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(theme.textPrimary)

                        if isRecommended {
                            Text("BEST VALUE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(theme.accentBlue)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }

                    Text(product.displayPrice + (product.id.contains("yearly") ? "/year" : "/month"))
                        .font(Typography.body)
                        .foregroundColor(theme.textPrimary)

                    if let savings = savingsText {
                        Text(savings)
                            .font(Typography.caption)
                            .foregroundColor(.green)
                    }
                }

                Spacer()
            }
            .padding(16)
            .background(isSelected ? theme.accentBlue.opacity(0.1) : theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius)
                    .stroke(isSelected ? theme.accentBlue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("Paywall") {
    PaywallView(trigger: .speedLimit)
        .speedrTheme()
        .preferredColorScheme(.dark)
}

#Preview("Paywall - Pro Banner") {
    PaywallView(trigger: .proBanner)
        .speedrTheme()
        .preferredColorScheme(.dark)
}
