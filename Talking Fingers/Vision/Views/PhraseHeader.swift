import SwiftUI

struct PhraseHeader: View {

    let words: [String]
    let currentWordIndex: Int

    var body: some View {

        HStack(spacing: 6) {

            ForEach(words.indices, id: \.self) { index in

                Text(words[index])
                    .font(.headline)
                    .foregroundColor(
                        index == currentWordIndex
                        ? .primary
                        : .gray
                    )
            }
        }
    }
}