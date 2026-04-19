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
            var data: [String: Any] = [
                "id": card.id.uuidString,
                "term": card.term.rawValue,
                "category": card.category.rawValue,
                "starred": card.starred,
                "progress": String(describing: card.progress)
            ]
            data["lastSucceeded"] = card.lastSucceeded
            data["gifFileName"] = card.gifFileName ?? card.term.defaultGifFileName
            try await collectionRef.document(card.id.uuidString).setData(data)
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
                let termString = data["term"] as? String,
                let term = Term(rawValue: termString),
                let categoryString = data["category"] as? String,
                let category = TermCategory(rawValue: categoryString),
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
                category: category,
                gifFileName: data["gifFileName"] as? String
            )
            flashcards.append(card)
        }
        return flashcards
    }

    func downloadFlashcards() async throws -> [FlashcardModel] {
        let snapshot = try await db.collection(collectionName).getDocuments()

        var flashcards: [FlashcardModel] = []
        for doc in snapshot.documents {
            let data = doc.data()
            guard let id = UUID(uuidString: data["id"] as? String ?? ""),
                  let termString = data["term"] as? String,
                  let term = Term(rawValue: termString),
                  let categoryString = data["category"] as? String,
                  let category = TermCategory(rawValue: categoryString),
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
                category: category,
                gifFileName: data["gifFileName"] as? String
            )
            flashcards.append(card)
        }
        return flashcards
    }
}
