//
//  ProgressModel.swift
//  Talking Fingers
//
//  Created by Jagat Sachdeva on 2/19/26.
//

import Foundation
import SwiftData

@Model
class StatsWidget {
    var id: UUID
    var title: String
    var displayOrder: Int

    init(id: UUID = UUID(), title: String, displayOrder: Int = 0) {
        self.id = id
        self.title = title
        self.displayOrder = displayOrder
    }
}
