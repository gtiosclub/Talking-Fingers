//
//  AISentenceComprehensionView.swift
//  Talking Fingers
//
//  Created by Jagat Sachdeva on 2/23/26.
//

import SwiftUI

struct AISentenceComprehensionView: View {
    private let carouselImages = ["Image 1", "Image 2", "Image 3", "Image 4", "Image 5"]
    @State private var currentIndex = 0

    private var currentImage: String {
        carouselImages[currentIndex]
    }
    
    private var progress: CGFloat = 0.5

    private let words = ["word 1", "word 2", "word 3", "word 4", "word 5", "word 6", "word 7"]

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
            .padding(.vertical, 16)

            Spacer(minLength: 0)

            // 2. Middle: square + lines + word bank
            VStack(spacing: 12) {
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

                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(white: 0.92))
                    Text(currentImage)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .aspectRatio(1, contentMode: .fit)

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

            // Notebook-style lines container - equal spacing above each line
            VStack(spacing: 44) {
                HStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(height: 2)
                }
                HStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(height: 2)
                }
            }
            .padding(.vertical, 44)
            .padding(.horizontal)

            // Word bank - chips in a wrapping flow layout
            WrappingHStack(horizontalSpacing: 10, verticalSpacing: 10) {
                ForEach(words, id: \.self) { word in
                    Text(word)
                        .font(.subheadline)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .frame(minHeight: 44)
                        .background(Color(white: 0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
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
        }
        .padding()
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
