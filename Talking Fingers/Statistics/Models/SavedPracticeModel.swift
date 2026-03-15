//
//  SavedPracticeModel.swift
//  Talking Fingers
//
//  Created by Aimee on 3/9/26.
//

import SwiftData
import Foundation

@Model
class SavedPracticeModel {
    var id: UUID
    var date: Date
    var sentencesData: Data
    var categories: [String]

    init(sentences: [AISentenceModel], categories: [String]) {
        self.id = UUID()
        self.date = Date()
        self.sentencesData = (try? JSONEncoder().encode(sentences)) ?? Data()
        self.categories = categories
    }

    var sentences: [AISentenceModel] {
        get {
            (try? JSONDecoder().decode([AISentenceModel].self, from: sentencesData)) ?? []
        }
        set {
            sentencesData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }
}
