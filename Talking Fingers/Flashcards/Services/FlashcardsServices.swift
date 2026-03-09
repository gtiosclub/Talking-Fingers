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

    func downloadFlashcards() async throws -> [FlashcardModel] {
        let snapshot = try await db.collection(collectionName).getDocuments()

        var flashcards: [FlashcardModel] = []
        for doc in snapshot.documents {
            let data = doc.data()
            guard let id = UUID(uuidString: data["id"] as? String ?? ""),
                  let term = data["term"] as? String,
                  let category = data["category"] as? String,
                  let starred = data["starred"] as? Bool,
                  let progressStr = data["progress"] as? String else {
                continue
            }

            let progress: ProgressType
            switch progressStr.lowercased() {
            case "new": progress = .new
            case "learning": progress = .learning
            case "polishing": progress = .polishing
            case "mastered": progress = .mastered
            default: progress = .new
            }

            let lastSucceeded = (data["lastSucceeded"] as? Timestamp)?.dateValue()

            let card = FlashcardModel(
                term: term,
                id: id,
                lastSucceeded: lastSucceeded,
                starred: starred,
                progress: progress,
                category: category
            )
            flashcards.append(card)
        }
        return flashcards
    }
}

