//
//  ProgressBar.swift
//  Talking Fingers
//
//  Created by Krish Prasad on 3/1/26.
//
import SwiftUI

struct CustomProgressBar: View {
    var progress: Double
    /// Track includes alpha when using 8-digit hex (e.g. `#A9CEEC26`).
    var trackColor: Color = Color(hex: "#A9CEEC26")
    var trackOpacity: Double = 1.0
    var fillColor: Color = Color(hex: "#58A0DA")
    var barHeight: CGFloat = 10

    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = barHeight
            let rawFill = CGFloat(progress) * w
            let fillW = progress <= 0 ? 0 : max(h * 0.5, min(rawFill, w))

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(trackColor.opacity(trackOpacity))

                Capsule()
                    .fill(fillColor)
                    .frame(width: fillW)
            }
            .frame(width: w, height: h)
        }
        .frame(height: barHeight)
    }
}
