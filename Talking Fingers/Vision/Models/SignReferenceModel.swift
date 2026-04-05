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

/// A single locally recorded take, backed by files in Application Support/Recordings.
/// Usually both `jsonURL` and `videoURL` exist and share the same basename.
struct RecordedSignTake: Identifiable, Hashable, Sendable {
    let id: String
    let baseName: String
    let signName: String
    let createdAt: Date
    let jsonURL: URL?
    let videoURL: URL?

    init(
        baseName: String,
        signName: String,
        createdAt: Date,
        jsonURL: URL?,
        videoURL: URL?
    ) {
        self.id = baseName
        self.baseName = baseName
        self.signName = signName
        self.createdAt = createdAt
        self.jsonURL = jsonURL
        self.videoURL = videoURL
    }

    var displayFileName: String {
        if let videoURL {
            return videoURL.lastPathComponent
        }
        if let jsonURL {
            return jsonURL.lastPathComponent
        }
        return baseName
    }

    var frameDataAvailable: Bool { jsonURL != nil }
    var videoAvailable: Bool { videoURL != nil }
}
