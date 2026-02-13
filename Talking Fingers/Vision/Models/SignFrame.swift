//
//  SignFrame.swift
//  Talking Fingers
//
//  Created by Remy Laurens on 2/12/26.
//

import Foundation
import Vision
import CoreMedia

struct JointInfo: Codable {
    let name: String
    let x: Double
    let y: Double
    let confidence: Float
}

enum HandSide: String, Codable {
    case left
    case right
    case unknown
    
    init(from vnChirality: VNChirality) {
        switch vnChirality {
        case .left: self = .left
        case .right: self = .right
        case .unknown: self = .unknown
        }
    }
}

struct SignFrame: Identifiable, Codable {
    let id: UUID
    private let seconds: Double
    private let timescale: Int32
    
    let joints: [JointInfo]
    let chirality: HandSide // Use the Enum here
    
    var timestamp: CMTime {
        CMTime(seconds: seconds, preferredTimescale: timescale)
    }

    init(from observation: VNHumanHandPoseObservation, at time: CMTime) {
        self.id = UUID()
        self.seconds = time.seconds
        self.timescale = time.timescale
        
        // Clean conversion using our Enum init
        self.chirality = HandSide(from: observation.chirality)
        
        let allPoints = (try? observation.recognizedPoints(.all)) ?? [:]
        self.joints = allPoints.compactMap { (key, point) in
            JointInfo(
                name: key.rawValue.rawValue,
                x: point.location.x,
                y: point.location.y,
                confidence: point.confidence
            )
        }
    }
}
