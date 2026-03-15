//
//  MultipleChoiceVM.swift
//  Talking Fingers
//

import SwiftUI

enum ImageMode: String, CaseIterable {
    case both = "Both"
    case camera = "Camera"
    case flashcard = "Flashcards"
}

@Observable
class MultipleChoiceVM {
    private let deck: [FlashcardModel]
    private let allFlashcards: [FlashcardModel]
    private var deckIndex: Int = 0

    private(set) var card: FlashcardModel
    var choices: [String] = []
    var selectedAnswer: String? = nil
    var hasSubmitted: Bool = false
    var showHint: Bool = false
    var showResult: Bool = false
    var imageMode: ImageMode = .both
    var sessionComplete: Bool = false

    var isCorrect: Bool {
        selectedAnswer == card.term
    }

    /// Fraction of the deck completed (0.0 → 1.0) for the progress bar.
    var deckProgress: Double {
        Double(deckIndex) / Double(max(deck.count, 1))
    }

    init(deck: [FlashcardModel], allFlashcards: [FlashcardModel]) {
        let shuffledDeck = deck.isEmpty ? allFlashcards.shuffled() : deck.shuffled()
        self.deck = shuffledDeck
        self.allFlashcards = allFlashcards
        let firstCard = shuffledDeck.first ?? allFlashcards[0]
        self.card = firstCard
        self.choices = Self.generateChoices(for: firstCard, from: allFlashcards)
    }

    func selectAnswer(_ answer: String) {
        guard !hasSubmitted else { return }
        selectedAnswer = answer
    }

    func submit() {
        guard selectedAnswer != nil else { return }
        hasSubmitted = true
        showResult = true
    }

    func nextCard() {
        deckIndex += 1
        if deckIndex >= deck.count {
            sessionComplete = true
            return
        }
        card = deck[deckIndex]
        selectedAnswer = nil
        hasSubmitted = false
        showHint = false
        showResult = false
        choices = Self.generateChoices(for: card, from: allFlashcards)
    }

    // MARK: - Distractor Generation

    private static func generateChoices(for card: FlashcardModel, from allFlashcards: [FlashcardModel]) -> [String] {
        let correctTerm = card.term
        var distractors: [String] = []

        // 1. Prefer distractors from the same Term category (hardest to distinguish)
        if let term = Term.from(correctTerm) {
            let sameCategory = Term.words(for: term.category)
                .map(\.rawValue)
                .filter { $0 != correctTerm }
                .shuffled()
            distractors.append(contentsOf: sameCategory.prefix(3))
        }

        // 2. Pad from other cards in the current session deck
        if distractors.count < 3 {
            let fromCards = allFlashcards
                .map(\.term)
                .filter { $0 != correctTerm && !distractors.contains($0) }
                .shuffled()
            distractors.append(contentsOf: fromCards.prefix(3 - distractors.count))
        }

        // 3. Final fallback: pull from the full Term vocabulary
        if distractors.count < 3 {
            let allTerms = Term.allCases
                .map(\.rawValue)
                .filter { $0 != correctTerm && !distractors.contains($0) }
                .shuffled()
            distractors.append(contentsOf: allTerms.prefix(3 - distractors.count))
        }

        var choices = Array(distractors.prefix(3))
        choices.append(correctTerm)
        return choices.shuffled()
    }
}
