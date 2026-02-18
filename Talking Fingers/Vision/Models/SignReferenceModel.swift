//
//  SignReferenceModel.swift
//  Talking Fingers
//
//  Created by Anushka Prabhu on 2/16/26.
//


import Foundation

/// A reference model for a sign, containing its unique identifier,
/// optional display name, and a list of captured frames that make up the sign.
final class SignReference: Identifiable, Sendable, Codable {
    let id: UUID
    var signName: String?
    var frames: [SignFrame]

    /// Initialize a new SignReference.
    /// - Parameters:
    ///   - id: Unique identifier (defaults to a new UUID).
    ///   - signName: Optional display name for the sign.
    ///   - frames: Frames that compose this sign (defaults to empty).
    init(id: UUID = UUID(), signName: String? = nil, frames: [SignFrame] = []) {
        self.id = id
        self.signName = signName
        self.frames = frames
    }
}

