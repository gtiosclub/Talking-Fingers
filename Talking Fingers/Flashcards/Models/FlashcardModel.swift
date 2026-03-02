//
//  FlashcardModel.swift
//  Talking Fingers
//
//  Created by Isha Jain on 1/29/26.
//

import Foundation
import SwiftData

@Model
class FlashcardModel {
    @Attribute(.unique) var id: UUID
    var term: String
    var lastSucceeded: Date?
    var starred: Bool
    var progress: ProgressType
    var category: String
    
    init(term: String, id: UUID = UUID(), lastSucceeded: Date? = nil, starred: Bool = false, progress: ProgressType = .new, category: String) {
        self.id = id
        self.term = term
        self.lastSucceeded = lastSucceeded
        self.starred = starred
        self.progress = progress
        self.category = category
    }
}
