//
//  AISentenceComprehensionView.swift
//  Talking Fingers
//
//  Created by Jagat Sachdeva on 2/23/26.
//

import SwiftUI

struct AISentenceComprehensionView: View {
    @Binding var sentenceModel: AISentenceModel
    var onSentenceComplete: (() -> Void)? = nil

    private var correctOrder: [String] {
        sentenceModel.gloss.map { $0.rawValue.lowercased() }
    }

    @State private var allChips: [CompWordChip] = []
    @State private var lineChips: [CompWordChip] = []
    @State private var submitState: CompSubmitState = .idle
    @State private var totalAttemptCount: Int = 0
    @State private var isResultBookmarked: Bool = false
    @State private var macCarouselIndex: Int = 0
    #if os(macOS)
    @FocusState private var isMacCarouselFocused: Bool
    #endif

    private let chipTextColor = Color(hex: "#464646")
    private let chipBorderColor = Color(hex: "#F0F0F0")
    private let chipPlaceholderColor = Color(hex: "#FDF2D8")

    private var glossTerms: [Term] { sentenceModel.gloss }

    private var canSubmitAnswer: Bool { lineChips.count == correctOrder.count }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 14) {
                Spacer(minLength: 0)

                signImagesGrid

                answerArea

                wordBankView

                Spacer(minLength: 0)

                if submitState == .idle {
                    actionButton(
                        title: "Submit",
                        foreground: .white,
                        background: Color(hex: "#97C171")
                    ) { submit() }
                    .opacity(canSubmitAnswer ? 1.0 : 0.5)
                    .disabled(!canSubmitAnswer)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
            .allowsHitTesting(submitState == .idle)

            if submitState != .idle {
                ComprehensionAnswerFeedbackOverlay(
                    isCorrect: submitState == .correct,
                    answerPhrase: correctOrder.joined(separator: " "),
                    isBookmarked: $isResultBookmarked,
                    onContinue: { onSentenceComplete?() }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: submitState)
        .onAppear { setupChips() }
        #if os(macOS)
        .focusable()
        .focused($isMacCarouselFocused)
        .focusEffectDisabled()
        .onAppear { isMacCarouselFocused = true }
        .onMoveCommand { direction in
            switch direction {
            case .left:
                moveMacCarousel(by: -1)
            case .right:
                moveMacCarousel(by: 1)
            default:
                break
            }
        }
        #endif
    }

    // MARK: - Sign Images Grid

    private var signImagesGrid: some View {
#if os(macOS)
        VStack(spacing: 10) {
            if !glossTerms.isEmpty {
                signPlaceholderCard(for: glossTerms[clampedMacCarouselIndex])
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .frame(height: 300)
            }

            HStack(spacing: 10) {
                Button {
                    moveMacCarousel(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.jakarta(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color(hex: "#97C171"))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(clampedMacCarouselIndex == 0)
                .opacity(clampedMacCarouselIndex == 0 ? 0.4 : 1)

                HStack(spacing: 6) {
                    ForEach(Array(glossTerms.enumerated()), id: \.offset) { index, _ in
                        Circle()
                            .fill(index == clampedMacCarouselIndex ? Color(hex: "#97C171") : Color.gray.opacity(0.3))
                            .frame(width: 7, height: 7)
                    }
                }

                Button {
                    moveMacCarousel(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.jakarta(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color(hex: "#97C171"))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(clampedMacCarouselIndex == max(glossTerms.count - 1, 0))
                .opacity(clampedMacCarouselIndex == max(glossTerms.count - 1, 0) ? 0.4 : 1)
            }
        }
        .padding(.bottom, 4)
#else
        TabView {
            ForEach(Array(glossTerms.enumerated()), id: \.offset) { _, term in
                signPlaceholderCard(for: term)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 6)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .frame(height: 180)
        .padding(.bottom, 4)
#endif
    }

    private var clampedMacCarouselIndex: Int {
        guard !glossTerms.isEmpty else { return 0 }
        return min(max(0, macCarouselIndex), glossTerms.count - 1)
    }

    private func moveMacCarousel(by offset: Int) {
        guard !glossTerms.isEmpty else { return }
        let nextIndex = clampedMacCarouselIndex + offset
        macCarouselIndex = min(max(0, nextIndex), glossTerms.count - 1)
    }
    
    private func signPlaceholderCard(for term: Term) -> some View {
#if os(macOS)
        Group {
            if let gifFileName = term.defaultGifFileName {
                GIFView(gifFileName: gifFileName)
                    .id(gifFileName)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 2) {
                    Image(systemName: "person.fill")
                        .font(.jakarta(size: 24))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("No GIF")
                        .font(.jakarta(size: 9))
                        .foregroundColor(.gray.opacity(0.65))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
#else
        VStack(spacing: 4) {
            Group {
                if let gifFileName = term.defaultGifFileName {
                    GIFView(gifFileName: gifFileName)
                        .id(gifFileName)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 2) {
                        Image(systemName: "person.fill")
                            .font(.jakarta(size: 24))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No GIF")
                            .font(.jakarta(size: 9))
                            .foregroundColor(.gray.opacity(0.65))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Text(term.rawValue.lowercased())
                .font(.jakarta(size: 9))
                .foregroundColor(.gray.opacity(0.65))
                .lineLimit(1)
        }
        .padding(6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.93))
        .clipShape(RoundedRectangle(cornerRadius: 8))
#endif
    }

    // MARK: - Answer Area (bordered box — red/green/gray border)

    private var answerArea: some View {
        VStack(alignment: .leading, spacing: 0) {
            CompWrappingHStack(horizontalSpacing: 10, verticalSpacing: 10) {
                ForEach(lineChips) { chip in
                    chipView(
                        chip.text,
                        background: .white,
                        borderColor: answerChipBorderColor,
                        foregroundColor: answerChipForegroundColor
                    )
                    .onTapGesture {
                        guard submitState == .idle else { return }
                        withAnimation(.spring()) {
                            lineChips.removeAll { $0.id == chip.id }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 52)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(answerBorderColor, lineWidth: submitState == .idle ? 1 : 2)
        )
    }

    private var answerBorderColor: Color {
        switch submitState {
        case .correct:
            return Color(hex: "#EAF3E3")
        case .incorrect:
            return Color(hex: "#FFE0E1")
        case .idle:
            return Color.gray.opacity(0.35)
        }
    }

    private var answerChipBorderColor: Color {
        switch submitState {
        case .idle:
            return chipBorderColor
        case .correct:
            return Color(hex: "#689F38")
        case .incorrect:
            return Color(hex: "#E53935")
        }
    }

    private var answerChipForegroundColor: Color {
        submitState == .idle ? chipTextColor : answerChipBorderColor
    }

    // MARK: - Word Bank

    private var wordBankView: some View {
        CompWrappingHStack(horizontalSpacing: 10, verticalSpacing: 10, horizontalAlignment: .center) {
            ForEach(allChips) { chip in
                if lineChips.contains(where: { $0.id == chip.id }) {
                    // Shadow placeholder
                    Text(chip.text)
                        .font(.jakarta(size: 17))
                        .foregroundColor(chipTextColor)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .opacity(0)
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                        .padding(.bottom, 10)
                        .frame(minHeight: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(chipPlaceholderColor)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(chipBorderColor, lineWidth: 1.5)
                        )
                } else {
                    chipView(chip.text, background: .white, borderColor: chipBorderColor, foregroundColor: chipTextColor)
                        .onTapGesture {
                            guard submitState == .idle else { return }
                            withAnimation(.spring()) {
                                lineChips.append(chip)
                            }
                        }
                }
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Chip

    private func chipView(
        _ text: String,
        background: Color,
        borderColor: Color,
        foregroundColor: Color
    ) -> some View {
        Text(text)
            .font(.jakarta(size: 17))
            .foregroundColor(foregroundColor)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 10)
            .frame(minHeight: 40)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 1.5)
            )
    }

    // MARK: - Logic

    private func setupChips() {
        let correctSet = Set(correctOrder)
        let allTermStrings = Term.allCases.map { $0.rawValue.lowercased() }
        let possibleDistractors = allTermStrings.filter { !correctSet.contains($0) }
        let numDistractors = max(0, 7 - correctOrder.count)
        let distractors = Array(possibleDistractors.shuffled().prefix(numDistractors))

        let allWords = (correctOrder + distractors).shuffled()
        allChips = allWords.map { CompWordChip(text: $0) }
        lineChips = []
        submitState = .idle
        totalAttemptCount = 0
        isResultBookmarked = false
        macCarouselIndex = 0
    }

    private func submit() {
        guard lineChips.count == correctOrder.count else { return }

        totalAttemptCount += 1
        let userAnswer = lineChips.map { $0.text }
        let isCorrect = userAnswer == correctOrder
        sentenceModel.comprehensionAttempts = totalAttemptCount
        sentenceModel.comprehensionWasCorrect = isCorrect
        if isCorrect {
            withAnimation { submitState = .correct }
        } else {
            withAnimation { submitState = .incorrect }
        }
    }

    private func actionButton(
        title: String,
        foreground: Color,
        background: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(foreground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(background)
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Supporting Types

private enum CompSubmitState: Equatable {
    case idle
    case correct
    case incorrect
}

private struct CompWordChip: Identifiable, Equatable {
    let id = UUID()
    let text: String
}

// MARK: - Wrapping HStack Layout

private struct CompWrappingHStack: Layout {
    var horizontalSpacing: CGFloat
    var verticalSpacing: CGFloat
    var horizontalAlignment: HorizontalAlignment = .leading

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var height: CGFloat = 0
        for (i, row) in rows.enumerated() {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            height += rowHeight
            if i > 0 { height += verticalSpacing }
        }
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for (i, row) in rows.enumerated() {
            if i > 0 { y += verticalSpacing }
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            var x = startX(for: row, in: bounds)
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + horizontalSpacing
            }
            y += rowHeight
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubviews.Element]] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[LayoutSubviews.Element]] = [[]]
        var currentRowWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentRowWidth + size.width > maxWidth && !rows[rows.count - 1].isEmpty {
                rows.append([])
                currentRowWidth = 0
            }
            rows[rows.count - 1].append(subview)
            currentRowWidth += size.width + horizontalSpacing
        }
        return rows
    }

    private func startX(for row: [LayoutSubviews.Element], in bounds: CGRect) -> CGFloat {
        let rowWidth = width(for: row)
        switch horizontalAlignment {
        case .center:
            return bounds.minX + max(0, (bounds.width - rowWidth) / 2)
        case .trailing:
            return bounds.maxX - rowWidth
        default:
            return bounds.minX
        }
    }

    private func width(for row: [LayoutSubviews.Element]) -> CGFloat {
        guard !row.isEmpty else { return 0 }
        let contentWidth = row.reduce(CGFloat.zero) { partialResult, subview in
            partialResult + subview.sizeThatFits(.unspecified).width
        }
        return contentWidth + CGFloat(row.count - 1) * horizontalSpacing
    }
}

#Preview {
    @Previewable @State var sampleModel = AISentenceModel(
        sentence: "Today was good, thank you.",
        practiceType: .comprehension,
        gloss: [.today, .good, .happy, .you]
    )
    
    AISentenceComprehensionView(
        sentenceModel: $sampleModel
    )
}
