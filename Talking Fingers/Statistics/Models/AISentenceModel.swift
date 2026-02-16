//
//  AISentenceModel.swift
//  Talking Fingers
//
//  Created by Judy Hsu on 2/9/26.
//

import Foundation

enum PracticeType: String, Codable {
    case words
    case signs
}

struct AISentenceModel: Identifiable, Codable {
    var id = UUID()
    var words: [FlashcardModel]
    var score: [Int]
    var practiceType: PracticeType

    init(words: [FlashcardModel], score: [Int], practiceType: PracticeType) {
        self.id = UUID()
        self.words = words
        self.score = score
        self.practiceType = practiceType
    }
}
