//
//  FlashcardModel.swift
//  Talking Fingers
//
//  Created by Isha Jain on 1/29/26.
//

import Foundation

class FlashcardModel {
    var term: String
    var id: UUID = UUID()
    var lastSucceeded: Date?
    var starred: Bool
    var progress: ProgressType
    
    init(term: String, id: UUID, lastSucceeded: Date?, starred: Bool, progress: ProgressType) {
        self.term = term
        self.id = id
        self.lastSucceeded = lastSucceeded
        self.starred = starred
        self.progress = progress
    }
    
    init(term: String, id: UUID) {
        self.term = term
        self.id = id
        self.lastSucceeded = nil
        self.starred = false
        self.progress = .new
    }
}
