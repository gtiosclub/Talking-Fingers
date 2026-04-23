//
//  AISentenceSigningViewMacOS.swift
//  Talking Fingers
//

import SwiftUI

// MARK: - Top-level Mac signing view

struct AISentenceSigningViewMacOS: View {
    @Binding var sentenceModel: AISentenceModel
    @Binding var currentPage: Int
    var sessionProgress: Double = 0.3
    var onSentenceFinished: ((Double) -> Void)? = nil
    var onSubtitleChange: ((String) -> Void)? = nil
    var glossUniformColor: Color? = nil
    var externalCameraVM: CameraVM? = nil

    @State private var showGloss: Bool = false

    private var subtitle: String {
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
        Group {
            if currentPage == 1 {
                VStack(alignment: .leading, spacing: 32) {
                    CustomProgressBarMacOS(progress: sessionProgress)

                    Text(subtitle)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(subtitleColor)

                    PageOneContentMacOS(
                        sentenceModel: sentenceModel,
                        showGloss: $showGloss
                    )
                }
                .padding(.top, 40)
                .padding(.horizontal, 40)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .transition(.opacity.combined(with: .move(edge: .leading)))
            } else if currentPage == 2 {
                LiveSigningViewMacOS(
                    sentenceModel: $sentenceModel,
                    onSentenceFinished: onSentenceFinished,
                    glossUniformColor: glossUniformColor,
                    externalCameraVM: externalCameraVM
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.25), value: currentPage)
        .onAppear {
            onSubtitleChange?(subtitle)
        }
        .onChange(of: currentPage) { _, _ in
            onSubtitleChange?(subtitle)
        }
    }
}

// MARK: - Page One: Sentence Display + Gloss
// No action buttons here — Continue is provided by PracticeSessionView (same as iOS).

struct PageOneContentMacOS: View {
    let sentenceModel: AISentenceModel
    @Binding var showGloss: Bool

    private let glossGold = Color(hex: "#ECA509")

    private var glossLineString: String {
        sentenceModel.gloss
            .map(\.rawValue)
            .joined(separator: " ")
            .uppercased()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            Spacer(minLength: 0)

            Text(sentenceModel.sentence)
                .font(.system(size: 48, weight: .semibold))
                .foregroundColor(Color(hex: "#464646"))
                .multilineTextAlignment(.leading)

            VStack(alignment: .leading, spacing: 10) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) { showGloss.toggle() }
                }) {
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: "wand.and.rays")
                            .font(.system(size: 22, weight: .semibold))
                            .symbolRenderingMode(.monochrome)
                            .foregroundColor(glossGold)
                        Text("Gloss")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(glossGold)
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Text(glossLineString)
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundColor(Color(white: 0.58))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .opacity(showGloss ? 1 : 0)
                    .allowsHitTesting(showGloss)
                    .accessibilityHidden(!showGloss)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - Page Two: Live Signing (macOS)
// Matches iOS LiveSigningView — only the camera with a "Skip word" overlay.
// No Back/Continue/Done buttons; auto-advance fires after the confidence threshold.

struct LiveSigningViewMacOS: View {
    @Binding var sentenceModel: AISentenceModel
    var onSentenceFinished: ((Double) -> Void)? = nil
    var glossUniformColor: Color? = nil
    var externalCameraVM: CameraVM? = nil

    @State private var currentWordIndex: Int = 0
    @State private var completedWords: Set<Int> = []
    @State private var skippedWords: Set<Int> = []
    @State private var passedThreshold: Bool = false
    @State private var autoAdvanceTask: Task<Void, Never>?
    @State private var currentWordMaxScore: Double = 0
    @State private var wordMaxScores: [Int: Double] = [:]
    @State private var showHintSheet: Bool = false

    private let autoAdvanceDelay: Duration = .seconds(0.5)

    var glossWords: [Term] { sentenceModel.gloss }
    var isFinished: Bool { currentWordIndex >= glossWords.count }

    private var currentTargetWord: String {
        glossWords[safe: currentWordIndex]?.rawValue ?? ""
    }

    var body: some View {
        VStack(spacing: 0) {
            // English sentence + scrollable gloss row (left-aligned)
            VStack(alignment: .leading, spacing: 8) {
                Text(sentenceModel.sentence)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(Color(hex: "#767676"))

                glossRow
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 40)
            .padding(.top, 24)
            .padding(.bottom, 16)

            // Camera with "Skip word" overlay — fills all available height
            ZStack(alignment: .bottomTrailing) {
                SigningPracticeView(
                    signName: currentTargetWord.lowercased(),
                    onConfidenceChange: { confidence in
                        handleThresholdReached(confidence: confidence)
                    },
                    showsLeaveButton: false,
                    usesInternalPadding: false,
                    externalCameraVM: externalCameraVM
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                if !isFinished {
                    Button(action: skipWord) {
                        Text("Skip word")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color(hex: "#97C171"))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 24)
                    .padding(.bottom, 24)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 24)

            // Word progress circles (centered)
            wordProgressCircles
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 40)
                .padding(.bottom, 28)
        }
        .onDisappear {
            autoAdvanceTask?.cancel()
            autoAdvanceTask = nil
        }
        .sheet(isPresented: $showHintSheet) {
            SignHintSheetView(
                word: currentTargetWord,
                onDismiss: { showHintSheet = false }
            )
            .frame(minWidth: 900, minHeight: 600)
        }
    }

    // MARK: Threshold + Auto-advance

    private func handleThresholdReached(confidence: Double) {
        guard !isFinished else { return }
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

    private func advanceWord() { advance(markingCurrentAs: .completed) }
    private func skipWord()    { advance(markingCurrentAs: .skipped) }

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
                wordMaxScores[currentWordIndex] = currentWordMaxScore > 0 ? currentWordMaxScore : 0
            case .skipped:
                skippedWords.insert(currentWordIndex)
                wordMaxScores[currentWordIndex] = Self.skippedWordRawScore
            }
            currentWordIndex += 1
        }

        passedThreshold = false
        currentWordMaxScore = 0

        if isFinished { finalizeAndComplete() }
    }

    private func finalizeAndComplete() {
        let rawScores = (0..<glossWords.count).map { wordMaxScores[$0] ?? 0 }
        let scores = rawScores.map { Self.userFacingSigningScore(from: $0) }
        sentenceModel.wordScores = scores
        let average = scores.isEmpty ? 0 : scores.reduce(0, +) / Double(scores.count)
        sentenceModel.score = Int(average.rounded())
        onSentenceFinished?(average)
    }

    private static func userFacingSigningScore(from raw: Double) -> Double { min(100, raw * 1.2) }
    private static let skippedWordRawScore: Double = 50.0 / 1.2

    // MARK: Gloss Row

    private var glossRow: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(glossWords.enumerated()), id: \.offset) { index, term in
                        Text(term.rawValue)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(glossWordColor(at: index))
                            .animation(.easeInOut(duration: 0.3), value: currentWordIndex)
                            .id("mac-gloss-\(index)")
                    }
                }
            }
            .onChange(of: currentWordIndex) { _, newIndex in
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo("mac-gloss-\(newIndex)", anchor: .center)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func glossWordColor(at index: Int) -> Color {
        if let c = glossUniformColor { return c }
        if completedWords.contains(index) { return .gray }
        if skippedWords.contains(index)   { return .gray.opacity(0.55) }
        if index == currentWordIndex      { return .primary }
        return Color(hex: "#D0D0D0")
    }

    // MARK: Word Progress Circles

    private var wordProgressCircles: some View {
        HStack(spacing: 16) {
            ForEach(Array(glossWords.enumerated()), id: \.offset) { index, _ in
                circleIcon(for: index)
            }
        }
    }

    @ViewBuilder
    private func circleIcon(for index: Int) -> some View {
        let isCompleted = completedWords.contains(index)
        let isSkipped   = skippedWords.contains(index)
        let isCurrent   = index == currentWordIndex && !isFinished
        let wordLabel   = glossWords[safe: index]?.rawValue ?? ""
        let diameter: CGFloat = isCurrent ? 62 : 52

        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(circleFill(isCompleted: isCompleted, isSkipped: isSkipped, isCurrent: isCurrent))
                    .frame(width: diameter, height: diameter)
                    .overlay {
                        if isCurrent {
                            Circle()
                                .strokeBorder(Color(hex: "#F8BC3A"), lineWidth: 1.5)
                                .frame(width: diameter, height: diameter)
                        }
                    }

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(hex: "#71A046"))
                } else if isSkipped {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.gray)
                } else if isCurrent {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color(hex: "#F8BC3A"))
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.gray.opacity(0.5))
                }
            }
            .contentShape(Circle())
            .onTapGesture {
                if isCurrent { showHintSheet = true }
            }

            Text(wordLabel)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(hex: "#767676"))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .opacity(isCurrent ? 1 : 0)
                .frame(height: 17)
        }
        .frame(width: 72)
        .animation(.easeInOut(duration: 0.3), value: currentWordIndex)
    }

    private func circleFill(isCompleted: Bool, isSkipped: Bool, isCurrent: Bool) -> Color {
        if isCompleted { return Color(hex: "#EAF3E3") }
        if isSkipped   { return Color.gray.opacity(0.25) }
        if isCurrent   { return Color(hex: "#FDF2D8") }
        return Color.gray.opacity(0.12)
    }
}

// MARK: - Progress Bar

struct CustomProgressBarMacOS: View {
    var progress: Double
    private let trackColor = Color(hex: "#A9CEEC26")
    private let fillColor  = Color(hex: "#58A0DA")
    private let barHeight: CGFloat = 10

    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let rawFill = CGFloat(progress) * w
            let fillW = progress <= 0 ? 0 : max(barHeight * 0.5, min(rawFill, w))

            ZStack(alignment: .leading) {
                Capsule().fill(trackColor)
                Capsule().fill(fillColor).frame(width: fillW)
            }
            .frame(width: w, height: barHeight)
        }
        .frame(height: barHeight)
    }
}
