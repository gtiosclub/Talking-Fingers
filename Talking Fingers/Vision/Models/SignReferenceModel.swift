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

