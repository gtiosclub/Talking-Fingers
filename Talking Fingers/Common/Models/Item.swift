//
//  Item.swift
//  Talking Fingers
//
//  Created by Nikola Cao on 1/24/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
