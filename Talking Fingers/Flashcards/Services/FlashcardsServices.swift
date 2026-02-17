//
//  FlashcardsServices.swift
//  Talking Fingers
//
//  Created by Na Hua on 2/12/26.
//
import Foundation
import FirebaseFirestore

enum FlashcardsServiceError: Error {
    case collectionNotFound
}

final class FlashcardsServices {

    private let db = Firestore.firestore()
    private let collectionName = "flashcards"

    func uploadFlashcards(_ flashcards: [FlashcardModel]) async throws {
        let collectionRef = db.collection(collectionName)

        for card in flashcards {
            try await collectionRef.document(card.id.uuidString).setData([
                "id": card.id.uuidString,
                "term": card.term,
                "category": card.category,
                "starred": card.starred,
                "progress": String(describing: card.progress),
                "lastSucceeded": card.lastSucceeded as Any
            ])
        }
    }
}

