//
//  DailyReviewQueue.swift
//  Talking Fingers
//
//  Created by Kairav Parikh on 2/17/26.
//

import Foundation

struct DailyReviewQueue {
    
    let cards: [FlashcardModel]
    let generatedAt: Date
    let totalCardCount: Int
    let categoryBreakdown: [TermCategory: Int]
    let requestedLimit: Int

    var wasTruncated: Bool {
        totalCardCount > requestedLimit
    }

    var categories: [TermCategory] {
        Array(categoryBreakdown.keys).sorted { $0.rawValue < $1.rawValue }
    }

    init(cards: [FlashcardModel], requestedLimit: Int, totalCardCount: Int) {
        self.cards = cards
        self.requestedLimit = requestedLimit
        self.totalCardCount = totalCardCount
        self.generatedAt = Date()

        var breakdown: [TermCategory: Int] = [:]
        for card in cards {
            breakdown[card.category, default: 0] += 1
        }
        self.categoryBreakdown = breakdown
    }
}
