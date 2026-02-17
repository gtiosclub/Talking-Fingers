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
    
    // MARK: - Properties
    private var modelContext: ModelContext?
    
    // MARK: - Initialization
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }
    
    // MARK: - Enhanced Prompt Generation with Learning Path Principles
    func generatePromptForLLM(from flashcards: [StatsFlashcard]) -> String {
        return PromptGenerator.generatePromptForLLM(from: flashcards)
    }
    
    // MARK: - Data Operations
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
    
    
}
