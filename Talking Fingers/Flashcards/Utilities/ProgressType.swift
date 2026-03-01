//
//  ProgressType.swift
//  Talking Fingers
//
//  Created by Isha Jain on 1/29/26.
//

import Foundation

public enum ProgressType: String, Codable {
    case new
    case learning
    case polishing
    case mastered
    
    func increase() -> ProgressType {
            switch self {
            case .new: return .learning
            case .learning: return .polishing
            case .polishing: return .mastered
            case .mastered: return .mastered
            }
        }
        
        func decrease() -> ProgressType {
            switch self {
            case .new: return .new
            case .learning: return .new
            case .polishing: return .learning
            case .mastered: return .polishing
            }
        }
}
