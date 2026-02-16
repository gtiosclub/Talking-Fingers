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
    var words: [String]
    var gloss: [String]
    var score: [Int]
    var practiceType: PracticeType
    var difficulty: Difficulty

    init(words: [String], score: [Int], practiceType: PracticeType, difficulty: Difficulty, gloss: [String]) {
        self.id = UUID()
        self.words = words
        self.score = score
        self.practiceType = practiceType
        self.difficulty = difficulty
        self.gloss = gloss
    }
}
