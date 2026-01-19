# Documentation Resources

## ⚠️ MANDATORY REFERENCE

This file contains all official documentation that MUST be referenced when implementing features. Do not implement features from memory - always check the relevant documentation first.

---

## Section 1: SwiftUI Text & Rich Text
**Use for:** Word display, colored middle letter, text styling

### Official Apple Documentation
| Resource | URL |
|----------|-----|
| Building rich SwiftUI text experiences | https://developer.apple.com/documentation/swiftui/building-rich-swiftui-text-experiences |
| TextEditor Documentation | https://developer.apple.com/documentation/swiftui/texteditor |
| AttributedString | https://developer.apple.com/documentation/foundation/attributedstring |
| Text View | https://developer.apple.com/documentation/swiftui/text |

### WWDC Videos
| Resource | URL |
|----------|-----|
| Cook up a rich text experience (WWDC 2025) | https://developer.apple.com/videos/play/wwdc2025/280/ |
| What's new in SwiftUI (WWDC 2025) | https://developer.apple.com/videos/play/wwdc2025/256/ |

### Key Implementation Notes
- Use `AttributedString` to style individual characters
- Set `foregroundColor` attribute for specific character ranges
- `Text` view can display AttributedStrings directly
- For the middle letter: calculate the middle index, create attributed string with different color for that character

### Example Pattern
```swift
func styledWord(_ word: String, middleColor: Color) -> AttributedString {
    var attributedString = AttributedString(word)
    let middleIndex = word.count / 2
    
    // Find the range of the middle character
    if let range = attributedString.range(of: String(word[word.index(word.startIndex, offsetBy: middleIndex)])) {
        attributedString[range].foregroundColor = middleColor
    }
    
    return attributedString
}
```

---

## Section 2: Liquid Glass Design (iOS 26)
**Use for:** All UI components, navigation, controls, settings

### Official Apple Documentation
| Resource | URL |
|----------|-----|
| Applying Liquid Glass to custom views | https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views |
| Human Interface Guidelines | https://developer.apple.com/design/human-interface-guidelines |

### Community Resources (Apple-Approved Patterns)
| Resource | URL |
|----------|-----|
| Complete Liquid Glass Reference | https://github.com/conorluddy/LiquidGlassReference |
| Sample App with Liquid Glass | https://github.com/mertozseven/LiquidGlassSwiftUI |
| Tutorial: Custom UI with Liquid Glass | https://www.donnywals.com/designing-custom-ui-with-liquid-glass-on-ios-26/ |
| Build a Liquid Glass Design System | https://levelup.gitconnected.com/build-a-liquid-glass-design-system-in-swiftui-ios-26-bfa62bcba5be |

### Key Implementation Notes
- `.glassEffect()` - Apply to navigation/control layers ONLY
- `.glassEffect(.regular)` - Standard glass appearance
- `.glassEffect(.regular.tint(.blue))` - Tinted glass
- `.glassEffect(.regular.interactive())` - Interactive elements
- `GlassEffectContainer` - Coordinate multiple glass elements
- **NEVER** apply glass effect to content (lists, tables, media)
- **ALWAYS** check `@Environment(\.accessibilityReduceTransparency)`

### Example Pattern
```swift
// ✅ CORRECT - Glass on controls
Button("Settings") { }
    .padding()
    .glassEffect(.regular.interactive())

// ❌ WRONG - Glass on content
List { items }
    .glassEffect() // DON'T DO THIS
```

---

## Section 3: StoreKit 2 (Monetization)
**Use for:** In-app purchases, subscriptions, paywall

### Official Apple Documentation
| Resource | URL |
|----------|-----|
| StoreKit Overview | https://developer.apple.com/storekit/ |
| StoreKit Documentation | https://developer.apple.com/documentation/storekit |
| Product | https://developer.apple.com/documentation/storekit/product |
| SubscriptionStoreView | https://developer.apple.com/documentation/storekit/subscriptionstoreview |

### WWDC Videos
| Resource | URL |
|----------|-----|
| What's new in StoreKit (WWDC 2025) | https://developer.apple.com/videos/play/wwdc2025/241/ |
| Meet StoreKit for SwiftUI (WWDC 2023) | https://developer.apple.com/videos/play/wwdc2023/10013/ |

### Tutorials
| Resource | URL |
|----------|-----|
| In-Depth StoreKit 2 Tutorial | https://www.revenuecat.com/blog/engineering/ios-in-app-subscription-tutorial-with-storekit-2-and-swift/ |

### Key Implementation Notes
- Use StoreKit 2 (NOT StoreKit 1 - deprecated)
- `ProductView` - Display individual products
- `StoreView` - Display multiple products
- `SubscriptionStoreView` - Subscription-specific paywall
- Use StoreKit Configuration File for testing in Xcode
- Transactions are automatically verified with JWS

### Example Pattern
```swift
import StoreKit

struct PaywallView: View {
    var body: some View {
        SubscriptionStoreView(productIDs: ["com.app.monthly", "com.app.yearly"])
    }
}
```

---

## Section 4: SwiftUI General
**Use for:** App structure, navigation, layout

### Official Apple Documentation
| Resource | URL |
|----------|-----|
| SwiftUI WWDC 2025 Guide | https://developer.apple.com/wwdc25/guides/swiftui/ |
| SwiftUI Documentation | https://developer.apple.com/documentation/swiftui |
| App Structure | https://developer.apple.com/documentation/swiftui/app-structure-and-behavior |
| Navigation | https://developer.apple.com/documentation/swiftui/navigationstack |

---

## Section 5: File Import (Books/PDFs)
**Use for:** Importing user's books and documents

### Official Apple Documentation
| Resource | URL |
|----------|-----|
| FileImporter | https://developer.apple.com/documentation/swiftui/view/fileimporter(ispresented:allowedcontenttypes:allowsmultipleselection:oncompletion:) |
| PDFKit | https://developer.apple.com/documentation/pdfkit |
| PDFDocument | https://developer.apple.com/documentation/pdfkit/pdfdocument |
| Uniform Type Identifiers | https://developer.apple.com/documentation/uniformtypeidentifiers |

### Key Implementation Notes
- Use `.fileImporter()` modifier for file selection
- Support `.pdf`, `.txt`, `.epub` content types
- Use PDFKit to extract text from PDFs
- Handle file access permissions properly

### Example Pattern
```swift
.fileImporter(
    isPresented: $showingImporter,
    allowedContentTypes: [.pdf, .plainText],
    allowsMultipleSelection: false
) { result in
    // Handle imported file
}
```

---

## Section 6: Data Persistence
**Use for:** Saving reading progress, user preferences

### Official Apple Documentation
| Resource | URL |
|----------|-----|
| SwiftData | https://developer.apple.com/documentation/swiftdata |
| AppStorage | https://developer.apple.com/documentation/swiftui/appstorage |
| UserDefaults | https://developer.apple.com/documentation/foundation/userdefaults |

### Key Implementation Notes
- Use `@AppStorage` for simple settings (WPM, colors)
- Use SwiftData for complex data (books, reading progress)
- Consider CloudKit sync for cross-device support

---

## Quick Reference: Feature → Documentation

| Feature | Primary Documentation | Section |
|---------|----------------------|---------|
| Word display | AttributedString | Section 1 |
| Colored middle letter | AttributedString | Section 1 |
| Glass UI effects | Liquid Glass | Section 2 |
| Settings panel | Liquid Glass + SwiftUI | Section 2 & 4 |
| Navigation | SwiftUI Navigation | Section 4 |
| Subscriptions | StoreKit 2 | Section 3 |
| File import | FileImporter | Section 5 |
| Save progress | SwiftData | Section 6 |

---

*Last updated: January 2026*
*Always check for newer documentation versions on developer.apple.com*
