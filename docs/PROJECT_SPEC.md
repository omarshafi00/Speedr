# Speedr - Complete Project Specification

## Overview

**App Name:** Speedr
**Tagline:** "Read faster. Focus better."
**Platform:** iOS 26+
**Framework:** SwiftUI with Liquid Glass design
**Target Audience:** Gen Z, ADHD community, students, ambitious readers

---

## Design System

### Color Palette

```
PRIMARY COLORS
- Accent Red (highlight): #FF3B3B (default middle letter color)
- Accent Blue: #007AFF (buttons, links)

DARK THEME (Default)
- Background: #000000
- Surface: #1C1C1E
- Text Primary: #FFFFFF
- Text Secondary: #8E8E93
- Focal Lines: #48484A

LIGHT THEME
- Background: #FFFFFF
- Surface: #F2F2F7
- Text Primary: #000000
- Text Secondary: #6C6C70
- Focal Lines: #C6C6C8
```

### Typography

```
READER VIEW
- Word Display: New York (serif), 48pt, medium weight
- WPM Display: SF Pro, 16pt, regular, secondary color

APP UI
- Headlines: SF Pro Display, 34pt, bold
- Body: SF Pro Text, 17pt, regular
- Caption: SF Pro Text, 13pt, regular
```

### Spacing & Layout

```
- Standard margin: 16pt
- Card padding: 20pt
- Button height: 50pt
- Tab bar: System default with Liquid Glass
- Corner radius: 12pt (cards), 25pt (buttons)
```

---

## Screen Specifications

### 1. HOME TAB (Default)

```
┌─────────────────────────────────────────┐
│ ← Safe Area                             │
│                                         │
│                                         │
│            ⚡️ (App Icon)                │
│                                         │
│         Ready to read                   │
│           faster?                       │
│                                         │
│    "Most people read 200 words per      │
│     minute. You can do 3x that."        │
│                                         │
│                                         │
│    ┌─────────────────────────────┐      │
│    │                             │      │
│    │     ▶  Try Demo             │      │  ← Primary CTA
│    │                             │      │
│    └─────────────────────────────┘      │
│                                         │
│    ┌─────────────────────────────┐      │
│    │                             │      │
│    │     📄 Import Document      │      │  ← Secondary CTA
│    │                             │      │
│    └─────────────────────────────┘      │
│                                         │
│                                         │
├─────────────────────────────────────────┤
│   📚        │    🏠       │    ⚙️       │
│  Library    │   Home      │  Settings   │
└─────────────────────────────────────────┘
```

**Behavior:**
- "Try Demo" → Opens ReaderView with built-in sample text
- "Import Document" → Opens file picker (.pdf, .txt, .epub)
- If user has read before, show stats card above buttons

---

### 2. READER VIEW (Core Experience)

```
┌─────────────────────────────────────────┐
│                                    ✕    │  ← Close button (top right)
│                                         │
│                                         │
│                                         │
│                                         │
│                                         │
│    ──────────────┬──────────────        │  ← Focal line (top)
│                  │                      │  ← Vertical notch (8pt tall)
│                                         │
│              pe[o]ple.                  │  ← Word display
│                                         │
│                  │                      │  ← Vertical notch (8pt tall)
│    ──────────────┴──────────────        │  ← Focal line (bottom)
│                                         │
│                           300 wpm       │  ← Speed indicator
│                                         │
│                                         │
│                                         │
│                                         │
│  ┌──────┐ ┌────────────────┐ ┌──────┐   │
│  │  ⏪  │ │       ⏸        │ │  ⏩  │   │  ← Controls
│  │      │ │                │ │      │   │
│  └──────┘ └────────────────┘ └──────┘   │
│                                         │
│  ════════════════════════════════════   │  ← Progress bar
│  Location: 45%              2 min left  │
│                                         │
└─────────────────────────────────────────┘
```

**Technical Specifications:**

FOCAL POINT STRUCTURE:
```swift
// Focal lines configuration
struct FocalPointConfig {
    let lineWidth: CGFloat = 1.0
    let lineLength: CGFloat = 120  // each side
    let lineColor: Color = .secondary.opacity(0.5)
    let notchHeight: CGFloat = 8
    let notchWidth: CGFloat = 1.0
    let gapFromWord: CGFloat = 24  // space between line and word
}
```

WORD POSITIONING (Critical!):
```
The word is NOT centered by its full width.
The word is positioned so the MIDDLE LETTER aligns with the focal point.

Example: "people" (6 letters)
- Middle letter: index 3 (the "p" or we use "o" at index 2-3)
- For even-length words: use the letter just LEFT of center
- Position the word so this letter is at screen center

Example: "reading" (7 letters)
- Middle letter: index 3 (the "d")
- Position word so "d" is at screen center
```

WORD DISPLAY:
```swift
// Middle letter calculation
func findMiddleIndex(word: String) -> Int {
    let length = word.count
    if length <= 1 { return 0 }
    // For RSVP, the optimal recognition point (ORP) is slightly left of center
    // Approximately 35% from the start of the word
    return max(0, Int(Double(length) * 0.35))
}
```

SPEED CONTROLS:
- Left button (⏪): Decrease by 10 WPM (min: 10 WPM)
- Right button (⏩): Increase by 10 WPM (max: 1000 WPM)
- Long press: Continuous adjustment
- Center button: Play/Pause toggle
- All buttons use Liquid Glass effect

TIMING CALCULATION:
```swift
// Words per minute to milliseconds per word
func msPerWord(wpm: Int) -> Int {
    return Int(60000 / Double(wpm))
}

// Example: 300 WPM = 200ms per word
```

---

### 3. ONBOARDING POPUP (First Time Speed Hint)

Appears 3 seconds after user starts reading for the first time:

```
┌─────────────────────────────────────────┐
│                                         │
│         ┌─────────────────────┐         │
│         │                     │         │
│         │  💡 Pro Tip         │         │
│         │                     │         │
│         │  Tap here to        │←────────│── Arrow pointing to ⏩
│         │  speed up!          │         │
│         │                     │         │
│         │  You can do it. 🚀  │         │
│         │                     │         │
│         │      [Got it]       │         │
│         │                     │         │
│         └─────────────────────┘         │
│                                         │
└─────────────────────────────────────────┘
```

---

### 4. LIBRARY TAB

```
┌─────────────────────────────────────────┐
│                                         │
│  Library                        ┌───┐   │
│                                 │ + │   │  ← Add document
│                                 └───┘   │
│  ┌─────────────────────────────────┐    │
│  │  🔍 Search documents            │    │
│  └─────────────────────────────────┘    │
│                                         │
│  MY DOCUMENTS                           │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ 📄 Sample Text           100%  ▶│    │  ← Built-in demo
│  │    823 words • Completed        │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ 📄 My Document.pdf        45%  ▶│    │  ← User upload
│  │    2,340 words • 5 min left     │    │
│  └─────────────────────────────────┘    │
│                                         │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  📚 COMING SOON                 │    │
│  │                                 │    │
│  │  Book Library                   │    │
│  │  Thousands of books at your     │    │
│  │  fingertips. Stay tuned!        │    │
│  │                                 │    │
│  └─────────────────────────────────┘    │
│                                         │
├─────────────────────────────────────────┤
│   📚        │    🏠       │    ⚙️       │
└─────────────────────────────────────────┘
```

---

### 5. SETTINGS TAB

```
┌─────────────────────────────────────────┐
│                                         │
│  Settings                               │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  ⚡️ Speedr Pro           GET → │    │  ← Paywall banner
│  │  Unlimited speed & documents    │    │
│  └─────────────────────────────────┘    │
│                                         │
│  READER                                 │
│  ┌─────────────────────────────────┐    │
│  │  🎨 Highlight Color      🔴  → │    │
│  ├─────────────────────────────────┤    │
│  │  🔤 Font Size            Aa  → │    │
│  ├─────────────────────────────────┤    │
│  │  🌙 Theme               Auto → │    │
│  └─────────────────────────────────┘    │
│                                         │
│  SOUND                                  │
│  ┌─────────────────────────────────┐    │
│  │  🎵 Background Music      🔒 → │    │  ← Pro feature
│  └─────────────────────────────────┘    │
│                                         │
│  ACCOUNT                                │
│  ┌─────────────────────────────────┐    │
│  │  📊 Statistics               → │    │
│  ├─────────────────────────────────┤    │
│  │  🔄 Restore Purchases        → │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ABOUT                                  │
│  ┌─────────────────────────────────┐    │
│  │  ❓ Help & FAQ                → │    │
│  ├─────────────────────────────────┤    │
│  │  ⭐️ Rate Speedr              → │    │
│  ├─────────────────────────────────┤    │
│  │  📤 Share Speedr              → │    │
│  └─────────────────────────────────┘    │
│                                         │
│                          Version 1.0.0  │
│                                         │
├─────────────────────────────────────────┤
│   📚        │    🏠       │    ⚙️       │
└─────────────────────────────────────────┘
```

---

### 6. PAYWALL VIEW

```
┌─────────────────────────────────────────┐
│ ✕                                       │
│                                         │
│                                         │
│               ⚡️                        │
│                                         │
│        Unlock Speedr Pro                │
│                                         │
│   "Read unlimited books at             │
│    unlimited speed"                     │
│                                         │
│                                         │
│   ✓ Unlimited documents                 │
│   ✓ Speed up to 1000+ WPM              │
│   ✓ Custom highlight colors            │
│   ✓ Background music & sounds          │
│   ✓ Reading statistics                 │
│   ✓ Future: Full book library          │
│                                         │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │                                 │    │
│  │  YEARLY - $29.99/year          │    │  ← Recommended
│  │  Save 50% • $2.50/month         │    │
│  │                                 │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  MONTHLY - $4.99/month         │    │
│  └─────────────────────────────────┘    │
│                                         │
│                                         │
│    ┌─────────────────────────────┐      │
│    │                             │      │
│    │       Continue              │      │  ← Purchase button
│    │                             │      │
│    └─────────────────────────────┘      │
│                                         │
│   Restore Purchases • Terms • Privacy   │
│                                         │
└─────────────────────────────────────────┘
```

---

## Sample Demo Text (The "WOW" Experience)

This text is CRITICAL. It's designed to:
1. Explain what's happening AS the user experiences it
2. Use simple, common words for fast recognition
3. Build confidence progressively
4. Create the "wow" moment

```
SAMPLE_TEXT = """
Welcome to Speedr.

Right now, you are reading faster than most people.

This is called RSVP. Rapid Serial Visual Presentation.

Instead of moving your eyes across a page, words come to you.

Your brain is amazing. It can process words much faster than you think.

Most people read around 200 words per minute. That is slow.

Your eyes waste time jumping between words. Your inner voice slows you down.

But not anymore.

Focus on the red letter. It helps your brain find the center of each word instantly.

You are already reading at 300 words per minute.

Want to go faster? Tap the right button.

Push yourself. Your brain can handle it.

At 500 words per minute, you can read a book in two hours.

At 700 words per minute, you can finish an article in seconds.

This is not a trick. This is how your brain was meant to read.

Try it. Speed up. See what you can do.

You might surprise yourself.

Welcome to the future of reading.

Welcome to Speedr.
"""
```

Word count: ~180 words
At 300 WPM: 36 seconds
At 500 WPM: 22 seconds
At 700 WPM: 15 seconds

---

## Data Models

### Document

```swift
struct Document: Identifiable, Codable {
    let id: UUID
    var title: String
    var content: String  // Full text content
    var wordCount: Int
    var currentPosition: Int  // Word index where user stopped
    var dateAdded: Date
    var lastRead: Date?
    var isCompleted: Bool
    var isBuiltIn: Bool  // true for sample text
    
    var progress: Double {
        guard wordCount > 0 else { return 0 }
        return Double(currentPosition) / Double(wordCount)
    }
    
    var wordsRemaining: Int {
        return max(0, wordCount - currentPosition)
    }
}
```

### UserPreferences

```swift
struct UserPreferences: Codable {
    var highlightColor: String  // Hex color
    var fontSize: Double  // Multiplier (1.0 = default)
    var theme: AppTheme  // dark, light, auto
    var defaultWPM: Int
    var hasSeenOnboarding: Bool
    var hasSeenSpeedHint: Bool
}

enum AppTheme: String, Codable {
    case dark, light, auto
}
```

### ReadingSession

```swift
struct ReadingSession: Identifiable, Codable {
    let id: UUID
    let documentId: UUID
    let date: Date
    let wordsRead: Int
    let duration: TimeInterval  // seconds
    let averageWPM: Int
    let maxWPM: Int
}
```

### SubscriptionStatus

```swift
enum SubscriptionStatus {
    case free
    case pro(expirationDate: Date)
    
    var isPro: Bool {
        switch self {
        case .free: return false
        case .pro: return true
        }
    }
}
```

---

## Business Logic

### Free vs Pro Limits

```swift
struct AppLimits {
    static let freeMaxDocuments = 1  // + built-in sample
    static let freeMaxWPM = 400
    static let proMaxWPM = 1500
    
    static func canUploadDocument(currentCount: Int, isPro: Bool) -> Bool {
        if isPro { return true }
        return currentCount < freeMaxDocuments
    }
    
    static func canIncreaseSpeed(currentWPM: Int, isPro: Bool) -> Bool {
        if isPro { return currentWPM < proMaxWPM }
        return currentWPM < freeMaxWPM
    }
}
```

### Paywall Triggers

```swift
enum PaywallTrigger {
    case documentLimit      // Trying to upload 2nd document
    case speedLimit         // Trying to exceed 400 WPM
    case musicFeature       // Trying to access music
    case colorFeature       // Trying custom colors (optional - can be free)
    case completedDemo      // After finishing sample text (soft sell)
}
```

---

## File Structure

```
Speedr/
├── CLAUDE.md                          # Instructions for Claude Code
├── docs/
│   └── RESOURCES.md                   # Apple documentation links
├── Speedr/
│   ├── App/
│   │   ├── SpeedrApp.swift            # App entry point
│   │   └── ContentView.swift          # Main tab view
│   ├── Core/
│   │   ├── Reader/
│   │   │   ├── ReaderView.swift       # Full-screen reader
│   │   │   ├── ReaderViewModel.swift  # Speed, timing, state
│   │   │   ├── WordDisplayView.swift  # Word + focal lines
│   │   │   ├── FocalPointView.swift   # The lines and notches
│   │   │   └── ReaderControlsView.swift # Play/pause, speed buttons
│   │   ├── Onboarding/
│   │   │   └── SpeedHintPopup.swift   # First-time tip
│   │   └── Paywall/
│   │       └── PaywallView.swift      # Subscription screen
│   ├── Features/
│   │   ├── Home/
│   │   │   └── HomeView.swift         # Home tab
│   │   ├── Library/
│   │   │   ├── LibraryView.swift      # Library tab
│   │   │   └── DocumentRow.swift      # List item
│   │   └── Settings/
│   │       ├── SettingsView.swift     # Settings tab
│   │       ├── ColorPickerView.swift  # Highlight color
│   │       └── StatsView.swift        # Reading statistics
│   ├── Models/
│   │   ├── Document.swift
│   │   ├── UserPreferences.swift
│   │   ├── ReadingSession.swift
│   │   └── SubscriptionStatus.swift
│   ├── Services/
│   │   ├── TextProcessor.swift        # Parse text, find middle letter
│   │   ├── DocumentImporter.swift     # PDF/TXT parsing
│   │   ├── StoreKitManager.swift      # In-app purchases
│   │   ├── PersistenceManager.swift   # SwiftData/UserDefaults
│   │   └── AudioManager.swift         # Background music (v1.1)
│   ├── Design/
│   │   ├── Theme.swift                # Colors, fonts
│   │   ├── GlassComponents.swift      # Liquid Glass modifiers
│   │   └── Constants.swift            # App-wide constants
│   └── Resources/
│       ├── SampleTexts.swift          # Built-in demo text
│       └── Assets.xcassets            # Images, colors
├── SpeedrTests/
└── .gitignore
```

---

## Build Order for Claude Code

### Phase 1: Core Reader (Week 1)

```
Day 1-2:
□ Project setup with SwiftUI
□ Basic app structure (3 tabs)
□ Theme.swift with color palette
□ Constants.swift

Day 3-4:
□ FocalPointView.swift (the lines and notches)
□ WordDisplayView.swift (word with colored middle letter)
□ TextProcessor.swift (find middle letter, calculate position)

Day 5-7:
□ ReaderViewModel.swift (timing, speed control)
□ ReaderControlsView.swift (play/pause, speed buttons)
□ ReaderView.swift (full reader assembly)
□ Basic dark theme
```

### Phase 2: Content & Navigation (Week 2)

```
Day 8-9:
□ Document.swift model
□ SampleTexts.swift (built-in demo)
□ HomeView.swift

Day 10-11:
□ DocumentImporter.swift (PDF, TXT support)
□ LibraryView.swift
□ DocumentRow.swift

Day 12-14:
□ PersistenceManager.swift (save documents, progress)
□ UserPreferences.swift
□ Light theme support
□ Theme switching
```

### Phase 3: Monetization (Week 3)

```
Day 15-17:
□ StoreKitManager.swift
□ PaywallView.swift
□ Subscription status tracking
□ Paywall triggers implementation

Day 18-21:
□ SettingsView.swift
□ ColorPickerView.swift
□ Speed limit enforcement (400 WPM free)
□ Document limit enforcement (1 free)
```

### Phase 4: Polish (Week 4)

```
Day 22-24:
□ SpeedHintPopup.swift (onboarding)
□ Animations and transitions
□ Liquid Glass effects on controls

Day 25-28:
□ StatsView.swift (reading statistics)
□ Error handling
□ Edge cases (empty states, loading)
□ App icon design
□ Bug fixes
```

### Phase 5: Testing & Launch (Week 5-6)

```
Day 29-32:
□ Internal testing
□ TestFlight setup
□ Beta distribution
□ Collect feedback

Day 33-35:
□ Bug fixes from feedback
□ Performance optimization
□ Final polish

Day 36+:
□ App Store submission
□ Screenshots and description
□ Launch! 🚀
```

---

## App Store Metadata

### App Name
Speedr - Speed Reading

### Subtitle
Read faster. Focus better.

### Keywords
speed reading, ADHD, focus, reading, books, productivity, RSVP, fast reading, concentration

### Description
```
Read 3x faster with Speedr.

Most people read 200 words per minute. With Speedr, you can reach 500, 700, or even 1000+ words per minute.

HOW IT WORKS
Speedr uses RSVP (Rapid Serial Visual Presentation) to show you one word at a time. No more wasting time moving your eyes across the page. Words come to you.

PERFECT FOR
• ADHD readers who need focus
• Students with heavy reading loads
• Busy professionals
• Anyone who wants to read more

FEATURES
• Adjustable reading speed (10-1000+ WPM)
• Focus-enhancing visual guide
• Import your own documents (PDF, TXT)
• Dark and light themes
• Reading statistics
• Background music for focus

Download Speedr and unlock your reading potential.
```

### Screenshots Needed
1. Reader view with focal lines
2. Home screen
3. Speed control demonstration
4. Library view
5. Settings/themes
6. Paywall (optional)

---

## Future Features (Post-Launch)

### Version 1.1
- Background music/ambient sounds
- Share achievement cards
- Reading streaks

### Version 1.2
- URL import (paste article links)
- Paste text feature
- Widget for home screen

### Version 2.0
- Book library (curated free books)
- Genres and categories
- Recommendations

### Version 2.x
- Reading challenges
- Social features (compare with friends)
- Apple Watch companion

---

*Document Version: 1.0*
*Last Updated: January 2026*
*Project: Speedr*
