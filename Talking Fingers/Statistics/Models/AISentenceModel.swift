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

struct AISentenceModel: Identifiable, Codable {
    var id = UUID()
    var sentence: String
    var gloss: [Term]
    var score: Int?
    var practiceType: PracticeType
    var completed: Bool

    init(sentence: String, score: Int? = nil, practiceType: PracticeType, gloss: [Term], completed: Bool = false) {
        self.id = UUID()
        self.sentence = sentence
        self.score = score
        self.practiceType = practiceType
        self.gloss = gloss
        self.completed = completed
    }
    
    var glossStrings: [String] {
        return gloss.map { $0.rawValue }
    }
}
