//
//  UserModel.swift
//  Talking Fingers
//
//  Created by Jihoon Kim on 1/27/26.
//

class User {
    var userId: String
    var name: String
    var email: String
    var password: String
    
    init(userId: String, name: String, email: String) {
        self.userId = userId
        self.name = name
        self.email = email
        self.password = ""
    }
    
}
