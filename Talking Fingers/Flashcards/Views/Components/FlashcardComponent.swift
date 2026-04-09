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
        
        let dummySentence = AISentenceModel(
            sentence: "I like eating \(card.term.rawValue)",
            practiceType: .signs,
            gloss: [card.term],
            completed: false
        )
        
        let ex = SentenceExerciseModel(
            sentence: dummySentence,
            correctOrder: ["I", "like", "eating", card.term.rawValue],
            distractors: ["thank", "you"]
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
            term: .food,
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            category: .commonObjects
        )
    )
}
