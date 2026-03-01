//
//  WordTokenModel.swift
//  Talking Fingers
//
//  Created by Na Hua on 2/27/26.
//
import Foundation

struct WordTokenModel: Identifiable, Hashable {
    let id: UUID
    let text: String

    init(id: UUID = UUID(), text: String) {
        self.id = id
        self.text = text
    }
}

