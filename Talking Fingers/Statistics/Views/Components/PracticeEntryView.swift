import SwiftUI

struct PracticeEntryView: View {
    var practiceTitle: String
    var remainingSentenceCount: Int
    var categories: [TermCategory]
    var flowerAssetName: String

    private let chipTextColor = Color(hex: "#ECA509")

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 20)

            Text(practiceTitle)
                .font(.system(size: 40, weight: .semibold))
                .foregroundColor(Color(hex: "#464646"))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Text("\(remainingSentenceCount) sentence\(remainingSentenceCount == 1 ? "" : "s") to go!")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(hex: "#464646"))
                .padding(.top, 10)

            if !categories.isEmpty {
                FlowLayout(verticalSpacing: 8, horizontalSpacing: 8) {
                    ForEach(categories, id: \.self) { category in
                        categoryChip(category)
                    }
                }
                .padding(.top, 20)
            }

            Spacer(minLength: 20)

            Image(flowerAssetName)
                .resizable()
                .scaledToFit()
                .frame(width: 240, height: 300)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }

    private func categoryChip(_ category: TermCategory) -> some View {
        HStack(spacing: 3) {
            Image(systemName: symbolName(for: category))
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(Color(hex: "#ECA509"))
            Text(category.displayName)
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(Color(hex: "#ECA509"))
        }
        .foregroundColor(chipTextColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(hex: "#FEF7E7"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color(hex: "#F8BC3A"), lineWidth: 0.5)
        )
    }

    private func symbolName(for category: TermCategory) -> String {
        switch category {
        case .alphabet:
            return "character.book.closed"
        case .numbers:
            return "number"
        case .greetings:
            return "hand.wave"
        case .personalInformation:
            return "person.text.rectangle"
        case .family:
            return "person.2"
        case .verbs:
            return "bolt"
        case .dateTime:
            return "clock"
        case .feelingsEmotions:
            return "face.smiling"
        case .locations:
            return "mappin.and.ellipse"
        case .commonDescriptors:
            return "tag"
        case .commonObjects:
            return "shippingbox"
        }
    }
}
