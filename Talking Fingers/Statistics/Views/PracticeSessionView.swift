//
//  PracticeSessionView.swift
//  Talking Fingers
//
//  Session that runs AISentenceSigningView for each sentence, then shows
//  completion screen with Extend (add 5 more) / Finish (return to Saved Practice).
//

import SwiftUI

struct PracticeSessionView: View {
    @Binding var sentences: [AISentenceModel]
    var onFinish: () -> Void
    var onExtend: () async -> Void

    @State private var currentSentenceIndex: Int = 0
    @State private var isExtending: Bool = false

    private var sessionProgress: Double {
        guard !sentences.isEmpty else { return 0 }
        return Double(currentSentenceIndex + 1) / Double(sentences.count)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top: Leave only (single progress bar is inside AISentenceSigningView, above subtitle)
            HStack {
                Button(action: onFinish) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Leave")
                    }
                    .font(.body)
                    .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 4)

            if currentSentenceIndex < sentences.count {
                AISentenceSigningView(
                    sentenceModel: sentences[currentSentenceIndex],
                    sessionProgress: sessionProgress,
                    onSentenceComplete: {
                        withAnimation {
                            currentSentenceIndex += 1
                        }
                    }
                )
                .id(currentSentenceIndex)
            } else {
                completionContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    private var completionContent: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Practice completed!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            Text("Completed")
                .font(.title3)
                .foregroundColor(.secondary)

            Spacer()

            HStack(spacing: 16) {
                Button(action: extendTapped) {
                    Text("Extend")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray5))
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .disabled(isExtending)

                Button(action: onFinish) {
                    Text("Finish")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.darkGray))
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private func extendTapped() {
        guard !isExtending else { return }
        isExtending = true
        Task {
            await onExtend()
            await MainActor.run {
                isExtending = false
            }
        }
    }
}
