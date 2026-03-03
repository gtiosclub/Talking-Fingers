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
    var flashcards: [FlashcardModel] = FlashcardVM.dummyFlashcards
    var lastCardID: UUID?

    static let dummyFlashcards: [FlashcardModel] = {
        let calendar = Calendar.current
        let now = Date()

        func daysAgo(_ days: Int) -> Date {
            calendar.date(byAdding: .day, value: -days, to: now)!
        }

        return [
            FlashcardModel(term: "Hello", id: UUID(), lastSucceeded: nil,starred: false, progress: .new, category: "Greetings"),
            FlashcardModel(term: "Goodbye", id: UUID(), lastSucceeded: daysAgo(10), starred: false, progress: .learning,  category: "Greetings"),
            FlashcardModel(term: "Thank You", id: UUID(), lastSucceeded: daysAgo(3),starred: true,  progress: .learning, category: "Greetings"),
            FlashcardModel(term: "Please", id: UUID(), lastSucceeded: daysAgo(1),starred: false, progress: .polishing, category: "Greetings"),

            FlashcardModel(term: "One", id: UUID(), lastSucceeded: daysAgo(8), starred: false, progress: .learning,  category: "Numbers"),
            FlashcardModel(term: "Two", id: UUID(), lastSucceeded: daysAgo(2), starred: false, progress: .polishing, category: "Numbers"),
            FlashcardModel(term: "Three", id: UUID(), lastSucceeded: daysAgo(5),starred: true,  progress: .polishing, category: "Numbers"),
            FlashcardModel(term: "Four", id: UUID(), lastSucceeded: daysAgo(1),starred: false, progress: .mastered,  category: "Numbers"),

            FlashcardModel(term: "Red", id: UUID(), lastSucceeded: daysAgo(1), starred: false, progress: .mastered,  category: "Colors"),
            FlashcardModel(term: "Blue", id: UUID(), lastSucceeded: daysAgo(2), starred: false, progress: .mastered, category: "Colors"),
            FlashcardModel(term: "Green", id: UUID(), lastSucceeded: daysAgo(3),starred: true,  progress: .polishing, category: "Colors"),
            FlashcardModel(term: "Yellow", id: UUID(), lastSucceeded: daysAgo(1),starred: false, progress: .mastered,  category: "Colors"),
        ]
    }()
    
    init() {
        let dummyID = UUID(uuidString: "GifDiagramTest") ?? UUID() // change to static diagram test to test static diagram
        let dummyCard = FlashcardModel(
            term: "Test",
            id: dummyID,
            category: "Test",
            gifFileName: "a34a6e11-0fa6-4b52-abad-0454bd74ea5a.gif"
        )
        self.flashcards = [dummyCard]
    }
    
    func searchFlashCard(input: String) -> [String] {
        var results = [String]()
        for card in flashcards {
            if card.term.lowercased().contains(input.lowercased()) {
                results.append(card.term)
            }
        }
        return results
    }
    
    func filterByCategory(from flashcards: [FlashcardModel], category: String) -> [FlashcardModel] {
        flashcards.filter { $0.category == category }
    }
    
    func filterStarred(from flashcards: [FlashcardModel]) -> [FlashcardModel] {
        flashcards.filter { $0.starred }
    }
   
    func returnProgress(flashcards: [FlashcardModel]) -> Float {
        guard !flashcards.isEmpty else { return 0.0 }
        var progressTotal: Float = 0.0

        for flashcard in flashcards {
            switch flashcard.progress {
            case .new:
                progressTotal += 0
            case .learning:
                progressTotal += 40
            case .polishing:
                progressTotal += 70
            case .mastered:
                progressTotal += 100
            }
        }
        return progressTotal / Float(flashcards.count)
    }
    
    func updateStatus(for card: FlashcardModel, to newProgress: ProgressType) -> FlashcardModel {
        card.progress = newProgress
        return card
    }
    
    func handleAnswer(for card: FlashcardModel, correct: Bool) {
        let newProgress: ProgressType

        switch (card.progress, correct) {
        case (.new, true):
            newProgress = .learning
        case (.learning, true):
            newProgress = .polishing
        case (.polishing, true):
            newProgress = .mastered
        case (.mastered, true):
            newProgress = .mastered
        case (.mastered, false):
            newProgress = .polishing
        case (.polishing, false):
            newProgress = .learning
        case (.learning, false):
            newProgress = .learning
        case (.new, false):
            newProgress = .new
        }

        let updatedCard = updateStatus(for: card, to: newProgress)
        if correct {
            updatedCard.lastSucceeded = Date()
        }
    }
    
    func nextCard() -> FlashcardModel? {
        guard !flashcards.isEmpty else { return nil }
        
        // return a weight to help determine probability of card appearing
        func weight(for card: FlashcardModel) -> Int {
            switch card.progress {
            case .new:
                return 5
            case .learning:
                return 4
            case .polishing:
                return 2
            case .mastered:
                return 1
            }
        }
        
        // if flashcards array is: [A (weight 4), B (weight 1), C (weight 2)]
        // -> returns flattened array repeating card weight # times: [A, A, A, A, B, C, C]
        let weightedCards = flashcards.flatMap { card -> [FlashcardModel] in
            let weight = weight(for: card)
            return Array(repeating: card, count: weight)
        }
        
        // to not repeat same card twice in a row, create new array that removes most recent card
        let filtered = weightedCards.filter { $0.id != lastCardID }
        let chosenCard = (filtered.isEmpty ? weightedCards : filtered).randomElement()
        lastCardID = chosenCard?.id
        return chosenCard
    }
        
        // possible additions: should it end, if so when;
        // maybe we can have a queue of recently missed cards and prioritize those first;
        // implementing time-spaced spacing with lastSucceeded

    func generateDailyReviewQueue(limit: Int = 5) -> DailyReviewQueue {
        let sorted = flashcards.sorted { a, b in
            if a.progress != b.progress {
                return progressRank(a) < progressRank(b)
            }
            return (a.lastSucceeded ?? .distantPast) < (b.lastSucceeded ?? .distantPast)
        }

        let topCards = Array(sorted.prefix(limit))
        return DailyReviewQueue(cards: topCards, requestedLimit: limit, totalCardCount: flashcards.count)
    }

    private func progressRank(_ card: FlashcardModel) -> Int {
        switch card.progress {
        case .new:       return 0
        case .learning:  return 1
        case .polishing: return 2
        case .mastered:  return 3
        }
    }
}
