//
//  FlashcardModel.swift
//  Talking Fingers
//
//  Created by Isha Jain on 1/29/26.
//

import Foundation

class FlashcardModel {
    var term: String
    var definition: String
    var lastSucceeded: Date?
    var starred: Bool
    
    init(term: String, definition: String, lastSucceeded: Date? = nil, starred: Bool) {
        self.term = term
        self.definition = definition
        self.lastSucceeded = nil
        self.starred = false
    }
}
