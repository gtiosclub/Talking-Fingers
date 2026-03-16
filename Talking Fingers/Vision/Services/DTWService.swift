//
//  DTWService.swift
//  Talking Fingers
//
//  Created by Remy Laurens on 2/21/26.
//

import Foundation

struct DTWService {
    
    /// Calculates the similarity score between a live buffer and a reference template.
    /// - Parameters:
    ///   - buffer: The rolling window of frames captured from the camera.
    ///   - template: The reference sign frames used for comparison.
    /// - Returns: The normalized distance score. A lower score indicates a closer match.
    func computeDTW(buffer: SignReference, template: SignReference) -> Double {
        let n = buffer.frames.count
        let m = template.frames.count
        
        if (n == 0 || m == 0) { // no frames to references, should not indicate a low score
            return .infinity
        }
        
        guard n > 0, m > 0 else { return .infinity }
        
        var dtw = Array(repeating: Array(repeating: Double.infinity, count: n + 1), count: m + 1)

        for j in 0...n {
            dtw[0][j] = 0
        }

        for i in 1...m {
            for j in 1...n {
                let cost = frameDistance(template.frames[i-1], buffer.frames[j-1])
                
                dtw[i][j] = cost + min(dtw[i-1][j],     // Insertion
                                       dtw[i][j-1],     // Deletion
                                       dtw[i-1][j-1])   // Match
            }
        }

        guard let minFinalCost = dtw[m].min() else { return .infinity }

        return minFinalCost / Double(m)
    }

    /// Per-frame distance combining two components:
    /// 1. Handshape: centroid + scale normalized hand joints (finger configuration)
    /// 2. Trajectory: wrist/elbow positions relative to shoulder midpoint,
    ///    normalized by shoulder width (where the hand is in signing space)
    private func frameDistance(_ f1: SignFrame, _ f2: SignFrame) -> Double {
        // --- Handshape: centroid+scale normalized hand joints ---
        var matched1: [(x: Double, y: Double)] = []
        var matched2: [(x: Double, y: Double)] = []

        for (key, j1) in f1.joints {
            guard key.contains("VNHLK") else { continue }
            guard let j2 = f2.joints[key] else { continue }
            guard j1.confidence > 0.3, j2.confidence > 0.3 else { continue }
            matched1.append((x: j1.x, y: j1.y))
            matched2.append((x: j2.x, y: j2.y))
        }

        guard matched1.count >= 5 else { return .infinity }

        let n = Double(matched1.count)

        let cx1 = matched1.reduce(0.0) { $0 + $1.x } / n
        let cy1 = matched1.reduce(0.0) { $0 + $1.y } / n
        let cx2 = matched2.reduce(0.0) { $0 + $1.x } / n
        let cy2 = matched2.reduce(0.0) { $0 + $1.y } / n

        let s1 = max(matched1.reduce(0.0) { max($0, hypot($1.x - cx1, $1.y - cy1)) }, 1e-6)
        let s2 = max(matched2.reduce(0.0) { max($0, hypot($1.x - cx2, $1.y - cy2)) }, 1e-6)

        var handshapeDist: Double = 0
        for i in 0..<matched1.count {
            let x1 = (matched1[i].x - cx1) / s1
            let y1 = (matched1[i].y - cy1) / s1
            let x2 = (matched2[i].x - cx2) / s2
            let y2 = (matched2[i].y - cy2) / s2
            handshapeDist += hypot(x1 - x2, y1 - y2)
        }
        handshapeDist /= n

        // --- Trajectory: wrist/elbow positions relative to shoulder midpoint ---
        guard let ls1 = f1.joints["left_shoulder_1_joint"],
              let rs1 = f1.joints["right_shoulder_1_joint"],
              let ls2 = f2.joints["left_shoulder_1_joint"],
              let rs2 = f2.joints["right_shoulder_1_joint"],
              ls1.confidence > 0.3, rs1.confidence > 0.3,
              ls2.confidence > 0.3, rs2.confidence > 0.3 else {
            return handshapeDist
        }

        let bodyCx1 = (ls1.x + rs1.x) / 2, bodyCy1 = (ls1.y + rs1.y) / 2
        let bodyCx2 = (ls2.x + rs2.x) / 2, bodyCy2 = (ls2.y + rs2.y) / 2

        let shoulderW1 = max(hypot(ls1.x - rs1.x, ls1.y - rs1.y), 1e-6)
        let shoulderW2 = max(hypot(ls2.x - rs2.x, ls2.y - rs2.y), 1e-6)

        let trajectoryJoints = ["leftVNHLKWRI", "rightVNHLKWRI",
                                "left_forearm_joint", "right_forearm_joint"]
        var trajectoryDist: Double = 0
        var trajectoryCount = 0

        for key in trajectoryJoints {
            guard let j1 = f1.joints[key], let j2 = f2.joints[key],
                  j1.confidence > 0.3, j2.confidence > 0.3 else { continue }
            let tx1 = (j1.x - bodyCx1) / shoulderW1
            let ty1 = (j1.y - bodyCy1) / shoulderW1
            let tx2 = (j2.x - bodyCx2) / shoulderW2
            let ty2 = (j2.y - bodyCy2) / shoulderW2
            trajectoryDist += hypot(tx1 - tx2, ty1 - ty2)
            trajectoryCount += 1
        }

        guard trajectoryCount > 0 else { return handshapeDist }
        trajectoryDist /= Double(trajectoryCount)

        return 0.5 * handshapeDist + 0.5 * trajectoryDist
    }
}
