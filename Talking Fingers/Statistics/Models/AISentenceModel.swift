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
    case comprehension = "comprehension"
}

/// Which practice modes the user wants in this session.
/// At least one must be selected.
struct PracticeModeSelection: Equatable {
    var signing: Bool = true
    var comprehension: Bool = false

    var isValid: Bool { signing || comprehension }
}

struct AISentenceModel: Identifiable, Codable {
    var id = UUID()
    var sentence: String
    var gloss: [Term]
    var score: Int?
    var practiceType: PracticeType
    var completed: Bool
    
    /// For signing: max confidence score (0-100) achieved per word after passing threshold
    var wordScores: [Double]?
    /// For comprehension: number of attempts taken (1 = first try correct, 2+ = needed retries)
    var comprehensionAttempts: Int?
    /// For comprehension: whether the submitted answer was correct.
    /// Optional for backward compatibility with older saved sessions.
    var comprehensionWasCorrect: Bool?

    init(
        sentence: String,
        score: Int? = nil,
        practiceType: PracticeType,
        gloss: [Term],
        completed: Bool = false,
        wordScores: [Double]? = nil,
        comprehensionAttempts: Int? = nil,
        comprehensionWasCorrect: Bool? = nil
    ) {
        self.id = UUID()
        self.sentence = sentence
        self.score = score
        self.practiceType = practiceType
        self.gloss = gloss
        self.completed = completed
        self.wordScores = wordScores
        self.comprehensionAttempts = comprehensionAttempts
        self.comprehensionWasCorrect = comprehensionWasCorrect
    }
    
    var glossStrings: [String] {
        return gloss.map { $0.rawValue }
    }
    
    /// Calculated accuracy for this sentence (0-100)
    var accuracy: Double? {
        guard completed else { return nil }
        
        switch practiceType {
        case .comprehension:
            if let comprehensionWasCorrect, !comprehensionWasCorrect {
                return 0
            }
            guard let attempts = comprehensionAttempts else { return nil }
            // First try = 100%, second try = 70%, third+ = 40%
            switch attempts {
            case 1: return 100
            case 2: return 70
            default: return 40
            }
        case .words, .signs:
            guard let scores = wordScores, !scores.isEmpty else { return nil }
            return scores.reduce(0, +) / Double(scores.count)
        }
    }
}
