//
//  UserModel.swift
//  Talking Fingers
//
//  Created by Jihoon Kim on 1/27/26.
//

import Foundation

class User {
    var userId: String
    var name: String
    var email: String
    var password: String
    var birthday: Date
    var flashcards: [FlashcardModel]
    var unlockedCategories: [String] //change to [Category] later
    
    init(userId: String, name: String, email: String, birthday: Date) {
        self.userId = userId
        self.name = name
        self.email = email
        self.password = ""
        self.birthday = birthday
        self.flashcards = []
        self.unlockedCategories = []
    }
}
