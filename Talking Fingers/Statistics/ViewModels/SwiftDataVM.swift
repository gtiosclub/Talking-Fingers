//
//  SwiftDataVM.swift
//  Talking Fingers
//
//  Created by Krish Prasad on 2/4/26.
//

import Observation
import SwiftData
import Foundation

@Observable
class SwiftDataVM {
    private var modelContext: ModelContext?
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }
    
    func generatePromptForLLM(from flashcards: [StatsFlashcard]) -> String {
        return PromptGenerator.generatePromptForLLM(from: flashcards)
    }
    
    func fetchFlashcards() -> [StatsFlashcard] {
        guard let modelContext = modelContext else { return [] }
        
        do {
            let descriptor = FetchDescriptor<StatsFlashcard>()
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching flashcards: \(error)")
            return []
        }
    }
    
    func generatePromptFromCurrentData() -> String {
        let flashcards = fetchFlashcards()
        if flashcards.isEmpty { 
            return "Error: No flashcards available to generate prompt." 
        }
        return generatePromptForLLM(from: flashcards)
    }
    
    
    func updateFlashcardProgress(flashcards: [StatsFlashcard], scores: [Int]) {
        guard flashcards.count == scores.count else { return }
        
        for index in 0..<scores.count {
            if scores[index] == 1 {
                flashcards[index].progress = flashcards[index].progress.increase()
            } else if scores[index] == -1 {
                flashcards[index].progress = flashcards[index].progress.decrease()
            }
        }
    }
}
