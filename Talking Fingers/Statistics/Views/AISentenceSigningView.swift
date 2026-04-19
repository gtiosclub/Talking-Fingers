//
//  AISentenceSigningView.swift
//  Talking Fingers
//
//  Created by Aimee on 2/22/26.
//

import SwiftUI

struct AISentenceSigningView: View {
    let sentenceModel: AISentenceModel
    /// Session progress 0.0...1.0 (e.g. currentSentenceIndex / totalSentences). Shown in the single progress bar.
    var sessionProgress: Double = 0
    var onSentenceComplete: (() -> Void)? = nil

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
        currentPage == 1 ? Color(hex: "#58A0DA") : Color.gray
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            CustomProgressBar(progress: sessionProgress)
                .padding(.top, 20)

            Text(subtitle)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(subtitleColor)
                .animation(.easeInOut, value: currentPage)

            if currentPage == 1 {
                PageOneContent(
                    sentenceModel: sentenceModel,
                    showGloss: $showGloss,
                    onContinue: {
                        withAnimation { currentPage = 2 }
                    }
                )
            } else if currentPage == 2 {
                LiveSigningView(
                    sentenceModel: sentenceModel,
                    onBack: {
                        withAnimation { currentPage = 1 }
                    },
                    onComplete: onSentenceComplete
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 30)
    }
}

struct PageOneContent: View {
    let sentenceModel: AISentenceModel
    @Binding var showGloss: Bool
    var onContinue: () -> Void

    private let glossGold = Color(hex: "#F8BC3A")
    private let glossCream = Color(hex: "#FDF2D8")

    /// Single-line ASL gloss, uppercase with spaces (matches design reference).
    private var glossLineString: String {
        sentenceModel.gloss
            .map(\.rawValue)
            .joined(separator: " ")
            .uppercased()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            Spacer()

            Text(sentenceModel.sentence)
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.black)
                .multilineTextAlignment(.leading)

            Button(action: { withAnimation { showGloss.toggle() } }) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .center, spacing: 12) {
                        glossBulbBadge
                        Text(showGloss ? "Hide gloss" : "Gloss")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(glossGold)
                        Spacer(minLength: 0)
                    }

                    if showGloss {
                        Text(glossLineString)
                            .font(.system(size: 17, weight: .semibold))
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

            Button(action: onContinue) {
                Text("Continue")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(hex: "#97C171"))
                    .cornerRadius(20)
            }
        }
    }

    /// Cream circle with golden outline-style bulb (or eye when hiding).
    private var glossBulbBadge: some View {
        ZStack {
            Circle()
                .fill(glossCream)
                .frame(width: 40, height: 40)
            Circle()
                .strokeBorder(glossGold.opacity(0.55), lineWidth: 1)
                .frame(width: 40, height: 40)
            Image(systemName: showGloss ? "eye.slash" : "lightbulb")
                .font(.system(size: 19, weight: .semibold))
                .symbolRenderingMode(.monochrome)
                .foregroundColor(glossGold)
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    let sampleData = AISentenceModel(
        sentence: "I didn't go to the store yesterday.",
        score: nil,
        practiceType: .words,
        gloss: [.yesterday, .store, .me, .goNot],
        completed: false
    )

    AISentenceSigningView(sentenceModel: sampleData)
}
