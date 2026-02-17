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
