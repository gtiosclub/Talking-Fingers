//
//  SignFrame.swift
//  Talking Fingers
//
//  Created by Remy Laurens on 2/12/26.
//

import Foundation
import Vision
import CoreMedia

struct Joint: Codable {
    let x: Double
    let y: Double
    let confidence: Float
}

struct SignFrame: Identifiable, Codable {
    let id: UUID
    private let seconds: Double
    private let timescale: Int32

    /// Pixel dimensions of the camera frame this sample was captured from.
    ///
    /// Vision returns joint positions as fractions of the source frame's width
    /// and height (the values in `joints`), so the same physical pose produces
    /// different x/y values depending on the source aspect ratio. Comparison
    /// code uses these dimensions to convert back to pixel-equivalent space
    /// before doing any centroid/scale normalization, which lets references
    /// recorded on one platform (e.g. iPhone portrait) be scored correctly on
    /// another (e.g. macOS landscape).
    ///
    /// All references shipped with the app were recorded on iPhone in portrait
    /// at the `.hd1280x720` preset, so frames decoded from JSON without these
    /// fields default to `720 x 1280`.
    let sourceWidth: Double
    let sourceHeight: Double

    /// Raw Vision-normalized joint positions (0..1 coordinate space).
    let joints: [String: Joint]

    /// Anchor-relative joint positions:
    /// - Shoulders & elbows: relative to body center (midpoint of both shoulders = 0,0)
    /// - Hand joints: relative to that hand's wrist (wrist = 0,0)
    let normalizedJoints: [String: Joint]
    
    var timestamp: CMTime {
        CMTime(seconds: seconds, preferredTimescale: timescale)
    }

    /// Default capture dimensions for live frames on the current platform.
    /// Matches the orientation we configure on the AVCaptureConnection in
    /// `CameraVM.setupSession()`:
    /// - iOS: portrait (`.portrait` orientation, 720 x 1280)
    /// - macOS: native landscape (1280 x 720)
    static var liveDefaultSourceWidth: Double {
        #if os(macOS)
        return 1280
        #else
        return 720
        #endif
    }

    static var liveDefaultSourceHeight: Double {
        #if os(macOS)
        return 720
        #else
        return 1280
        #endif
    }

    /// Default capture dimensions assumed for reference JSONs that predate the
    /// `sourceWidth` / `sourceHeight` fields. All bundled references were
    /// recorded on iPhone in portrait, so they map to a 720 x 1280 frame.
    static let referenceDefaultSourceWidth: Double = 720
    static let referenceDefaultSourceHeight: Double = 1280

    init(
        body: VNHumanBodyPoseObservation?,
        hands: [VNHumanHandPoseObservation],
        at time: CMTime,
        sourceWidth: Double = SignFrame.liveDefaultSourceWidth,
        sourceHeight: Double = SignFrame.liveDefaultSourceHeight
    ) {
        self.id = UUID()
        self.seconds = time.seconds
        self.timescale = time.timescale
        self.sourceWidth = sourceWidth
        self.sourceHeight = sourceHeight

        var tempJoints: [String: Joint] = [:]
        
        if let body = body {
            let bodyPoints = (try? body.recognizedPoints(.all)) ?? [:]
            for (key, point) in bodyPoints where point.confidence > 0.3 {
                tempJoints[key.rawValue.rawValue] = Joint(
                    x: point.location.x,
                    y: point.location.y,
                    confidence: point.confidence
                )
            }
        }
        
        for hand in hands {
            let prefix = hand.chirality == .left ? "left" : "right"
            let handPoints = (try? hand.recognizedPoints(.all)) ?? [:]
            
            for (key, point) in handPoints where point.confidence > 0.3 {
                let rawName = key.rawValue.rawValue
                
                let formattedName = prefix + rawName.prefix(1).uppercased() + String(rawName.dropFirst())
                
                tempJoints[formattedName] = Joint(
                    x: point.location.x,
                    y: point.location.y,
                    confidence: point.confidence
                )
            }
        }
        
        self.joints = tempJoints
        self.normalizedJoints = SignFrame.computeNormalizedJoints(from: tempJoints)
    }

    // MARK: - Codable (backward-compatible with JSON that lacks normalizedJoints)

    private enum CodingKeys: String, CodingKey {
        case id, seconds, timescale, joints, normalizedJoints, sourceWidth, sourceHeight
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        seconds = try c.decode(Double.self, forKey: .seconds)
        timescale = try c.decode(Int32.self, forKey: .timescale)
        joints = try c.decode([String: Joint].self, forKey: .joints)
        normalizedJoints = try c.decodeIfPresent([String: Joint].self, forKey: .normalizedJoints)
            ?? SignFrame.computeNormalizedJoints(from: joints)
        sourceWidth = try c.decodeIfPresent(Double.self, forKey: .sourceWidth)
            ?? SignFrame.referenceDefaultSourceWidth
        sourceHeight = try c.decodeIfPresent(Double.self, forKey: .sourceHeight)
            ?? SignFrame.referenceDefaultSourceHeight
    }

    // MARK: - Normalization logic

    private static let bodyJointKeys: Set<String> = [
        "leftShoulder", "rightShoulder", "leftElbow", "rightElbow"
    ]

    static func computeNormalizedJoints(from joints: [String: Joint]) -> [String: Joint] {
        var normalized: [String: Joint] = [:]

        // --- Body: anchor = midpoint of both shoulders ---
        if let ls = joints["leftShoulder"], let rs = joints["rightShoulder"] {
            let centerX = (ls.x + rs.x) / 2.0
            let centerY = (ls.y + rs.y) / 2.0

            for key in bodyJointKeys {
                if let j = joints[key] {
                    normalized[key] = Joint(
                        x: j.x - centerX,
                        y: j.y - centerY,
                        confidence: j.confidence
                    )
                }
            }
        }

        // --- Hands: anchor = respective wrist ---
        for prefix in ["left", "right"] {
            let wristKey = "\(prefix)Wrist"
            guard let wrist = joints[wristKey] else { continue }

            for (key, joint) in joints where key.hasPrefix(prefix) {
                if bodyJointKeys.contains(key) { continue }

                normalized[key] = Joint(
                    x: joint.x - wrist.x,
                    y: joint.y - wrist.y,
                    confidence: joint.confidence
                )
            }
        }

        return normalized
    }
}
// MARK: - JSON encode/decode helpers (SignFrame array)

extension SignFrame {
    static func encodeArray(_ frames: [SignFrame], pretty: Bool = true) throws -> Data {
        let encoder = JSONEncoder()
        if pretty {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        }
        return try encoder.encode(frames)
    }

    static func decodeArray(from data: Data) throws -> [SignFrame] {
        try JSONDecoder().decode([SignFrame].self, from: data)
    }

    static func decodeArray(from url: URL) throws -> [SignFrame] {
        try decodeArray(from: Data(contentsOf: url))
    }
}
