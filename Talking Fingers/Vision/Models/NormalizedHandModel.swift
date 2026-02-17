import Foundation
import Vision
import CoreGraphics

struct NormalizedHand: Identifiable {
    let id = UUID()
    let joints: [VNHumanHandPoseObservation.JointName: CGPoint]
    
    init?(from observation: VNHumanHandPoseObservation, pitch: Double) {
        var correctedJoints: [VNHumanHandPoseObservation.JointName: CGPoint] = [:]
        guard let allPoints = try? observation.recognizedPoints(.all) else { return nil }
        
        // Aspect ratio
        let width: CGFloat = 720
        let height: CGFloat = 1280
        let correctionFactor = CGFloat(cos(pitch))
        
        guard abs(correctionFactor) > 0.1 else { return nil }
        
        for (name, point) in allPoints {
            let pixelY = point.location.y * height
            
            let centeredY = pixelY - (height / 2)
            let correctedY = (centeredY / correctionFactor) + (height / 2)
            
            let finalY = correctedY / height
            
            correctedJoints[name] = CGPoint(x: point.location.x, y: finalY)
        }
        self.joints = correctedJoints
    }
}
