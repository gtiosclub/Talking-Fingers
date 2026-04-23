//
//  AISentenceSigningViewMacOS.swift
//  Talking Fingers
//
//  Created by Judy Hsu on 2/23/26.
//

import SwiftUI

struct AISentenceSigningViewMacOS: View {
    let sentenceModel: AISentenceModel
    var sessionProgress: Double = 0.3
    var onSentenceComplete: (() -> Void)? = nil
    /// Optional externally-owned camera VM. When provided, the live signing
    /// step reuses it instead of creating its own, which avoids tearing the
    /// camera session down and back up between sentences.
    var externalCameraVM: CameraVM? = nil

    @State private var currentPage: Int = 1
    @State private var showGloss: Bool = false

    var subtitle: String {
        switch currentPage {
        case 1: return "New sentence!"
        case 2: return "Sign each word!"
        default: return ""
        }
    }

    private var subtitleColor: Color {
        currentPage == 1 ? Color(hex: "#58A0DA") : Color.secondary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            if currentPage == 1 {
                CustomProgressBarMacOS(progress: sessionProgress)
            }

            Text(subtitle)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(subtitleColor)
                .animation(.easeInOut, value: currentPage)

            if currentPage == 1 {
                PageOneContentMacOS(
                    sentenceModel: sentenceModel,
                    showGloss: $showGloss,
                    onContinue: {
                        withAnimation { currentPage = 2 }
                    }
                )
            } else if currentPage == 2 {
                LiveSigningViewMacOS(
                    sentenceModel: sentenceModel,
                    onBack: {
                        withAnimation { currentPage = 1 }
                    },
                    onComplete: onSentenceComplete,
                    externalCameraVM: externalCameraVM
                )
            }
        }
        .padding(.top, 40)
        .padding(.horizontal, 80)
        .padding(.bottom, 40)
        .frame(minWidth: 800, minHeight: 600)
        .animation(.easeInOut(duration: 0.3), value: showGloss)
    }
}

// MARK: - Page One: Sentence Display + Gloss

struct PageOneContentMacOS: View {
    let sentenceModel: AISentenceModel
    @Binding var showGloss: Bool
    var onContinue: () -> Void

    private let glossGold = Color(hex: "#F8BC3A")
    private let glossCream = Color(hex: "#FDF2D8")

    private var glossLineString: String {
        sentenceModel.gloss
            .map(\.rawValue)
            .joined(separator: " ")
            .uppercased()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 48) {
            Spacer()

            Text(sentenceModel.sentence)
                .font(.system(size: 56, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .lineSpacing(8)

            Button(action: { withAnimation { showGloss.toggle() } }) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .center, spacing: 14) {
                        glossBulbBadge
                        Text(showGloss ? "Hide gloss" : "Gloss")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(glossGold)
                        Spacer(minLength: 0)
                    }

                    if showGloss {
                        Text(glossLineString)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(white: 0.58))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Spacer()

            HStack(spacing: 16) {
                Button(action: {
                    print("Skip tapped")
                }) {
                    Text("Skip")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)

                Button(action: onContinue) {
                    Text("Continue")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var glossBulbBadge: some View {
        ZStack {
            Circle()
                .fill(glossCream)
                .frame(width: 48, height: 48)
            Circle()
                .strokeBorder(glossGold.opacity(0.55), lineWidth: 1)
                .frame(width: 48, height: 48)
            Image(systemName: showGloss ? "eye.slash" : "lightbulb")
                .font(.system(size: 22, weight: .semibold))
                .symbolRenderingMode(.monochrome)
                .foregroundColor(glossGold)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Page Two: Live Signing

struct LiveSigningViewMacOS: View {
    let sentenceModel: AISentenceModel
    var onBack: () -> Void
    var onComplete: (() -> Void)? = nil
    var externalCameraVM: CameraVM? = nil

    @State private var currentWordIndex: Int = 0
    @State private var completedWords: Set<Int> = []
    @State private var skippedWords: Set<Int> = []
    @State private var passedThreshold: Bool = false
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
            // Gloss sentence row
            glossRow
                .padding(.bottom, 24)

            // Live camera tied to the current target word.
            // Negative horizontal padding extends past the parent's 80pt
            // padding so the preview sits close to the window edges.
            SigningPracticeView(
                signName: currentTargetWord.lowercased(),
                onConfidenceChange: { _ in
                    handleThresholdReached()
                },
                showsLeaveButton: false,
                usesInternalPadding: false,
                externalCameraVM: externalCameraVM
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, -64)
            .padding(.bottom, 28)

            // Word progress circles
            wordProgressCircles
                .padding(.bottom, 28)

            // Action buttons
            HStack(spacing: 16) {
                Button(action: onBack) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.gray.opacity(0.6))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)

                Button(action: skipWord) {
                    Text("Skip")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .disabled(isFinished)

                Button(action: advanceWord) {
                    Text(isFinished ? "Done ✓" : "Continue →")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(continueButtonColor)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .disabled(!passedThreshold && !isFinished)
                .animation(.easeInOut(duration: 0.2), value: passedThreshold)
            }
        }
        .onDisappear {
            autoAdvanceTask?.cancel()
            autoAdvanceTask = nil
        }
    }

    private var continueButtonColor: Color {
        if isFinished { return .green }
        if passedThreshold { return Color.accentColor }
        return Color.gray.opacity(0.4)
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

    // MARK: Gloss Row

    private var glossRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(glossWords.enumerated()), id: \.offset) { index, term in
                    Text(term.rawValue)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(colorForWord(at: index))
                        .animation(.easeInOut(duration: 0.3), value: currentWordIndex)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // MARK: Word Progress Circles

    private var wordProgressCircles: some View {
        HStack(spacing: 20) {
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
                .frame(width: 52, height: 52)

            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            } else if isSkipped {
                Image(systemName: "forward.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.gray)
            } else if isCurrent {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(Color(hex: "#F8BC3A"))
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.gray.opacity(0.5))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentWordIndex)
    }

    private func circleFill(isCompleted: Bool, isSkipped: Bool, isCurrent: Bool) -> Color {
        if isCompleted { return .primary }
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
            return .primary
        } else {
            return .gray.opacity(0.35)
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

        passedThreshold = false

        if isFinished {
            onComplete?()
        }
    }
}

// MARK: - Progress Bar

struct CustomProgressBarMacOS: View {
    var progress: Double
    private let trackColor = Color(hex: "#A9CEEC26")
    private let fillColor = Color(hex: "#58A0DA")
    private let barHeight: CGFloat = 10

    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = barHeight
            let rawFill = CGFloat(progress) * w
            let fillW = progress <= 0 ? 0 : max(h * 0.5, min(rawFill, w))

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(trackColor)

                Capsule()
                    .fill(fillColor)
                    .frame(width: fillW)
            }
            .frame(width: w, height: h)
        }
        .frame(height: barHeight)
    }
}

// MARK: - Preview

#Preview {
    let sampleData = AISentenceModel(
        sentence: "I went to the store yesterday.",
        score: nil,
        practiceType: .words,
        gloss: [.yesterday, .store, .me, .go],
        completed: false
    )

    AISentenceSigningViewMacOS(sentenceModel: sampleData)
        .frame(width: 1000, height: 700)
}
