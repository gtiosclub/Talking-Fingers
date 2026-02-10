//
//  FlashcardVM.swift
//  Talking Fingers
//
//  Created by Isha Jain on 2/9/26.
//

import Foundation
import Combine

@Observable
class FlashcardVM {

    var flashcards: [FlashcardModel] = []
    func filterByCategory(from flashcards: [FlashcardModel], category: String) -> [FlashcardModel] {
        flashcards.filter { $0.category == category }
    }
}
