//
//  SignReferenceModel.swift
//  Talking Fingers
//
//  Created by Anushka Prabhu on 2/16/26.
//

import Foundation

enum SignType: String, Codable, CaseIterable, Sendable {
    /// Single-frame signs (alphabet letters, some numbers).
    case `static`
    /// Multi-frame signs that involve motion (words, phrases).
    case dynamic
}

/// A reference model for a sign, containing its unique identifier,
/// optional display name, type, and a list of captured frames.
final class SignReference: Identifiable, Sendable, Codable {
    let id: UUID
    var signName: String?
    var signType: SignType
    var frames: [SignFrame]

    init(id: UUID = UUID(), signName: String? = nil, signType: SignType = .static, frames: [SignFrame] = []) {
        self.id = id
        self.signName = signName
        self.signType = signType
        self.frames = frames
    }
}

/// Represents a locally saved recording JSON file that can be browsed and played back.
struct RecordedSignFile: Identifiable, Hashable, Sendable {
    let id: URL
    let url: URL
    let signName: String
    let createdAt: Date
    let fileName: String

    init(url: URL, signName: String, createdAt: Date, fileName: String? = nil) {
        self.id = url
        self.url = url
        self.signName = signName
        self.createdAt = createdAt
        self.fileName = fileName ?? url.lastPathComponent
    }
}
