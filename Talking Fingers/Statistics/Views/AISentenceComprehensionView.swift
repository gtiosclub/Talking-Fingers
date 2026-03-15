//
//  AISentenceComprehensionView.swift
//  Talking Fingers
//
//  Created by Jagat Sachdeva on 2/23/26.
//

import SwiftUI

struct WordChip: Identifiable, Equatable {
    let id = UUID()
    let text: String
}

struct AISentenceComprehensionView: View {
    private let carouselImages = ["Image 1", "Image 2", "Image 3", "Image 4", "Image 5"]
    @State private var currentIndex = 0

    private var currentImage: String {
        carouselImages[currentIndex]
    }
    
    private var progress: CGFloat = 0.5

    /// Fixed order of all words; bank shows this order with shadows where words are on the line.
    @State private var allWordsInOrder: [WordChip] = [
        WordChip(text: "word 1"), WordChip(text: "word 2"), WordChip(text: "word 3"),
        WordChip(text: "word 4"), WordChip(text: "word 5"), WordChip(text: "word 6"),
        WordChip(text: "word 7")
    ]
    @State private var lineWords: [WordChip] = []

    private static let lineHorizontalSpacing: CGFloat = 10
    /// Vertical spacing between word rows; also drives notebook line positions so words sit on the lines.
    private static let lineVerticalSpacing: CGFloat = 18

    var body: some View {
        VStack(spacing: 0) {
            // 1. Top: progress bar container
            VStack(alignment: .leading, spacing: 20) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(white: 0.9))
                            .frame(height: 8)
                        Capsule()
                            .fill(Color(white: 0.5))
                            .frame(width: geo.size.width * min(max(progress, 0), 1), height: 8)
                    }
                }
                .frame(height: 4)

                Text("Translate!")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(Color(white: 0.3))
            }
            .padding(.horizontal)
            .padding(.top, 16)

            Spacer(minLength: 0)

            // 2. Middle: square + lines + word bank
            VStack(spacing: 40) {
                HStack(spacing: 16) {
                Button {
                    currentIndex = (currentIndex - 1 + carouselImages.count) % carouselImages.count
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title2.weight(.medium))
                        .foregroundStyle(.primary)
                        .frame(width: 44, height: 44)
                        .background(Color(white: 0.9))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                ZStack(alignment: .bottom) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(white: 0.92))
                        Text(currentImage)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .aspectRatio(1, contentMode: .fit)

                    HStack(spacing: 6) {
                        ForEach(carouselImages.indices, id: \.self) { index in
                            Circle()
                                .fill(index == currentIndex ? Color(white: 0.4) : Color(white: 0.85))
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(.bottom, 8)
                }

                Button {
                    currentIndex = (currentIndex + 1) % carouselImages.count
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title2.weight(.medium))
                        .foregroundStyle(.primary)
                        .frame(width: 44, height: 44)
                        .background(Color(white: 0.9))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            // Lines + word bank: same width as Check button (padded); content inside has no extra padding
            VStack(spacing: 32) {
                linesZoneView
                bankZoneView
            }
            .padding(.horizontal)
            }
            .frame(maxHeight: .infinity)

            Spacer(minLength: 0)

            // 3. Bottom: Check button
            Button("Check") { }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(white: 0.3))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .buttonStyle(.plain)
                .padding(.horizontal)
        }
        .padding()
    }

    // MARK: - Lines Zone

    /// Gap between the bottom of a word row and the notebook line below it.
    private static let lineToWordGap: CGFloat = 6
    /// Must match chip minHeight and WrappingHStack row height.
    private static let notebookRowHeight: CGFloat = 44
    private static var linesZoneHeight: CGFloat {
        let secondLineY = notebookRowHeight + Self.lineVerticalSpacing + notebookRowHeight - 1 + lineToWordGap
        return secondLineY + 4
    }

    private var linesZoneView: some View {
        ZStack(alignment: .topLeading) {
            notebookLinesView
            WrappingHStack(horizontalSpacing: Self.lineHorizontalSpacing, verticalSpacing: Self.lineVerticalSpacing) {
                ForEach(lineWords) { chip in
                    chipView(chip, onLine: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: Self.linesZoneHeight, maxHeight: Self.linesZoneHeight, alignment: .top)
        }
        .frame(height: Self.linesZoneHeight)
    }

    private var notebookLinesView: some View {
        let rowHeight = Self.notebookRowHeight
        let gap = Self.lineToWordGap
        // First line: just below first row of words (same as WrappingHStack row 0 bottom + gap).
        let firstLineY = rowHeight - 1 + gap
        // Second line: just below second row of words (row 0 + spacing + row 1 + gap).
        let secondLineY = rowHeight + Self.lineVerticalSpacing + rowHeight - 1 + gap
        return Color.clear
            .frame(height: Self.linesZoneHeight)
            .overlay(alignment: .topLeading) {
                Group {
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(height: 2)
                        .offset(y: firstLineY)
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(height: 2)
                        .offset(y: secondLineY)
                }
            }
    }

    // MARK: - Bank Zone

    private var bankZoneView: some View {
        WrappingHStack(horizontalSpacing: 10, verticalSpacing: 10) {
            ForEach(allWordsInOrder) { chip in
                if lineWords.contains(where: { $0.id == chip.id }) {
                    bankShadowView(for: chip)
                } else {
                    chipView(chip, onLine: false)
                }
            }
        }
    }

    /// Shadow placeholder in the bank: same size as the chip, darker, no text. Word stays in its slot when on the line.
    private func bankShadowView(for chip: WordChip) -> some View {
        Text(chip.text)
            .font(.subheadline)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .opacity(0)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(white: 0.4).opacity(0.5))
            )
    }

    // MARK: - Chip View

    private func chipView(_ chip: WordChip, onLine: Bool) -> some View {
        Text(chip.text)
            .font(.subheadline)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .background(Color(white: 0.9))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring()) {
                    if onLine {
                        lineWords.removeAll { $0.id == chip.id }
                    } else {
                        lineWords.append(chip)
                    }
                }
            }
    }
}

private struct WrappingHStack: Layout {
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
    AISentenceComprehensionView()
}
