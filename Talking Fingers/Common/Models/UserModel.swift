//
//  UserModel.swift
//  Talking Fingers
//
//  Created by Jihoon Kim on 1/27/26.
//

import Foundation
import SwiftData

@Model
class User {
    var userId: String
    var name: String
    var email: String
    var password: String
    var birthday: Date
    
    @Relationship(deleteRule: .cascade)
    var flashcards: [FlashcardModel]
    
    var unlockedCategories: [String]
    var streakCount: Int = 0
    var lastActivity: Date?
    
    init(userId: String, name: String, email: String) {
        self.userId = userId
        self.name = name
        self.email = email
        self.password = ""
        self.birthday = Date()
        self.flashcards = []
        self.unlockedCategories = []
        self.streakCount = 0
        self.lastActivity = nil
    }
}
