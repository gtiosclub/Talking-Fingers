import SwiftUI

struct SentenceCompletionOverlay: View {
    let averageScore: Double
    @Binding var isFavorited: Bool
    var onContinue: () -> Void

    private var roundedScore: Int { Int(averageScore.rounded()) }

    private enum CompletionTier {
        case high
        case medium
        case low

        init(score: Int) {
            if score >= 75 {
                self = .high
            } else if score >= 50 {
                self = .medium
            } else {
                self = .low
            }
        }

        var textAccent: Color {
            switch self {
            case .high: return Color(hex: "#71A046")
            case .medium: return Color(hex: "#ECA509")
            case .low: return Color(hex: "#EF1013")
            }
        }

        var buttonAndGloss: Color {
            switch self {
            case .high: return Color(hex: "#97C171")
            case .medium: return Color(hex: "#ECA509")
            case .low: return Color(hex: "#F46769")
            }
        }

        var background: Color {
            switch self {
            case .high: return Color(hex: "#EAF3E3")
            case .medium: return Color(hex: "#FEF7E7")
            case .low: return Color(hex: "#FFE0E1")
            }
        }

        var title: String {
            switch self {
            case .high: return "Amazing!"
            case .medium: return "Almost!"
            case .low: return "Not Quite!"
            }
        }
    }

    /// Continue button and live gloss row only (separate from overlay copy color).
    static func glossAndButtonColor(for averageScore: Double) -> Color {
        CompletionTier(score: Int(averageScore.rounded())).buttonAndGloss
    }

    private var tier: CompletionTier { CompletionTier(score: roundedScore) }

    private var textAccent: Color { tier.textAccent }
    private var continueButtonColor: Color { tier.buttonAndGloss }
    private var overlayBackground: Color { tier.background }
    private var titleText: String { tier.title }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Image(systemName: roundedScore >= 75 ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.jakarta(size: 24, weight: .semibold))
                    Text(titleText)
                        .font(.jakarta(size: 24, weight: .semibold))
                }
                .foregroundColor(textAccent)

                Spacer()

                Button(action: { isFavorited.toggle() }) {
                    Image(systemName: isFavorited ? "bookmark.fill" : "bookmark")
                        .font(.jakarta(size: 22, weight: .medium))
                        .foregroundColor(textAccent)
                }
                .buttonStyle(.plain)
            }

            Text("Accuracy: \(roundedScore)%")
                .font(.jakarta(size: 17, weight: .regular))
                .foregroundColor(textAccent)

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
        .padding(.horizontal, 16)
        .padding(.top, 16)
        // Inset content from the home indicator; the fill extends under it (see below).
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
}
