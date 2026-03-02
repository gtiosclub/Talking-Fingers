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
}
