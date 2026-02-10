//
//  NormalizedHandModel.swift
//  Talking Fingers
//
//  Created by Remy Laurens on 2/9/26.
//

import Foundation
import Vision

struct NormalizedHand {
    let id = UUID()
    let joints: [VNHumanHandPoseObservation.JointName: CGPoint]
    
    init?(from observation: VNHumanHandPoseObservation, aspect: CGFloat = 720.0 / 1280.0) {
        
        guard let wrist = try? observation.recognizedPoint(.wrist),
              let middleMCP = try? observation.recognizedPoint(.middleMCP) else {
            return nil
        }

        let wristPoint = CGPoint(x: wrist.location.x * aspect, y: wrist.location.y)
        let mcpPoint = CGPoint(x: middleMCP.location.x * aspect, y: middleMCP.location.y)

        let dx = mcpPoint.x - wristPoint.x
        let dy = mcpPoint.y - wristPoint.y
        let distance = sqrt(dx*dx + dy*dy)
        let angle = atan2(dy, dx) - (CGFloat.pi / 2)

        var normalizedJoints: [VNHumanHandPoseObservation.JointName: CGPoint] = [:]
        let joints = try? observation.recognizedPoints(.all)
        
        joints?.forEach { (name, point) in
            
            let tx = (point.location.x * aspect) - wristPoint.x
            let ty = point.location.y - wristPoint.y

            let cost = cos(-angle)
            let sint = sin(-angle)

            let rx = (tx * cost - ty * sint) / distance
            let ry = (tx * sint + ty * cost) / distance

            normalizedJoints[name] = CGPoint(x: rx, y: ry)
        }
        self.joints = normalizedJoints
    }
}
