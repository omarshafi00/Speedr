//
//  ReaderViewModel.swift
//  Speedr
//
//  Reference: PROJECT_SPEC.md - "READER VIEW", "SPEED CONTROLS", "TIMING CALCULATION"
//

import SwiftUI
import Combine

/// ViewModel for the RSVP reader
@Observable
final class ReaderViewModel {

    // MARK: - Published State

    /// All words in the document
    private(set) var words: [String] = []

    /// Current word index (0-based)
    private(set) var currentIndex: Int = 0

    /// Current reading speed in words per minute
    private(set) var wpm: Int = Constants.Reader.defaultWPM

    /// Whether the reader is currently playing
    private(set) var isPlaying: Bool = false

    /// Whether the document has been completed
    private(set) var isCompleted: Bool = false

    /// Whether the user has Pro subscription (affects speed limits)
    var isPro: Bool = false

    /// Custom highlight color for ORP character
    var highlightColor: Color = ThemeColors.highlightRed

    /// Font size multiplier
    var fontSizeMultiplier: CGFloat = 1.0

    // MARK: - Computed Properties

    /// The current word to display
    var currentWord: String {
        guard currentIndex < words.count else { return "" }
        return words[currentIndex]
    }

    /// Total number of words
    var totalWords: Int {
        words.count
    }

    /// Progress as percentage (0.0 to 1.0)
    var progress: Double {
        TextProcessor.progress(currentIndex: currentIndex, totalWords: totalWords)
    }

    /// Progress as percentage string
    var progressPercentage: String {
        "\(Int(progress * 100))%"
    }

    /// Number of words remaining
    var wordsRemaining: Int {
        TextProcessor.wordsRemaining(currentIndex: currentIndex, totalWords: totalWords)
    }

    /// Estimated time remaining at current speed
    var timeRemaining: TimeInterval {
        TextProcessor.estimatedReadingTime(wordCount: wordsRemaining, wpm: wpm)
    }

    /// Formatted time remaining string
    var timeRemainingFormatted: String {
        TextProcessor.formatReadingTime(timeRemaining)
    }

    /// WPM display string
    var wpmDisplay: String {
        "\(wpm) wpm"
    }

    /// Actual font size based on multiplier
    var fontSize: CGFloat {
        Constants.Reader.defaultFontSize * fontSizeMultiplier
    }

    /// Maximum WPM allowed based on subscription
    var maxAllowedWPM: Int {
        Constants.Limits.maxAllowedWPM(isPro: isPro)
    }

    /// Whether user can increase speed (not at limit)
    var canIncreaseSpeed: Bool {
        wpm < maxAllowedWPM
    }

    /// Whether user can decrease speed (not at minimum)
    var canDecreaseSpeed: Bool {
        wpm > Constants.Reader.minWPM
    }

    // MARK: - Private Properties

    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {}

    /// Initialize with text content
    /// - Parameter text: The text to read
    convenience init(text: String) {
        self.init()
        loadText(text)
    }

    /// Initialize with array of words
    /// - Parameter words: Pre-split words array
    convenience init(words: [String]) {
        self.init()
        self.words = words
    }

    // MARK: - Content Loading

    /// Load text content for reading
    /// - Parameter text: The full text to read
    func loadText(_ text: String) {
        stop()
        words = TextProcessor.splitIntoWords(text)
        currentIndex = 0
        isCompleted = false
    }

    /// Load pre-split words
    /// - Parameter words: Array of words
    func loadWords(_ words: [String]) {
        stop()
        self.words = words
        currentIndex = 0
        isCompleted = false
    }

    // MARK: - Playback Control

    /// Start or resume reading
    func play() {
        guard !words.isEmpty, !isCompleted else { return }

        isPlaying = true
        startTimer()
    }

    /// Pause reading
    func pause() {
        isPlaying = false
        stopTimer()
    }

    /// Toggle play/pause state
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    /// Stop reading and reset to beginning
    func stop() {
        pause()
        currentIndex = 0
        isCompleted = false
    }

    /// Restart from the beginning
    func restart() {
        stop()
        play()
    }

    // MARK: - Navigation

    /// Move to the next word
    func nextWord() {
        guard currentIndex < words.count - 1 else {
            // Reached the end
            pause()
            isCompleted = true
            return
        }

        currentIndex += 1
    }

    /// Move to the previous word
    func previousWord() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        isCompleted = false
    }

    /// Jump to a specific word index
    /// - Parameter index: Target word index
    func jumpToWord(at index: Int) {
        let clampedIndex = max(0, min(index, words.count - 1))
        currentIndex = clampedIndex
        isCompleted = clampedIndex >= words.count - 1
    }

    /// Jump to a specific progress percentage
    /// - Parameter progress: Progress value (0.0 to 1.0)
    func jumpToProgress(_ progress: Double) {
        let targetIndex = Int(Double(words.count - 1) * progress)
        jumpToWord(at: targetIndex)
    }

    // MARK: - Speed Control

    /// Increase reading speed by step amount
    func increaseSpeed() {
        let newWPM = wpm + Constants.Reader.speedStep
        setSpeed(newWPM)
    }

    /// Decrease reading speed by step amount
    func decreaseSpeed() {
        let newWPM = wpm - Constants.Reader.speedStep
        setSpeed(newWPM)
    }

    /// Set reading speed to specific value
    /// - Parameter newWPM: Target WPM value
    func setSpeed(_ newWPM: Int) {
        // Clamp to valid range
        let minWPM = Constants.Reader.minWPM
        let maxWPM = maxAllowedWPM

        wpm = max(minWPM, min(newWPM, maxWPM))

        // Restart timer if playing to apply new speed
        if isPlaying {
            restartTimer()
        }
    }

    // MARK: - Timer Management

    private func startTimer() {
        stopTimer()

        let interval = TextProcessor.timeIntervalPerWord(wpm: wpm)

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.timerFired()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func restartTimer() {
        if isPlaying {
            startTimer()
        }
    }

    private func timerFired() {
        nextWord()

        // Check if we've reached the end
        if isCompleted {
            stopTimer()
        }
    }

    // MARK: - Cleanup

    deinit {
        stopTimer()
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension ReaderViewModel {
    /// Create a sample view model for previews
    static var preview: ReaderViewModel {
        let vm = ReaderViewModel()
        vm.loadText("Welcome to Speedr. Right now, you are reading faster than most people. This is called RSVP. Rapid Serial Visual Presentation.")
        return vm
    }

    /// Create a view model at specific progress
    static func preview(atProgress progress: Double) -> ReaderViewModel {
        let vm = preview
        vm.jumpToProgress(progress)
        return vm
    }
}
#endif
