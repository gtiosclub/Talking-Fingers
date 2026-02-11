//
//  Flashcard.swift
//  Talking Fingers
//
//  Created by Krish Prasad on 2/4/26.
//
import SwiftData
import Foundation

class StatsFlashcard {
    var term: String
    var definition: String
    var lastSucceeded: Date?
    var starred: Bool
    var progress: ProgressType
    
    init(term: String, definition: String, lastSucceeded: Date? = nil, starred: Bool, progress: ProgressType) {
        self.term = term
        self.definition = definition
        self.lastSucceeded = nil
        self.starred = false
        self.progress = progress
    }
}
