//
//  SentenceExerciseModel.swift
//  Talking Fingers
//
//  Created by Na Hua on 2/19/26.
//
import Foundation

struct SentenceExerciseModel: Identifiable, Codable, Equatable {
    var id: UUID
    var sentence: AISentenceModel
    let correctOrder: [String]
    let distractors: [String]
    let wordBank: [String]
    
    init(sentence: AISentenceModel,
        correctOrder: [String],
        distractors: [String] = [],
        wordBank: [String]? = nil) {
        self.id = UUID()
        self.sentence = sentence
        self.correctOrder = correctOrder
        self.distractors = distractors
        let merged = correctOrder + distractors
        self.wordBank = wordBank ?? merged.shuffled()
    }
    
    var prompt: String {
        sentence.sentence
    }
    var wordBankTokenModels: [WordTokenModel] {
            wordBank.map { WordTokenModel(text: $0) }
    }
}
