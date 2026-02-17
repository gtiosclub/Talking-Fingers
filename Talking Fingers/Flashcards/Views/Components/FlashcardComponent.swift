//
//  FlashcardComponent.swift
//  Talking Fingers
//
//  Created by Isha Jain on 1/29/26.
//

import SwiftUI

struct FlashcardComponent: View {
    var card: FlashcardModel
    var body: some View {
        VStack{
            Text(card.term)
            if let image = UIImage(named: card.id.uuidString) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 250)
            }
        }
        Text("this is a flashcard component")
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

