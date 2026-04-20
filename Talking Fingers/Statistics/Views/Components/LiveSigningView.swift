//
//  LiveSigningView.swift
//  Talking Fingers
//
//  Created by Krish Prasad on 3/1/26.
//
import SwiftUI

struct LiveSigningView: View {
    let sentenceModel: AISentenceModel
    var onBack: () -> Void
    var onComplete: (() -> Void)? = nil

    // Index of the word currently being signed (highlighted in black)
    @State private var currentWordIndex: Int = 0
    // Tracks which words have been completed
    @State private var completedWords: Set<Int> = []
    // Tracks which words the user explicitly skipped (not credited as completed).
    @State private var skippedWords: Set<Int> = []
    // True once the live signing view has reported a confidence at/above the
    // "good" threshold for the current word. Gates the Continue button.
    @State private var passedThreshold: Bool = false
    // Pending auto-advance task started when threshold is first reached.
    @State private var autoAdvanceTask: Task<Void, Never>?

    /// How long to wait after reaching the threshold before auto-advancing
    /// if the user hasn't manually tapped Continue.
    private let autoAdvanceDelay: Duration = .seconds(0.5)

    var glossWords: [Term] { sentenceModel.gloss }
    var isFinished: Bool { currentWordIndex >= glossWords.count }

    private var currentTargetWord: String {
        glossWords[safe: currentWordIndex]?.rawValue ?? ""
    }

    var body: some View {
        VStack(spacing: 0) {
            // Gloss sentence display
            glossRow
                .padding(.bottom, 20)

            // Live camera tied to the current target word.
            // Negative horizontal padding extends past the parent's 24pt
            // padding so the preview sits close to the screen edges.
            SigningPracticeView(
                signName: currentTargetWord.lowercased(),
                onConfidenceChange: { _ in
                    handleThresholdReached()
                },
                usesInternalPadding: false
            )
            .frame(maxWidth: .infinity)
            .frame(height: 480)
            .padding(.horizontal, -16)
            .padding(.bottom, 24)

            // Word progress circles
            wordProgressCircles
                .padding(.bottom, 24)

            // Action buttons row
            HStack(spacing: 12) {
                // Back button
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.gray.opacity(0.6))
                        .cornerRadius(8)
                }
                .frame(maxWidth: 64)

                // Skip current word without crediting it as completed
                Button(action: skipWord) {
                    Text("Skip")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(8)
                }
                .disabled(isFinished)

                // Continue button — only tappable once threshold is reached
                Button(action: advanceWord) {
                    Text(isFinished ? "Done ✓" : "Continue →")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(continueButtonColor)
                        .cornerRadius(8)
                }
                .disabled(!passedThreshold && !isFinished)
                .animation(.easeInOut(duration: 0.2), value: passedThreshold)
            }
        }
        .onDisappear {
            autoAdvanceTask?.cancel()
            autoAdvanceTask = nil
        }
    }

    // MARK: Continue Button Styling
    private var continueButtonColor: Color {
        if isFinished { return .green }
        if passedThreshold { return Color(hex: "#97C171") }
        return Color.gray.opacity(0.4)
    }

    // MARK: Gloss Row
    private var glossRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Array(glossWords.enumerated()), id: \.offset) { index, term in
                    Text(term.rawValue)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(colorForWord(at: index))
                        .animation(.easeInOut(duration: 0.3), value: currentWordIndex)
                }
            }
        }
    }

    // MARK: Word Progress Circles
    private var wordProgressCircles: some View {
        HStack(spacing: 16) {
            ForEach(Array(glossWords.enumerated()), id: \.offset) { index, _ in
                circleIcon(for: index)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    @ViewBuilder
    private func circleIcon(for index: Int) -> some View {
        let isCompleted = completedWords.contains(index)
        let isSkipped = skippedWords.contains(index)
        let isCurrent = index == currentWordIndex && !isFinished

        ZStack {
            Circle()
                .fill(circleFill(isCompleted: isCompleted, isSkipped: isSkipped, isCurrent: isCurrent))
                .overlay(
                    Group {
                        if isCurrent {
                            Circle()
                                .strokeBorder(Color(hex: "#F8BC3A"), lineWidth: 1.5)
                        }
                    }
                )
                .frame(width: 44, height: 44)

            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            } else if isSkipped {
                Image(systemName: "forward.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.gray)
            } else if isCurrent {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(hex: "#F8BC3A"))
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.gray.opacity(0.5))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentWordIndex)
    }

    private func circleFill(isCompleted: Bool, isSkipped: Bool, isCurrent: Bool) -> Color {
        if isCompleted { return .black }
        if isSkipped { return Color.gray.opacity(0.25) }
        if isCurrent { return Color(hex: "#FDF2D8") }
        return Color.gray.opacity(0.12)
    }

    // MARK: Helpers
    private func colorForWord(at index: Int) -> Color {
        if completedWords.contains(index) {
            return .gray
        } else if skippedWords.contains(index) {
            return .gray.opacity(0.55)
        } else if index == currentWordIndex {
            return .black
        } else {
            return .gray.opacity(0.35)
        }
    }

    /// Called by the camera view when confidence crosses the "good" threshold.
    /// Unlocks the Continue button and schedules an auto-advance after a few
    /// seconds in case the user doesn't tap it themselves.
    private func handleThresholdReached() {
        guard !isFinished, !passedThreshold else { return }
        passedThreshold = true

        autoAdvanceTask?.cancel()
        autoAdvanceTask = Task { @MainActor in
            try? await Task.sleep(for: autoAdvanceDelay)
            if Task.isCancelled { return }
            if passedThreshold && !isFinished {
                advanceWord()
            }
        }
    }

    private func advanceWord() {
        advance(markingCurrentAs: .completed)
    }

    private func skipWord() {
        advance(markingCurrentAs: .skipped)
    }

    private enum WordOutcome { case completed, skipped }

    private func advance(markingCurrentAs outcome: WordOutcome) {
        autoAdvanceTask?.cancel()
        autoAdvanceTask = nil

        guard currentWordIndex < glossWords.count else {
            if isFinished { onComplete?() }
            return
        }

        withAnimation {
            switch outcome {
            case .completed: completedWords.insert(currentWordIndex)
            case .skipped: skippedWords.insert(currentWordIndex)
            }
            currentWordIndex += 1
        }

        // Reset threshold for the next word (or leave false if finished).
        passedThreshold = false

        if isFinished {
            onComplete?()
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
