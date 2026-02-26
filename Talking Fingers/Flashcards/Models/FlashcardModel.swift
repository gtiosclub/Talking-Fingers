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
    var gifFileName: String?
    
    init(term: String, id: UUID, lastSucceeded: Date?, starred: Bool, progress: ProgressType, category: String, gifFileName: String? = nil) {
        self.term = term
        self.id = id
        self.lastSucceeded = lastSucceeded
        self.starred = starred
        self.progress = progress
        self.category = category
        self.gifFileName = gifFileName
    }
    
    init(term: String, id: UUID, category: String, gifFileName: String? = nil) {
        self.term = term
        self.id = id
        self.lastSucceeded = nil
        self.starred = false
        self.progress = .new
        self.category = category
        self.gifFileName = gifFileName
    }
}
