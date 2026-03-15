//
//  SentenceExerciseModel.swift
//  Talking Fingers
//
//  Created by Na Hua on 2/19/26.
//
import Foundation

struct SentenceExerciseModel: Identifiable, Codable, Equatable {
    let id: UUID
    let prompt: String
    let correctOrder: [String]
    let distractors: [String]
    let wordBank: [String]
    
    init(prompt: String,
        correctOrder: [String],
        distractors: [String] = [],
        wordBank: [String]? = nil) {
        self.id = UUID()
        self.prompt = prompt
        self.correctOrder = correctOrder
        self.distractors = distractors
        let merged = correctOrder + distractors
        self.wordBank = wordBank ?? merged.shuffled()
    }
    var wordBankTokenModels: [WordTokenModel] {
            wordBank.map { WordTokenModel(text: $0) }
    }
}
