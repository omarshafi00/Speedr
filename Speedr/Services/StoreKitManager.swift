//
//  StoreKitManager.swift
//  Speedr
//
//  Reference: PROJECT_SPEC.md - "Business Logic", "Paywall View"
//  Reference: RESOURCES.md - Section 3 (StoreKit 2)
//

import Foundation
import StoreKit

/// Manages in-app purchases and subscriptions using StoreKit 2
@Observable
@MainActor
final class StoreKitManager {

    // MARK: - Singleton

    static let shared = StoreKitManager()

    // MARK: - Product IDs

    enum ProductID: String, CaseIterable {
        case monthly = "com.speedr.pro.monthly"
        case yearly = "com.speedr.pro.yearly"

        var displayName: String {
            switch self {
            case .monthly: return "Monthly"
            case .yearly: return "Yearly"
            }
        }
    }

    // MARK: - State

    /// Available products from the App Store
    private(set) var products: [Product] = []

    /// Current subscription status
    private(set) var subscriptionStatus: SubscriptionStatus = .free

    /// Whether products are being loaded
    private(set) var isLoading = false

    /// Error message if something went wrong
    private(set) var errorMessage: String?

    /// Transaction listener task
    private var updateListenerTask: Task<Void, Error>?

    // MARK: - Computed Properties

    /// Whether user has active Pro subscription
    var isPro: Bool {
        subscriptionStatus.isPro
    }

    /// Monthly product
    var monthlyProduct: Product? {
        products.first { $0.id == ProductID.monthly.rawValue }
    }

    /// Yearly product
    var yearlyProduct: Product? {
        products.first { $0.id == ProductID.yearly.rawValue }
    }

    // MARK: - Initialization

    private init() {
        // Start listening for transactions
        updateListenerTask = listenForTransactions()

        // Load products and check status
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Product Loading

    /// Load available products from the App Store
    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let productIDs = ProductID.allCases.map { $0.rawValue }
            products = try await Product.products(for: productIDs)
            products.sort { $0.price < $1.price }
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            print("StoreKit Error: \(error)")
        }

        isLoading = false
    }

    // MARK: - Purchase

    /// Purchase a product
    /// - Parameter product: The product to purchase
    /// - Returns: Whether the purchase was successful
    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updateSubscriptionStatus()
                await transaction.finish()
                isLoading = false
                return true

            case .userCancelled:
                isLoading = false
                return false

            case .pending:
                errorMessage = "Purchase is pending approval"
                isLoading = false
                return false

            @unknown default:
                isLoading = false
                return false
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            print("Purchase Error: \(error)")
            isLoading = false
            return false
        }
    }

    /// Purchase by product ID
    /// - Parameter productID: The product ID to purchase
    /// - Returns: Whether the purchase was successful
    @discardableResult
    func purchase(productID: ProductID) async -> Bool {
        guard let product = products.first(where: { $0.id == productID.rawValue }) else {
            errorMessage = "Product not found"
            return false
        }
        return await purchase(product)
    }

    // MARK: - Restore Purchases

    /// Restore previous purchases
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil

        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
            print("Restore Error: \(error)")
        }

        isLoading = false
    }

    // MARK: - Subscription Status

    /// Update the current subscription status
    func updateSubscriptionStatus() async {
        var hasActiveSubscription = false
        var latestExpirationDate: Date?

        // Check all subscription transactions
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                // Check if it's one of our subscription products
                if ProductID.allCases.map({ $0.rawValue }).contains(transaction.productID) {
                    if let expirationDate = transaction.expirationDate {
                        if expirationDate > Date() {
                            hasActiveSubscription = true
                            if latestExpirationDate == nil || expirationDate > latestExpirationDate! {
                                latestExpirationDate = expirationDate
                            }
                        }
                    }
                }
            } catch {
                print("Transaction verification failed: \(error)")
            }
        }

        if hasActiveSubscription, let expirationDate = latestExpirationDate {
            subscriptionStatus = .pro(expirationDate: expirationDate)
        } else {
            subscriptionStatus = .free
        }

        // Save status to UserDefaults for offline access
        saveSubscriptionStatus()
    }

    // MARK: - Transaction Listener

    /// Listen for transaction updates
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updateSubscriptionStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction update failed: \(error)")
                }
            }
        }
    }

    // MARK: - Verification

    /// Verify a transaction result
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Persistence

    private func saveSubscriptionStatus() {
        if let encoded = try? JSONEncoder().encode(subscriptionStatus) {
            UserDefaults.standard.set(encoded, forKey: "subscriptionStatus")
        }
    }

    private func loadSubscriptionStatus() {
        if let data = UserDefaults.standard.data(forKey: "subscriptionStatus"),
           let status = try? JSONDecoder().decode(SubscriptionStatus.self, from: data) {
            // Only use cached status if it's still valid
            if status.isPro {
                subscriptionStatus = status
            }
        }
    }
}

// MARK: - Product Extensions

extension Product {
    /// Formatted price string
    var formattedPrice: String {
        displayPrice
    }

    /// Price per month for yearly subscriptions
    var monthlyEquivalent: String? {
        guard id == StoreKitManager.ProductID.yearly.rawValue else { return nil }
        let monthlyPrice = price / 12
        return monthlyPrice.formatted(.currency(code: priceFormatStyle.currencyCode ?? "USD"))
    }

    /// Savings percentage compared to monthly
    func savingsPercentage(comparedTo monthly: Product) -> Int? {
        guard id == StoreKitManager.ProductID.yearly.rawValue else { return nil }
        let yearlyMonthlyEquivalent = price / 12
        let monthlyCost = monthly.price
        let savings = (1 - (yearlyMonthlyEquivalent / monthlyCost)) * 100
        return Int(savings.rounded())
    }
}

// MARK: - Environment Key

private struct StoreKitManagerKey: EnvironmentKey {
    static let defaultValue = StoreKitManager.shared
}

extension EnvironmentValues {
    var storeKitManager: StoreKitManager {
        get { self[StoreKitManagerKey.self] }
        set { self[StoreKitManagerKey.self] = newValue }
    }
}
