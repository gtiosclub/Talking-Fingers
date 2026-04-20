//
//  FlashcardVM.swift
//  Talking Fingers
//
//  Created by Isha Jain on 2/9/26.
//
import Foundation
import Combine
import SwiftData

@Observable
class FlashcardVM {
    var flashcards: [FlashcardModel] = []
    var isLoading = false
    var isSyncing = false
    private let firebaseService = FlashcardsServices()
    var fakeFlashcards: [FlashcardModel] = FlashcardVM.dummyFlashcards
    var lastCardID: UUID?

    static let dummyFlashcards: [FlashcardModel] = {
        let calendar = Calendar.current
        let now = Date()

        func daysAgo(_ days: Int) -> Date {
            calendar.date(byAdding: .day, value: -days, to: now)!
        }

        return [
            FlashcardModel(term: .hello, id: UUID(), lastSucceeded: nil, starred: false, progress: .new, category: .greetings, gifFileName: Term.hello.defaultGifFileName),
            FlashcardModel(term: .a, id: UUID(), lastSucceeded: nil, starred: false, progress: .new, category: .greetings),
            FlashcardModel(term: .bye, id: UUID(), lastSucceeded: daysAgo(10), starred: false, progress: .learning, category: .greetings),
            FlashcardModel(term: .niceMeetYou, id: UUID(), lastSucceeded: daysAgo(3), starred: true, progress: .learning, category: .greetings),
            FlashcardModel(term: .howYou, id: UUID(), lastSucceeded: daysAgo(1), starred: false, progress: .polishing, category: .greetings),

            FlashcardModel(term: .one, id: UUID(), lastSucceeded: daysAgo(8), starred: false, progress: .learning, category: .numbers),
            FlashcardModel(term: .zero, id: UUID(), lastSucceeded: nil, starred: false, progress: .new, category: .numbers),
            FlashcardModel(term: .two, id: UUID(), lastSucceeded: daysAgo(2), starred: false, progress: .polishing, category: .numbers),
            FlashcardModel(term: .three, id: UUID(), lastSucceeded: daysAgo(5), starred: true, progress: .polishing, category: .numbers),
            FlashcardModel(term: .four, id: UUID(), lastSucceeded: daysAgo(1), starred: false, progress: .mastered, category: .numbers),

            FlashcardModel(term: .good, id: UUID(), lastSucceeded: daysAgo(1), starred: false, progress: .mastered, category: .commonDescriptors),
            FlashcardModel(term: .happy, id: UUID(), lastSucceeded: daysAgo(2), starred: false, progress: .mastered, category: .feelingsEmotions),
            FlashcardModel(term: .sad, id: UUID(), lastSucceeded: daysAgo(3), starred: true, progress: .polishing, category: .feelingsEmotions),
            FlashcardModel(term: .excited, id: UUID(), lastSucceeded: daysAgo(1), starred: false, progress: .mastered, category: .feelingsEmotions),
        ]
    }()
    
    init() {
        let dummyID = UUID(uuidString: "GifDiagramTest") ?? UUID() // change to static diagram test to test static diagram
        let dummyCard = FlashcardModel(
            term: .hello,
            id: dummyID,
            category: .commonObjects,
            gifFileName: "a34a6e11-0fa6-4b52-abad-0454bd74ea5a.gif"
        )
        self.flashcards = [dummyCard]
    }
    
    func searchFlashCard(input: String) -> [String] {
        var results = [String]()
        for card in flashcards {
            if card.term.rawValue.lowercased().contains(input.lowercased()) {
                results.append(card.term.rawValue)
            }
        }   
        return results
    }
    
    func filterByCategory(from flashcards: [FlashcardModel], category: TermCategory) -> [FlashcardModel] {
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

    
    func loadFlashcards(modelContext: ModelContext) async {
        
        isLoading = true
        flashcards = fetchFromSwiftData(modelContext)
        isLoading = false
        isSyncing = true
        Task {
            do {
                let remoteCards = try await firebaseService.downloadFlashcards()
                await saveToSwiftData(remoteCards, modelContext: modelContext)
                flashcards = fetchFromSwiftData(modelContext)
            } catch {
                print("Firebase sync failed: \(error)")
            }
            isSyncing = false
        }
    }

    private func fetchFromSwiftData(_ modelContext: ModelContext) -> [FlashcardModel] {
        let descriptor = FetchDescriptor<FlashcardModel>()
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func saveToSwiftData(_ cards: [FlashcardModel], modelContext: ModelContext) async {
        for card in cards {
            let cardID = card.id
            let descriptor = FetchDescriptor<FlashcardModel>(
                predicate: #Predicate<FlashcardModel> { flashcard in
                    flashcard.id == cardID
                }
            )
            if let existing = try? modelContext.fetch(descriptor).first {
                existing.term = card.term
                existing.category = card.category
                existing.starred = card.starred
                existing.progress = card.progress
                existing.lastSucceeded = card.lastSucceeded
                existing.gifFileName = card.gifFileName
            } else {
                modelContext.insert(card)
            }
        }
        try? modelContext.save()
    }

    func updateFlashcard(_ card: FlashcardModel, modelContext: ModelContext) async {
        try? modelContext.save()
        
        Task {
            try? await firebaseService.uploadFlashcards([card])
        }
    }
    
    func updateStatusFull(flashcard: FlashcardModel, progress: ProgressType) -> FlashcardModel {
        return FlashcardModel(
            term: flashcard.term,
            id: flashcard.id,
            lastSucceeded: flashcard.lastSucceeded,
            starred: flashcard.starred,
            progress: progress,
            category: flashcard.category,
            gifFileName: flashcard.gifFileName
        )
    }

    func updateStatus(for card: FlashcardModel, to newProgress: ProgressType) -> FlashcardModel {
        card.progress = newProgress
        return card
    }
    
    func handleAnswer(for card: FlashcardModel, correct: Bool, user: User, dataVM: SwiftDataVM) {
        dataVM.updateStreak(for: user)
        
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
        
        let now = Date()
        
        func baseWeight(for card: FlashcardModel) -> Double {
            switch card.progress {
            case .new: return 5
            case .learning: return 4
            case .polishing: return 2
            case .mastered: return 1
            }
        }
        
        // ideal amount of time before seeing cards
        func interval(for card: FlashcardModel) -> TimeInterval {
            switch card.progress {
            case .new: return 0
            case .learning: return 60 * 60 * 24 // 1 day
            case .polishing: return 60 * 60 * 24 * 3 // 3 days
            case .mastered: return 60 * 60 * 24 * 7 // 7 days
            }
        }
        
        // decides how overdue a card is to increase or lower the chance of it appearing
        func timeMultiplier(for card: FlashcardModel) -> Double {
            guard let last = card.lastSucceeded else { return 2.0 }
            let elapsed = now.timeIntervalSince(last)
            let target = interval(for: card)
            guard target > 0 else { return 1.5 }
            let ratio = elapsed / target
            if ratio >= 1 { return 2.0 }
            if ratio >= 0.5 { return 1.2 }
            return 0.6
        }
        
        let weightedPairs = flashcards.map { card -> (card: FlashcardModel, weight: Double) in
            let weight = max(0.1, baseWeight(for: card) * timeMultiplier(for: card))
            return (card, weight)
        }
        
        // filter out the last card to prevent repeats
        let filteredPairs = weightedPairs.filter { $0.card.id != lastCardID }
        let finalPairs = filteredPairs.isEmpty ? weightedPairs : filteredPairs
        
        let totalWeight = finalPairs.reduce(0) { $0 + $1.weight }
        var randomThreshold = Double.random(in: 0..<totalWeight)
        for pair in finalPairs {
            randomThreshold -= pair.weight
            if randomThreshold <= 0 {
                lastCardID = pair.card.id
                return pair.card
            }
        }
        return finalPairs.last?.card
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
