//
//  FlashcardView.swift
//  Talking Fingers
//
//  Created by Isha Jain on 1/29/26.
//

import SwiftUI

struct FlashcardView: View {

    @State private var vm = FlashcardVM()

    var body: some View {
        VStack {
            if let card = vm.flashcards.first {
                FlashcardComponent(card: card)
            }
        }
        .padding()
    }
}

#Preview {
    FlashcardView()
}
