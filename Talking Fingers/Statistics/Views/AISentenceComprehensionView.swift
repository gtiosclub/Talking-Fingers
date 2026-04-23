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
    @State private var solutionRevealed: Bool = false

    private var glossTerms: [Term] { sentenceModel.gloss }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Spacer(minLength: 0)

            // Sign images grid (placeholders)
            signImagesGrid

            // Status label row: "INCORRECT 1/2" or "CORRECT"
            statusLabelRow

            // Answer area — bordered box, border colour changes on submit
            answerArea

            // Word bank
            wordBankView

            Spacer(minLength: 0)

            // Bottom: solution (if 2nd incorrect) + buttons
            bottomArea
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 30)
        .onAppear { setupChips() }
    }

    // MARK: - Sign Images Grid

    private var signImagesGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6),
                            count: min(max(glossTerms.count, 1), 4))
        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(Array(glossTerms.enumerated()), id: \.offset) { _, term in
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(white: 0.93))
                    VStack(spacing: 2) {
                        Image(systemName: "person.fill")
                            .font(.jakarta(size: 24))
                            .foregroundColor(.gray.opacity(0.5))
                        Text(term.rawValue.lowercased())
                            .font(.jakarta(size: 9))
                            .foregroundColor(.gray.opacity(0.65))
                            .lineLimit(1)
                    }
                }
                .aspectRatio(1, contentMode: .fit)
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: - Status Label Row (INCORRECT / CORRECT)

    @ViewBuilder
    private var statusLabelRow: some View {
        switch submitState {
        case .incorrect:
            HStack {
                Text("INCORRECT")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                Spacer()
                Text("Attempt \(totalAttemptCount)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.red.opacity(0.7))
            }
        case .correct:
            HStack {
                Text("CORRECT")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.30, green: 0.69, blue: 0.31))
                Spacer()
            }
        case .idle:
            EmptyView()
        }
    }

    // MARK: - Answer Area (bordered box — red/green/gray border)

    private var answerArea: some View {
        VStack(alignment: .leading, spacing: 0) {
            CompWrappingHStack(horizontalSpacing: 8, verticalSpacing: 8) {
                ForEach(lineChips) { chip in
                    chipView(chip.text, background: answerChipBg)
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
        case .correct:   return Color(red: 0.30, green: 0.69, blue: 0.31)
        case .incorrect: return .red
        case .idle:      return Color.gray.opacity(0.35)
        }
    }

    private var answerChipBg: Color {
        switch submitState {
        case .correct:   return Color(red: 0.78, green: 0.93, blue: 0.78)
        case .incorrect: return Color(red: 0.96, green: 0.82, blue: 0.82)
        case .idle:      return Color(white: 0.91)
        }
    }

    // MARK: - Word Bank

    private var wordBankView: some View {
        CompWrappingHStack(horizontalSpacing: 8, verticalSpacing: 8) {
            ForEach(allChips) { chip in
                if lineChips.contains(where: { $0.id == chip.id }) {
                    // Shadow placeholder
                    Text(chip.text)
                        .font(.subheadline)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .opacity(0)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(minHeight: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(white: 0.55).opacity(0.45))
                        )
                } else {
                    chipView(chip.text, background: Color(white: 0.91))
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

    private func chipView(_ text: String, background: Color) -> some View {
        Text(text)
            .font(.subheadline)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(minHeight: 40)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Bottom Area

    @ViewBuilder
    private var bottomArea: some View {
        switch submitState {
        case .idle:
            let canSubmit = lineChips.count == correctOrder.count
            actionButton(
                title: "Submit",
                foreground: .white,
                background: Color(hex: "#97C171")
            ) { submit() }
            .opacity(canSubmit ? 1.0 : 0.5)
            .disabled(!canSubmit)

        case .incorrect:
            VStack(spacing: 10) {
                if solutionRevealed {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SOLUTION:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                        Text(correctOrder.joined(separator: " "))
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.05))
                    .cornerRadius(8)

                    actionButton(
                        title: "Continue",
                        foreground: .white,
                        background: Color(hex: "#97C171")
                    ) { onSentenceComplete?() }
                } else {
                    HStack(spacing: 16) {
                        actionButton(
                            title: "Reveal Solution",
                            foreground: Color(red: 0.34, green: 0.50, blue: 0.27),
                            background: Color(red: 0.92, green: 0.96, blue: 0.88)
                        ) { revealSolution() }

                        actionButton(
                            title: "Try again",
                            foreground: .white,
                            background: Color(red: 0.60, green: 0.76, blue: 0.44)
                        ) { tryAgain() }
                    }
                }
            }
            .frame(maxWidth: .infinity)

        case .correct:
            actionButton(
                title: "Continue",
                foreground: .white,
                background: Color(hex: "#97C171")
            ) { onSentenceComplete?() }
        }
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
        solutionRevealed = false
    }

    private func submit() {
        guard lineChips.count == correctOrder.count else { return }
        
        totalAttemptCount += 1
        let userAnswer = lineChips.map { $0.text }
        if userAnswer == correctOrder {
            sentenceModel.comprehensionAttempts = totalAttemptCount
            withAnimation { submitState = .correct }
        } else {
            withAnimation {
                solutionRevealed = false
                submitState = .incorrect
            }
        }
    }

    private func tryAgain() {
        withAnimation {
            lineChips = []
            submitState = .idle
        }
    }

    private func revealSolution() {
        // When revealing solution, count as one more attempt (they gave up)
        totalAttemptCount += 1
        sentenceModel.comprehensionAttempts = totalAttemptCount
        withAnimation {
            solutionRevealed = true
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
            var x = bounds.minX
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
