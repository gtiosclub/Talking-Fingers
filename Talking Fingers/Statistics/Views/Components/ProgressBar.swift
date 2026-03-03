//
//  ProgressBar.swift
//  Talking Fingers
//
//  Created by Krish Prasad on 3/1/26.
//
import SwiftUI

struct CustomProgressBar: View {
    var progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: 16)
                    .opacity(0.3)
                    .foregroundColor(.gray)

                Rectangle()
                    .frame(width: min(CGFloat(progress) * geometry.size.width, geometry.size.width), height: 16)
                    .foregroundColor(.gray)
            }
        }
        .frame(height: 16)
    }
}
