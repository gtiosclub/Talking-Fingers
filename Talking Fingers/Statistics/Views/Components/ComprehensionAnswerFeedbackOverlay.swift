//
//  ComprehensionAnswerFeedbackOverlay.swift
//  Talking Fingers
//
//  Bottom sheet shown after submitting sentence comprehension (correct / incorrect).
//  Styling aligns with SentenceCompletionOverlay / signing flow.
//

import SwiftUI

struct ComprehensionAnswerFeedbackOverlay: View {
    let isCorrect: Bool
    let answerPhrase: String
    @Binding var isBookmarked: Bool
    var onContinue: () -> Void

    private var textAccent: Color {
        isCorrect ? Color(hex: "#71A046") : Color(hex: "#EF1013")
    }

    private var continueButtonColor: Color {
        isCorrect ? Color(hex: "#97C171") : Color(hex: "#F46769")
    }

    private var overlayBackground: Color {
        isCorrect ? Color(hex: "#EAF3E3") : Color(hex: "#FFE0E1")
    }

    private var titleText: String {
        isCorrect ? "Amazing!" : "Not quite!"
    }

    @ViewBuilder
    var body: some View {
        #if os(macOS)
        macBanner
        #else
        iosSheet
        #endif
    }

    private var overlayContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.jakarta(size: 24, weight: .semibold))
                    Text(titleText)
                        .font(.jakarta(size: 24, weight: .semibold))
                }
                .foregroundColor(textAccent)

                Spacer()

                Button(action: { isBookmarked.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .font(.jakarta(size: 22, weight: .medium))
                        #if os(macOS)
                        Text("Save")
                            .font(.jakarta(size: 17, weight: .semibold))
                        #endif
                    }
                    .foregroundColor(textAccent)
                }
                .buttonStyle(.plain)
            }

            (Text("Answer: ").font(.jakarta(size: 17, weight: .semibold)) + Text(answerPhrase).font(.jakarta(size: 17, weight: .regular)))
                .foregroundColor(textAccent)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: onContinue) {
                Text("Continue")
                    .font(.jakarta(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(continueButtonColor)
                    .clipShape(RoundedRectangle(cornerRadius: 50, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.bottom, 20)
        }
    }

    private var iosSheet: some View {
        overlayContent
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .safeAreaPadding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .top)
        .background(alignment: .bottom) {
            overlayBackground
                .ignoresSafeArea(edges: .bottom)

            UnevenRoundedRectangle(
                cornerRadii: RectangleCornerRadii(
                    topLeading: 26,
                    bottomLeading: 0,
                    bottomTrailing: 0,
                    topTrailing: 26
                ),
                style: .continuous
            )
            .fill(overlayBackground)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    #if os(macOS)
    private var macBanner: some View {
        overlayContent
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 0)
            .frame(maxWidth: 760, alignment: .top)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(overlayBackground)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
    }
    #endif
}
