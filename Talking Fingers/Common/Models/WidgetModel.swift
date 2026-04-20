//
//  WidgetModel.swift
//  Talking Fingers
//
//  Created by Assistant on 4/19/26.
//

import Foundation

enum WidgetType: String, Codable, CaseIterable {
    case streak = "Streak"
    case wordsLearned = "Words Learned"
    case recentProgress = "Recent Progress"
    case dailyChallenge = "Daily Challenge"
    case masteryBadges = "Mastery Badges"
    case weeklyActivity = "Weekly Activity"
    case accuracy = "Accuracy"
}

struct ProfileWidget: Identifiable, Codable {
    var id = UUID()
    var type: WidgetType
    var order: Int
}