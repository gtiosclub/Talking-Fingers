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
    var term: Term
    var lastSucceeded: Date?
    var starred: Bool
    var progress: ProgressType
    var category: TermCategory
    var gifFileName: String?
    
    init(term: Term, id: UUID, lastSucceeded: Date?, starred: Bool, progress: ProgressType, category: TermCategory, gifFileName: String? = nil) {
        self.term = term
        self.id = id
        self.lastSucceeded = lastSucceeded
        self.starred = starred
        self.progress = progress
        self.category = category
        self.gifFileName = gifFileName ?? term.defaultGifFileName
    }    
    init(term: Term, id: UUID, category: TermCategory, gifFileName: String? = nil) {
        self.term = term
        self.id = id
        self.lastSucceeded = nil
        self.starred = false
        self.progress = .new
        self.category = category
        self.gifFileName = gifFileName ?? term.defaultGifFileName
    }
}
