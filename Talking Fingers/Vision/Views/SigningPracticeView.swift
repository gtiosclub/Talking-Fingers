//
//  SigningPracticeView.swift
//  Talking Fingers
//

import SwiftUI

struct SigningPracticeView: View {

    // Example sentence
    let words: [String] = ["YESTERDAY", "STORE", "GO-NOT"]

    @State private var currentWordIndex: Int = 1

    var body: some View {

        VStack(spacing: 20) {

            // MARK: Back Button
            HStack {
                Button("Back") {
                    // navigation later
                }
                .foregroundColor(.gray)

                Spacer()
            }

            // MARK: Phrase Header
            PhraseHeader(
                words: words,
                currentWordIndex: currentWordIndex
            )

            // MARK: Camera Window (replaces cartoon)
            CameraView()
                .frame(height: 420)
                .clipShape(
                    RoundedRectangle(cornerRadius: 20)
                )
                .shadow(radius: 10)

            // MARK: Progress Dots
            WordProgressDots(
                total: words.count,
                current: currentWordIndex
            )

            // MARK: Navigation Buttons
            HStack(spacing: 40) {

                Button("Previous") {
                    previousWord()
                }
                .buttonStyle(.bordered)

                Button("Next") {
                    nextWord()
                }
                .buttonStyle(.borderedProminent)

            }

            Spacer()
        }
        .padding()
    }

    // MARK: Navigation Logic

    func nextWord() {
        if currentWordIndex < words.count - 1 {
            currentWordIndex += 1
        }
    }

    func previousWord() {
        if currentWordIndex > 0 {
            currentWordIndex -= 1
        }
    }
}

#Preview {
    SigningPracticeView()
}