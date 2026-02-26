//
//  AnalyticsModel.swift
//  Talking Fingers
//
//  Created by Ilisha Gupta on 24/02/26.
//

import Foundation
import SwiftData

@Model
class AnalyticsModel {
    var date: Date
    var value: Float

    init(date: Date, value: Float) {
        self.date = date
        self.value = value
    }
}
