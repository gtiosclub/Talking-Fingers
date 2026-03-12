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

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            CustomProgressBarMacOS(progress: progress)
                .padding(.top, 40)

            Text(subtitle)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.secondary)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 48) {
            Spacer()

            Text(sentenceModel.sentence)
                .font(.system(size: 56, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .lineSpacing(8)

            Button(action: { withAnimation { showGloss.toggle() } }) {
                HStack(spacing: 8) {
                    Image(systemName: showGloss ? "eye.slash" : "eye")
                        .font(.system(size: 16))
                    Text(showGloss ? "Hide gloss" : "Tap to reveal gloss!")
                        .font(.system(size: 16))
                }
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .buttonStyle(.plain)

            if showGloss {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(sentenceModel.gloss, id: \.self) { term in
                            Text(term.rawValue)
                                .font(.system(size: 18, weight: .semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.gray.opacity(0.12))
                                .cornerRadius(10)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

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
                .fill(isCompleted ? Color.primary : (isCurrent ? Color.gray.opacity(0.25) : Color.gray.opacity(0.12)))
                .frame(width: 52, height: 52)

            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            } else if isCurrent {
                Image(systemName: "eye")
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
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

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .frame(width: geometry.size.width, height: 12)
                    .foregroundColor(.gray.opacity(0.2))

                RoundedRectangle(cornerRadius: 8)
                    .frame(width: min(CGFloat(progress) * geometry.size.width, geometry.size.width), height: 12)
                    .foregroundColor(.accentColor)
            }
        }
        .frame(height: 12)
    }
}

// MARK: - Preview

#Preview {
    let sampleData = AISentenceModel(
        sentence: "I didn't go to the store yesterday.",
        score: nil,
        practiceType: .words,
        gloss: [.yesterday, .store, .me, .goNot],
        completed: false
    )

    AISentenceSigningViewMacOS(sentenceModel: sampleData)
        .frame(width: 1000, height: 700)
}
