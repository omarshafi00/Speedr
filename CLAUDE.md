# CLAUDE.md - Speedr Project Instructions

## ⚠️ CRITICAL: READ THIS FIRST

Before implementing ANY feature in this project, you MUST:
1. Read `/docs/PROJECT_SPEC.md` for exact UI specifications
2. Check `/docs/RESOURCES.md` for Apple documentation links
3. Follow the specifications EXACTLY as written
4. Only then write the code

**DO NOT** implement features from memory or assumptions. Always verify against the spec first.

---

## Project Overview

**App Name:** Speedr
**Bundle ID:** com.yourname.speedr (update with your actual bundle ID)
**Platform:** iOS 26+
**Minimum iOS:** iOS 17.0 (for wider compatibility, Liquid Glass iOS 26+)
**Framework:** SwiftUI
**Design:** Liquid Glass (iOS 26), fallback for older iOS

### What This App Does
Speedr is an RSVP (Rapid Serial Visual Presentation) speed reading app that displays one word at a time with a focal point system to help users read faster.

### Core Features (MVP)
1. Word-by-word reader with focal point lines
2. Colored middle letter for focus
3. Adjustable speed (10-1000 WPM)
4. PDF/TXT document import
5. Built-in sample text for demo
6. Dark/Light theme
7. Subscription paywall

---

## Documentation Reference

**ALWAYS** check these files before implementing:

| File | Contains |
|------|----------|
| `/docs/PROJECT_SPEC.md` | Complete UI specs, screen layouts, data models |
| `/docs/RESOURCES.md` | Apple documentation links for each feature |

### Feature → Documentation Mapping

| Feature | Check PROJECT_SPEC Section | Check RESOURCES.md Section |
|---------|---------------------------|---------------------------|
| Focal point lines | "Reader View" | N/A (custom implementation) |
| Colored middle letter | "Word Display", "TextProcessor" | Section 1 (AttributedString) |
| Liquid Glass UI | "Design System" | Section 2 (Liquid Glass) |
| Subscriptions | "Paywall View", "Business Logic" | Section 3 (StoreKit 2) |
| File import | "DocumentImporter" | Section 5 (FileImporter) |

---

## Design System (Quick Reference)

### Colors
```swift
// Dark Theme
static let background = Color.black
static let surface = Color(hex: "1C1C1E")
static let textPrimary = Color.white
static let textSecondary = Color(hex: "8E8E93")
static let focalLines = Color(hex: "48484A")

// Accent
static let highlightRed = Color(hex: "FF3B3B")  // Default middle letter
static let accentBlue = Color(hex: "007AFF")    // Buttons
```

### Typography
```swift
// Reader word display
.font(.custom("NewYork-Medium", size: 48))

// Or use system serif
.font(.system(size: 48, weight: .medium, design: .serif))
```

### Liquid Glass
```swift
// Only on controls/navigation, NEVER on content
Button("Action") { }
    .glassEffect(.regular.interactive())
```

---

## Critical Implementation Details

### 1. Middle Letter Calculation (IMPORTANT!)

The "middle" letter is NOT exactly center. Use the Optimal Recognition Point (ORP):

```swift
func findORPIndex(word: String) -> Int {
    let length = word.count
    if length <= 1 { return 0 }
    if length <= 3 { return 0 }  // First letter for short words
    
    // ORP is approximately 35% from the start
    return Int(Double(length - 1) * 0.35)
}

// Examples:
// "a" → index 0 (the "a")
// "the" → index 0 (the "t")
// "people" → index 2 (the "o")
// "reading" → index 2 (the "a")
```

### 2. Word Positioning (IMPORTANT!)

The word is positioned so the ORP letter aligns with the focal point center:

```swift
func calculateWordOffset(word: String, fontSize: CGFloat) -> CGFloat {
    let orpIndex = findORPIndex(word: word)
    let characterWidth = fontSize * 0.6  // Approximate
    let wordWidth = CGFloat(word.count) * characterWidth
    let orpPosition = CGFloat(orpIndex) * characterWidth
    let centerOffset = wordWidth / 2 - orpPosition
    return -centerOffset  // Shift left to align ORP with center
}
```

### 3. Timing Calculation

```swift
func millisecondsPerWord(wpm: Int) -> Int {
    guard wpm > 0 else { return 1000 }
    return Int(60000.0 / Double(wpm))
}

// 100 WPM = 600ms per word
// 300 WPM = 200ms per word
// 500 WPM = 120ms per word
// 1000 WPM = 60ms per word
```

### 4. Focal Point Structure

```
    ─────────────────┬─────────────────
                     │  (8pt notch)
                     
              word here
                     
                     │  (8pt notch)
    ─────────────────┴─────────────────
```

- Horizontal lines: 120pt each side, 1pt thick
- Vertical notches: 8pt tall, 1pt thick
- Gap from word to line: 24pt
- Color: secondary with 50% opacity

---

## File Structure

```
Speedr/
├── SpeedrApp.swift           # @main entry
├── ContentView.swift         # TabView with 3 tabs
├── Core/
│   ├── Reader/
│   │   ├── ReaderView.swift
│   │   ├── ReaderViewModel.swift
│   │   ├── WordDisplayView.swift
│   │   ├── FocalPointView.swift
│   │   └── ReaderControlsView.swift
│   ├── Onboarding/
│   │   └── SpeedHintPopup.swift
│   └── Paywall/
│       └── PaywallView.swift
├── Features/
│   ├── Home/
│   │   └── HomeView.swift
│   ├── Library/
│   │   ├── LibraryView.swift
│   │   └── DocumentRow.swift
│   └── Settings/
│       ├── SettingsView.swift
│       ├── ColorPickerView.swift
│       └── StatsView.swift
├── Models/
│   ├── Document.swift
│   ├── UserPreferences.swift
│   ├── ReadingSession.swift
│   └── SubscriptionStatus.swift
├── Services/
│   ├── TextProcessor.swift
│   ├── DocumentImporter.swift
│   ├── StoreKitManager.swift
│   └── PersistenceManager.swift
├── Design/
│   ├── Theme.swift
│   ├── GlassComponents.swift
│   └── Constants.swift
└── Resources/
    ├── SampleTexts.swift
    └── Assets.xcassets
```

---

## Build Order

Follow this EXACT order when building:

### Phase 1: Foundation
1. `Theme.swift` - Colors, fonts
2. `Constants.swift` - App-wide values
3. `SpeedrApp.swift` - Entry point
4. `ContentView.swift` - Tab bar

### Phase 2: Core Reader
5. `TextProcessor.swift` - ORP calculation, word splitting
6. `FocalPointView.swift` - Lines and notches
7. `WordDisplayView.swift` - Styled word display
8. `ReaderViewModel.swift` - State, timing
9. `ReaderControlsView.swift` - Buttons
10. `ReaderView.swift` - Assembly

### Phase 3: Content
11. `Document.swift` - Model
12. `SampleTexts.swift` - Demo content
13. `HomeView.swift` - Home tab
14. `DocumentImporter.swift` - PDF/TXT
15. `LibraryView.swift` - Document list
16. `PersistenceManager.swift` - Save data

### Phase 4: Monetization
17. `SubscriptionStatus.swift` - Model
18. `StoreKitManager.swift` - IAP
19. `PaywallView.swift` - Purchase UI
20. Paywall trigger logic

### Phase 5: Settings & Polish
21. `UserPreferences.swift` - Model
22. `SettingsView.swift` - Settings tab
23. `ColorPickerView.swift` - Color selection
24. `SpeedHintPopup.swift` - Onboarding
25. `GlassComponents.swift` - Liquid Glass
26. Animations and transitions

---

## Code Standards

### SwiftUI Views
- Use iOS 26+ APIs where available
- Provide fallbacks for iOS 17+
- Apply `.glassEffect()` ONLY to navigation/controls
- NEVER apply glass to content

### Naming
- Views: `SomethingView.swift`
- ViewModels: `SomethingViewModel.swift`
- Use `@Observable` (iOS 17+) for view models

### Comments
```swift
// Reference: PROJECT_SPEC.md - "Reader View" section
// Reference: RESOURCES.md - Section 1 (AttributedString)
func createStyledWord(_ word: String, highlightColor: Color) -> AttributedString {
    // Implementation
}
```

---

## Testing Checklist

Before considering a feature complete:

- [ ] Works in dark mode
- [ ] Works in light mode
- [ ] Works on iPhone SE (small screen)
- [ ] Works on iPhone 15 Pro Max (large screen)
- [ ] Handles empty states
- [ ] Handles errors gracefully
- [ ] Matches PROJECT_SPEC.md exactly

---

## Quick Commands for Claude Code

Use these prompts when working:

**Start a feature:**
"Check PROJECT_SPEC.md and implement [feature name]"

**Fix something:**
"The [feature] doesn't match the spec. Fix it according to PROJECT_SPEC.md"

**Add documentation reference:**
"Add proper documentation comments referencing PROJECT_SPEC.md and RESOURCES.md"

---

## Don'ts

❌ Don't implement features not in PROJECT_SPEC.md
❌ Don't change the color palette without asking
❌ Don't use UIKit unless absolutely necessary
❌ Don't skip the paywall logic
❌ Don't forget dark/light theme support
❌ Don't apply Liquid Glass to content areas

---

## Do's

✅ Follow PROJECT_SPEC.md exactly
✅ Check RESOURCES.md for Apple docs
✅ Use SwiftUI best practices
✅ Support iOS 17+ with iOS 26 enhancements
✅ Test both themes
✅ Keep code clean and commented

---

*This file is automatically read by Claude Code.*
*Keep it updated as the project evolves.*
