//
//  AISentenceModel.swift
//  Talking Fingers
//
//  Created by Judy Hsu on 2/9/26.
//

import Foundation

enum PracticeType: String, Codable {
    case words = "word"
    case signs = "signs"
}

enum Difficulty: String, Codable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
}

struct AISentenceModel: Identifiable, Codable {
    var id = UUID()
    var sentence: String
    var gloss: [String]
    var score: [Int]
    var practiceType: PracticeType
    var difficulty: Difficulty

    init(sentence: String, score: [Int], practiceType: PracticeType, difficulty: Difficulty, gloss: [String]) {
        self.id = UUID()
        self.sentence = sentence
        self.score = score
        self.practiceType = practiceType
        self.difficulty = difficulty
        self.gloss = gloss
    }
}
