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
    case decodingError
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
    
    func fetchFlashcards() async throws -> [FlashcardModel] {
        let collectionRef = db.collection(collectionName)

        let collection = try await collectionRef.getDocuments()

        guard !collection.documents.isEmpty else {
            throw FlashcardsServiceError.collectionNotFound
        }
        var flashcards: [FlashcardModel] = []

        for document in collection.documents {
            let data = document.data()

            guard
                let idString = data["id"] as? String,
                let id = UUID(uuidString: idString),
                let term = data["term"] as? String,
                let category = data["category"] as? String,
                let starred = data["starred"] as? Bool,
                let progress = data["progress"] as? ProgressType
            else {
                throw FlashcardsServiceError.decodingError
            }

            let lastSucceeded = data["lastSucceeded"] as? Timestamp
            let date = lastSucceeded?.dateValue()
            
            let card = FlashcardModel(
                term: term,
                id: id,
                lastSucceeded: date,
                starred: starred,
                progress: progress,
                category: category
            )
            flashcards.append(card)
        }
        return flashcards
    }
}

