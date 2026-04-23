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
    var onSentenceFinished: ((Double) -> Void)? = nil
    var onSubtitleChange: ((String) -> Void)? = nil
    /// When set (e.g. during sentence completion), all gloss terms use this color.
    var glossUniformColor: Color? = nil
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
                    onSentenceFinished: onSentenceFinished,
                    glossUniformColor: glossUniformColor,
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
                .font(.jakarta(size: 40, weight: .semibold))
                .foregroundColor(Color(hex: "#464646"))
                .multilineTextAlignment(.leading)

            VStack(alignment: .leading, spacing: 10) {
                Button(action: { withAnimation(.easeInOut(duration: 0.25)) { showGloss.toggle() } }) {
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: "wand.and.rays")
                            .font(.jakarta(size: 20, weight: .semibold))
                            .symbolRenderingMode(.monochrome)
                            .foregroundColor(glossGold)
                        Text("Gloss")
                            .font(.jakarta(size: 20, weight: .semibold))
                            .foregroundColor(glossGold)
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Text(glossLineString)
                    .font(.jakarta(size: 35, weight: .semibold))
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
