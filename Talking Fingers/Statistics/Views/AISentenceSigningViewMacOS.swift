//
//  AISentenceSigningViewMacOS.swift
//  Talking Fingers
//
//  Created by Judy Hsu on 2/23/26.
//

import SwiftUI

struct AISentenceSigningViewMacOS: View {
    let sentenceModel: AISentenceModel

    @State private var progress: Double = 0.3
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
            CustomProgressBarMacOS(progress: progress)
                .padding(.top, 40)

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
                    }
                )
            }
        }
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

    @State private var currentWordIndex: Int = 0
    @State private var completedWords: Set<Int> = []

    var glossWords: [Term] { sentenceModel.gloss }
    var isFinished: Bool { completedWords.count >= glossWords.count }

    var body: some View {
        VStack(spacing: 0) {
            // Gloss sentence row
            glossRow
                .padding(.bottom, 24)

            // Camera placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.gray.opacity(0.25), lineWidth: 1)
                    )

                VStack(spacing: 12) {
                    Image(systemName: "camera")
                        .font(.system(size: 44))
                        .foregroundColor(.gray.opacity(0.35))
                    Text("Camera coming soon")
                        .font(.system(size: 16))
                        .foregroundColor(.gray.opacity(0.4))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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

                Button(action: advanceWord) {
                    Text(isFinished ? "Done ✓" : "Next Word →")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(isFinished ? Color.green : Color.accentColor)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .disabled(isFinished)
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
        let isCurrent = index == currentWordIndex && !isFinished

        ZStack {
            Circle()
                .fill(isCompleted ? Color.primary : (isCurrent ? Color(hex: "#FDF2D8") : Color.gray.opacity(0.12)))
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

    // MARK: Helpers

    private func colorForWord(at index: Int) -> Color {
        if completedWords.contains(index) {
            return .gray
        } else if index == currentWordIndex {
            return .primary
        } else {
            return .gray.opacity(0.35)
        }
    }

    private func advanceWord() {
        guard currentWordIndex < glossWords.count else { return }
        withAnimation {
            completedWords.insert(currentWordIndex)
            if currentWordIndex < glossWords.count - 1 {
                currentWordIndex += 1
            } else {
                currentWordIndex = glossWords.count
            }
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
