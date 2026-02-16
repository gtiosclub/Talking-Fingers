//
//  SignReferenceModel.swift
//  Talking Fingers
//
//  Created by Anushka Prabhu on 2/16/26.
//


import Foundation

/// Represents a single frame of a sign recording.
public struct SignFrame: Sendable, Codable, Hashable {
    // Intentionally empty for now
    public init() {}
}

/// A reference model for a sign, containing its unique identifier,
/// optional display name, and a list of captured frames that make up the sign.
public final class SignReference: Identifiable, Sendable, Codable {
    public let id: UUID
    public var signName: String?
    public var frames: [SignFrame]

    /// Initialize a new SignReference.
    /// - Parameters:
    ///   - id: Unique identifier (defaults to a new UUID).
    ///   - signName: Optional display name for the sign.
    ///   - frames: Frames that compose this sign (defaults to empty).
    public init(id: UUID = UUID(), signName: String? = nil, frames: [SignFrame] = []) {
        self.id = id
        self.signName = signName
        self.frames = frames
    }
}
