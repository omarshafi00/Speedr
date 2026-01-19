//
//  SampleTexts.swift
//  Speedr
//
//  Reference: PROJECT_SPEC.md - "Sample Demo Text (The WOW Experience)"
//

import Foundation

/// Built-in sample texts for the app
enum SampleTexts {

    /// The main demo text - designed to create the "wow" experience
    /// Word count: ~180 words
    /// At 300 WPM: 36 seconds
    /// At 500 WPM: 22 seconds
    /// At 700 WPM: 15 seconds
    static let demo = """
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

    /// Short demo for quick testing
    static let shortDemo = """
    Welcome to Speedr. This is a quick demo of RSVP reading. Focus on the highlighted letter. Your brain processes words faster than you think. Try speeding up!
    """

    /// Word count for the main demo
    static var demoWordCount: Int {
        demo.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }

    /// Title for the demo document
    static let demoTitle = "Welcome to Speedr"
}
