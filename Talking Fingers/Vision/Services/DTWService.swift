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

    /// Temporary function to calcaulate the distance between two frames based on overlapping joint data.
    // TODO: Replace this function with #73 Frame by Frame Comparison
    private func frameDistance(_ f1: SignFrame, _ f2: SignFrame) -> Double {
        var totalDist: Double = 0
        var matchCount = 0
        
        for (jointType, p1) in f1.joints {
            if let p2 = f2.joints[jointType] {
                totalDist += hypot(p1.x - p2.x, p1.y - p2.y)
                matchCount += 1
            }
        }

        return matchCount > 0 ? (totalDist / Double(matchCount)) : .infinity
    }
}
