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
    /// User-visible practice name from the New Practice sheet (`nil` for legacy rows).
    var title: String?

    init(sentences: [AISentenceModel], categories: [String], title: String? = nil) {
        self.id = UUID()
        self.date = Date()
        self.sentencesData = (try? JSONEncoder().encode(sentences)) ?? Data()
        self.categories = categories
        self.title = title
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
