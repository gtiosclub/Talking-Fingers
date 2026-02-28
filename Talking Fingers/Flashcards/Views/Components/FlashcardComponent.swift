//
//  FlashcardComponent.swift
//  Talking Fingers
//
//  Created by Isha Jain on 1/29/26.
//

import SwiftUI

struct FlashcardComponent: View {
    var card: FlashcardModel

    @StateObject private var sentenceVM: SentenceBuilderVM
    
    init(card: FlashcardModel) {
            self.card = card

            // replace this with the real exercise for this card
            let ex = SentenceExerciseModel(
                prompt: "Arrange the sentence",
                correctOrder: ["today", "was", "amazing"],
                wordBank: ["today", "was", "amazing", "thank", "you"]
            )

            _sentenceVM = StateObject(wrappedValue: SentenceBuilderVM(exercise: ex))
    }

    var body: some View {
        VStack {

            universalImage(baseName: card.id.uuidString, ext: "png", height: 250)

            SentenceBuilderView(vm: sentenceVM)
        }
        .padding()
    }
}

#Preview {
    FlashcardComponent(
        card: FlashcardModel(
            term: "Apple",
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            category: "Test"
        )
    )
}
