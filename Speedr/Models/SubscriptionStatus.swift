//
//  SubscriptionStatus.swift
//  Speedr
//
//  Reference: PROJECT_SPEC.md - "Data Models", "Business Logic" sections
//

import Foundation

/// Represents the user's subscription status
enum SubscriptionStatus: Codable, Equatable {
    case free
    case pro(expirationDate: Date)

    /// Whether the user has an active Pro subscription
    var isPro: Bool {
        switch self {
        case .free:
            return false
        case .pro(let expirationDate):
            return expirationDate > Date()
        }
    }

    /// Days remaining in Pro subscription
    var daysRemaining: Int? {
        switch self {
        case .free:
            return nil
        case .pro(let expirationDate):
            let days = Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day
            return max(0, days ?? 0)
        }
    }

    /// Whether the subscription is about to expire (within 7 days)
    var isExpiringSoon: Bool {
        guard let days = daysRemaining else { return false }
        return days <= 7 && days > 0
    }

    /// Formatted expiration date
    var expirationFormatted: String? {
        switch self {
        case .free:
            return nil
        case .pro(let expirationDate):
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: expirationDate)
        }
    }
}

// MARK: - Codable Implementation

extension SubscriptionStatus {
    private enum CodingKeys: String, CodingKey {
        case type
        case expirationDate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "pro":
            let date = try container.decode(Date.self, forKey: .expirationDate)
            self = .pro(expirationDate: date)
        default:
            self = .free
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .free:
            try container.encode("free", forKey: .type)
        case .pro(let expirationDate):
            try container.encode("pro", forKey: .type)
            try container.encode(expirationDate, forKey: .expirationDate)
        }
    }
}

// MARK: - Paywall Triggers

/// Reasons why the paywall might be shown
enum PaywallTrigger: String, CaseIterable {
    /// User trying to upload more than 1 document
    case documentLimit = "document_limit"

    /// User trying to exceed 400 WPM
    case speedLimit = "speed_limit"

    /// User trying to access background music
    case musicFeature = "music_feature"

    /// User trying to use custom colors (optional - can be free)
    case colorFeature = "color_feature"

    /// Shown after completing the demo (soft sell)
    case completedDemo = "completed_demo"

    /// User tapped the Pro banner
    case proBanner = "pro_banner"

    var title: String {
        switch self {
        case .documentLimit:
            return "Unlimited Documents"
        case .speedLimit:
            return "Unlimited Speed"
        case .musicFeature:
            return "Background Music"
        case .colorFeature:
            return "Custom Colors"
        case .completedDemo:
            return "Unlock Full Experience"
        case .proBanner:
            return "Go Pro"
        }
    }

    var message: String {
        switch self {
        case .documentLimit:
            return "Upgrade to Pro to import unlimited documents."
        case .speedLimit:
            return "Upgrade to Pro to read at speeds up to 1500 WPM."
        case .musicFeature:
            return "Upgrade to Pro to enjoy background music while reading."
        case .colorFeature:
            return "Upgrade to Pro to customize your highlight color."
        case .completedDemo:
            return "Ready to speed read your own books and documents?"
        case .proBanner:
            return "Unlock all features with Speedr Pro."
        }
    }
}

// MARK: - App Limits Helper

/// Centralized limit checking based on subscription status
struct AppLimits {
    let status: SubscriptionStatus

    init(status: SubscriptionStatus = .free) {
        self.status = status
    }

    /// Maximum documents allowed (excluding built-in)
    var maxDocuments: Int {
        status.isPro ? .max : Constants.Limits.freeMaxDocuments
    }

    /// Maximum WPM allowed
    var maxWPM: Int {
        status.isPro ? Constants.Limits.proMaxWPM : Constants.Limits.freeMaxWPM
    }

    /// Check if user can upload another document
    func canUploadDocument(currentCount: Int) -> Bool {
        status.isPro || currentCount < Constants.Limits.freeMaxDocuments
    }

    /// Check if user can increase to a specific speed
    func canUseSpeed(_ wpm: Int) -> Bool {
        wpm <= maxWPM
    }

    /// Check if a feature is available
    func isFeatureAvailable(_ feature: PaywallTrigger) -> Bool {
        if status.isPro { return true }

        switch feature {
        case .documentLimit, .speedLimit, .musicFeature:
            return false
        case .colorFeature:
            return true // Colors are free in this implementation
        case .completedDemo, .proBanner:
            return true // These are just triggers, not features
        }
    }
}
