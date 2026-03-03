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

    // Index of the word currently being signed (highlighted in black)
    @State private var currentWordIndex: Int = 0
    // Tracks which words have been completed
    @State private var completedWords: Set<Int> = []

    var glossWords: [String] { sentenceModel.gloss }
    var isFinished: Bool { completedWords.count >= glossWords.count }

    var body: some View {
        VStack(spacing: 0) {
            // Gloss sentence display
            glossRow
                .padding(.bottom, 20)

            // Camera placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray).opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                    )

                VStack(spacing: 8) {
                    Image(systemName: "camera")
                        .font(.system(size: 36))
                        .foregroundColor(.gray.opacity(0.4))
                    Text("Camera coming soon")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.4))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 340)
            .padding(.bottom, 24)

            // Word progress circles
            wordProgressCircles
                .padding(.bottom, 24)

            // Action buttons row
            HStack(spacing: 16) {
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

                // "Complete Sign" simulation button
                Button(action: advanceWord) {
                    Text(isFinished ? "Done ✓" : "Next Word →")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isFinished ? Color.green : Color.black)
                        .cornerRadius(8)
                }
                .disabled(isFinished)
            }
        }
    }

    // MARK: Gloss Row
    private var glossRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Array(glossWords.enumerated()), id: \.offset) { index, word in
                    Text(word)
                        .font(.system(size: 18, weight: .bold))
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
        let isCurrent = index == currentWordIndex && !isFinished

        ZStack {
            Circle()
                .fill(isCompleted ? Color.black : (isCurrent ? Color.gray.opacity(0.25) : Color.gray.opacity(0.12)))
                .frame(width: 44, height: 44)

            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            } else if isCurrent {
                // Eye icon: currently active
                Image(systemName: "eye")
                    .font(.system(size: 14))
                    .foregroundColor(.black)
            } else {
                // Locked
                Image(systemName: "lock.fill")
                    .font(.system(size: 14))
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
            return .black
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
                // All done — move index past end to signal finished
                currentWordIndex = glossWords.count
            }
        }
    }
}
