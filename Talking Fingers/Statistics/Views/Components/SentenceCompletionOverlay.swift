import SwiftUI

struct SentenceCompletionOverlay: View {
    let averageScore: Double
    @Binding var isFavorited: Bool
    var onContinue: () -> Void

    private var roundedScore: Int { Int(averageScore.rounded()) }

    /// Title, accuracy line, and bookmark: original overlay text accents.
    private static func textAccentColor(for averageScore: Double) -> Color {
        let s = Int(averageScore.rounded())
        if s >= 80 { return Color(hex: "#71A046") }
        if s >= 60 { return Color(hex: "#ECA509") }
        return Color(hex: "#EF1013")
    }

    /// Continue button and live gloss row only (separate from overlay copy color).
    static func glossAndButtonColor(for averageScore: Double) -> Color {
        let s = Int(averageScore.rounded())
        if s >= 75 { return Color(hex: "#97C171") }
        if s >= 50 { return Color(hex: "#ECA509") }
        return Color(hex: "#F46769")
    }

    private var titleText: String {
        if roundedScore >= 75 { return "Amazing!" }
        if roundedScore >= 50 { return "Almost!" }
        return "Not Quite!"
    }

    private var overlayBackground: Color {
        if roundedScore >= 75 { return Color(hex: "#EAF3E3") }
        if roundedScore >= 50 { return Color(hex: "#FEF7E7") }
        return Color(hex: "#FFE0E1")
    }

    private var textAccent: Color { Self.textAccentColor(for: averageScore) }
    private var continueButtonColor: Color { Self.glossAndButtonColor(for: averageScore) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Image(systemName: roundedScore >= 75 ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 24, weight: .semibold))
                    Text(titleText)
                        .font(.system(size: 24, weight: .semibold))
                }
                .foregroundColor(textAccent)

                Spacer()

                Button(action: { isFavorited.toggle() }) {
                    Image(systemName: isFavorited ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(textAccent)
                }
                .buttonStyle(.plain)
            }

            Text("Accuracy: \(roundedScore)%")
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(textAccent)

            Button(action: onContinue) {
                Text("Continue")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(continueButtonColor)
                    .clipShape(RoundedRectangle(cornerRadius: 50, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        // Inset content from the home indicator; the fill extends under it (see below).
        .safeAreaPadding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .top)
        .background {
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
}
