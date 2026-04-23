//
//  AISentenceSigningView.swift
//  Talking Fingers
//
//  Created by Aimee on 2/22/26.
//

import SwiftUI

struct AISentenceSigningView: View {
    @Binding var sentenceModel: AISentenceModel
    @Binding var currentPage: Int
    var onSentenceComplete: (() -> Void)? = nil
    var onSubtitleChange: ((String) -> Void)? = nil
    /// Optional externally-owned camera VM. When provided, the live signing
    /// step reuses it instead of creating its own, which avoids tearing the
    /// camera session down and back up between sentences.
    var externalCameraVM: CameraVM? = nil

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
            if currentPage == 1 {
                PageOneContent(
                    sentenceModel: sentenceModel,
                    showGloss: $showGloss
                )
            } else if currentPage == 2 {
                LiveSigningView(
                    sentenceModel: $sentenceModel,
                    onBack: {
                        withAnimation { currentPage = 1 }
                    },
                    onComplete: onSentenceComplete,
                    externalCameraVM: externalCameraVM
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 30)
        .onAppear {
            onSubtitleChange?(subtitle)
        }
        .onChange(of: currentPage) { _, _ in
            onSubtitleChange?(subtitle)
        }
    }
}

struct PageOneContent: View {
    let sentenceModel: AISentenceModel
    @Binding var showGloss: Bool

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
                            .font(.system(size: 35, weight: .semibold))
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
    @Previewable @State var sampleData = AISentenceModel(
        sentence: "I went to the store yesterday.",
        score: nil,
        practiceType: .words,
        gloss: [.yesterday, .store, .me, .go],
        completed: false
    )

    AISentenceSigningView(sentenceModel: $sampleData, currentPage: .constant(1))
}
