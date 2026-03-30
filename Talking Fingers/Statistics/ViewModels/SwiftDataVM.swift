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
    var modelContext: ModelContext?
    var savedPractices: [SavedPracticeModel] = []
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }
    
    func generatePromptForLLM(from flashcards: [FlashcardModel], focusTerms: [Term] = []) -> String {
        return PromptGenerator.generatePromptForLLM(from: flashcards, focusTerms: focusTerms)
    }
    
    func fetchFlashcards() -> [FlashcardModel] {
        guard let modelContext = modelContext else { return [] }
        
        do {
            let descriptor = FetchDescriptor<FlashcardModel>()
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching flashcards: \(error)")
            return []
        }
    }
    
    func generatePromptFromCurrentData(focusTerms: [Term] = []) -> String {
        let flashcards = fetchFlashcards()
        if flashcards.isEmpty { 
            return "Error: No flashcards available to generate prompt." 
        }
        return generatePromptForLLM(from: flashcards, focusTerms: focusTerms)
    }
    
    
    func updateFlashcardProgress(flashcards: [FlashcardModel], scores: [Int]) {
        guard flashcards.count == scores.count else { return }
        
        for index in 0..<scores.count {
            if scores[index] == 1 {
                flashcards[index].progress = flashcards[index].progress.increase()
            } else if scores[index] == -1 {
                flashcards[index].progress = flashcards[index].progress.decrease()
            }
        }
    }
    // MARK: - AI Sentence Comprehension Grading
    func gradeSentenceComprehension(correctGloss: [Term], userAnswers: [String]) -> [Int] {
        var score: [Int] = []
        
        for i in 0..<correctGloss.count {
            if i < userAnswers.count {
                let correctWord = correctGloss[i].rawValue.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                let userWord = userAnswers[i].trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                
                if correctWord == userWord {
                    score.append(1)
                } else {
                    score.append(-1)
                }
            } else {
                score.append(-1)
            }
        }
        
        return score
    }
    
    // MARK: - Saved Practice Sessions
    func savePracticeSession(sentences: [AISentenceModel], categories: [String]) {
        guard let modelContext = modelContext else { return }
        
        let savedPractice = SavedPracticeModel(sentences: sentences, categories: categories)
        modelContext.insert(savedPractice)
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving practice session: \(error)")
        }
    }
    
    func fetchSavedPracticeSessions() -> [SavedPracticeModel] {
        guard let modelContext = modelContext else { return [] }
        
        do {
            var descriptor = FetchDescriptor<SavedPracticeModel>()
            descriptor.sortBy = [SortDescriptor(\.date, order: .reverse)]
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching saved practice sessions: \(error)")
            return []
        }
    }
    func getFlashcardsForGloss(_ gloss: [Term]) -> [FlashcardModel] {
            let allFlashcards = fetchFlashcards()
            let glossTermStrings = gloss.map { $0.rawValue }
            
            return glossTermStrings.compactMap { termString in
                allFlashcards.first { $0.term.rawValue == termString }
            }
        }
}
