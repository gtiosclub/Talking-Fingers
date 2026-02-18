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
