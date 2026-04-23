//
//  LiveSigningView.swift
//  Talking Fingers
//
//  Created by Krish Prasad on 3/1/26.
//
import SwiftUI

struct LiveSigningView: View {
    @Binding var sentenceModel: AISentenceModel
    var onBack: () -> Void
    var onSentenceFinished: ((Double) -> Void)? = nil
    /// When non-nil, the top gloss line uses this color for every word (e.g. with the score overlay).
    var glossUniformColor: Color? = nil
    var externalCameraVM: CameraVM? = nil

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
    // Max confidence score recorded for current word after passing threshold
    @State private var currentWordMaxScore: Double = 0
    // Stores the max score for each completed word
    @State private var wordMaxScores: [Int: Double] = [:]

    /// How long to wait after reaching the threshold before auto-advancing
    /// if the user hasn't manually tapped Continue.
    private let autoAdvanceDelay: Duration = .seconds(0.5)

    var glossWords: [Term] { sentenceModel.gloss }
    var isFinished: Bool { currentWordIndex >= glossWords.count }
    
    private var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    private var currentTargetWord: String {
        glossWords[safe: currentWordIndex]?.rawValue ?? ""
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text(sentenceModel.sentence)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(Color(hex: "#767676"))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                glossRow
            }
            .padding(.vertical, 10)

            // Live camera tied to the current target word.
            // Negative horizontal padding extends past the parent's 24pt
            // padding so the preview sits close to the screen edges.
            SigningPracticeView(
                signName: currentTargetWord.lowercased(),
                onConfidenceChange: { confidence in
                    handleThresholdReached(confidence: confidence)
                },
                usesInternalPadding: false,
                externalCameraVM: externalCameraVM
            )
            .frame(maxWidth: .infinity)
            .frame(height: 480)
            .padding(.horizontal, -16)
            .padding(.bottom, 24)

            // Word progress circles
            wordProgressCircles
                .padding(.bottom, 24)

            // Simulator-only controls
            if isSimulator {
                HStack(spacing: 12) {
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
                }
            }
        }
        .onDisappear {
            autoAdvanceTask?.cancel()
            autoAdvanceTask = nil
        }
    }

    // MARK: Gloss Row
    private var glossRow: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(glossWords.enumerated()), id: \.offset) { index, term in
                        Text(term.rawValue)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(colorForWord(at: index))
                            .animation(.easeInOut(duration: 0.3), value: currentWordIndex)
                            .id("gloss-\(index)")
                    }
                }
            }
            .onChange(of: currentWordIndex) { _, newIndex in
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo("gloss-\(newIndex)", anchor: .center)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Word Progress Circles
    private var wordProgressCircles: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(glossWords.enumerated()), id: \.offset) { index, _ in
                        circleIcon(for: index)
                            .id("circle-\(index)")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .onChange(of: currentWordIndex) { _, newIndex in
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo("circle-\(newIndex)", anchor: .center)
                }
            }
        }
    }

    /// Fixed column width so horizontal spacing between steps stays visually even
    /// (same circle size for every state; current is highlighted with a ring).
    private static let progressCircleColumnWidth: CGFloat = 72
    private static let progressCircleDiameter: CGFloat = 52

    @ViewBuilder
    private func circleIcon(for index: Int) -> some View {
        let isCompleted = completedWords.contains(index)
        let isSkipped = skippedWords.contains(index)
        let isCurrent = index == currentWordIndex && !isFinished
        let wordLabel = glossWords[safe: index]?.rawValue ?? ""
        let d = Self.progressCircleDiameter

        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(circleFill(isCompleted: isCompleted, isSkipped: isSkipped, isCurrent: isCurrent))
                    .frame(width: isCurrent ? d + 10 : d, height: isCurrent ? d + 10 : d)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(hex: "#71A046"))
                } else if isSkipped {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.gray)
                } else if isCurrent {
                    Image(systemName: "lightbulb.max")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(hex: "#F8BC3A"))
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(hex: "#B3B3B3"))
                }
            }
            .frame(width: Self.progressCircleColumnWidth, height: Self.progressCircleColumnWidth, alignment: .center)

            Text(wordLabel)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color(hex: "#767676"))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .opacity(isCurrent ? 1 : 0)
                .frame(height: 20)
        }
        .frame(width: Self.progressCircleColumnWidth)
        .animation(.easeInOut(duration: 0.3), value: currentWordIndex)
    }

    private func circleFill(isCompleted: Bool, isSkipped: Bool, isCurrent: Bool) -> Color {
        if isCompleted { return Color(hex: "#EAF3E3") }
        if isSkipped { return Color.gray.opacity(0.25) }
        if isCurrent { return Color(hex: "#FDF2D8") }
        return Color.gray.opacity(0.12)
    }

    // MARK: Helpers
    private func colorForWord(at index: Int) -> Color {
        if let glossUniformColor {
            return glossUniformColor
        }
        if completedWords.contains(index) {
            return .gray
        } else if skippedWords.contains(index) {
            return .gray.opacity(0.55)
        } else if index == currentWordIndex {
            return .black
        } else {
            return Color(hex: "#F0F0F0")
        }
    }

    /// Called by the camera view when confidence crosses the "good" threshold.
    /// Unlocks the Continue button and schedules an auto-advance after a few
    /// seconds in case the user doesn't tap it themselves.
    private func handleThresholdReached(confidence: Double) {
        guard !isFinished else { return }
        
        // Track max score after passing threshold
        if passedThreshold {
            currentWordMaxScore = max(currentWordMaxScore, confidence)
            return
        }
        
        passedThreshold = true
        currentWordMaxScore = confidence

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
            if isFinished { finalizeAndComplete() }
            return
        }

        withAnimation {
            switch outcome {
            case .completed:
                completedWords.insert(currentWordIndex)
                // In simulator without real detection, give a default good score
                let score = currentWordMaxScore > 0 ? currentWordMaxScore : (isSimulator ? 85 : 0)
                wordMaxScores[currentWordIndex] = score
            case .skipped:
                skippedWords.insert(currentWordIndex)
                wordMaxScores[currentWordIndex] = 85
            }
            currentWordIndex += 1
        }

        // Reset threshold and max score for the next word (or leave false if finished).
        passedThreshold = false
        currentWordMaxScore = 0

        if isFinished {
            finalizeAndComplete()
        }
    }
    
    private func finalizeAndComplete() {
        // Build array of word scores in order, then apply a +20% user-facing
        // boost (capped 0…100) before persisting and averaging.
        let rawScores = (0..<glossWords.count).map { wordMaxScores[$0] ?? 0 }
        let scores = rawScores.map { Self.userFacingSigningScore(from: $0) }
        sentenceModel.wordScores = scores
        let average = scores.isEmpty ? 0 : scores.reduce(0, +) / Double(scores.count)
        sentenceModel.score = Int(average.rounded())
        onSentenceFinished?(average)
    }

    /// +20% boost on raw per-word confidence (0–100), still capped at 100.
    private static func userFacingSigningScore(from raw: Double) -> Double {
        min(100, raw * 1.2)
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
