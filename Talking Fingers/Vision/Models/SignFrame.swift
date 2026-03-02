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
    
    let joints: [String: Joint]
    
    var timestamp: CMTime {
        CMTime(seconds: seconds, preferredTimescale: timescale)
    }

    init(body: VNHumanBodyPoseObservation?, hands: [VNHumanHandPoseObservation], at time: CMTime) {
        self.id = UUID()
        self.seconds = time.seconds
        self.timescale = time.timescale
        
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
    }
}
