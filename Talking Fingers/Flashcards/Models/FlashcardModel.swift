//
//  FlashcardModel.swift
//  Talking Fingers
//
//  Created by Isha Jain on 1/29/26.
//

import Foundation

class FlashcardModel : Codable {
    var term: String
    var id: UUID = UUID()
    var lastSucceeded: Date?
    var starred: Bool
    var progress: ProgressType
    var category: String
    
    init(term: String, id: UUID, lastSucceeded: Date?, starred: Bool, progress: ProgressType, category: String) {
        self.term = term
        self.id = id
        self.lastSucceeded = lastSucceeded
        self.starred = starred
        self.progress = progress
        self.category = category
    }
    
    init(term: String, id: UUID, category: String) {
        self.term = term
        self.id = id
        self.lastSucceeded = nil
        self.starred = false
        self.progress = .new
        self.category = category
    }
}
