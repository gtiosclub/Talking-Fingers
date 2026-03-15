//
//  AISentenceSigningView.swift
//  Talking Fingers
//
//  Created by Aimee on 2/22/26.
//

import SwiftUI

struct AISentenceSigningView: View {
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
        VStack(alignment: .leading, spacing: 24) {
            CustomProgressBar(progress: progress)
                .padding(.top, 20)

            Text(subtitle)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.gray)
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
                    }
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

    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            Spacer()

            Text(sentenceModel.sentence)
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.black)
                .multilineTextAlignment(.leading)

            Button(action: { withAnimation { showGloss.toggle() } }) {
                HStack(spacing: 6) {
                    Image(systemName: showGloss ? "eye.slash" : "eye")
                    Text(showGloss ? "Hide gloss" : "Tap to reveal gloss!")
                }
                .font(.subheadline)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
            }

            if showGloss {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(sentenceModel.gloss, id: \.self) { term in
                            Text(term.rawValue)
                                .font(.headline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.gray.opacity(0.15))
                                .cornerRadius(8)
                        }
                    }
                }
                .transition(.opacity)
            }

            Spacer()

            Button(action: onContinue) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.gray)
                    .cornerRadius(8)
            }
        }
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
