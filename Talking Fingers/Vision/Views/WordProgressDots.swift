//
//  WordProgressDots.swift
//  Talking Fingers
//

import SwiftUI

struct WordProgressDots: View {

    let total: Int
    let current: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0 ..< total, id: \.self) { index in
                Circle()
                    .fill(index == current ? Color.accentColor : Color.gray.opacity(0.4))
                    .frame(width: 10, height: 10)
            }
        }
    }
}

#Preview {
    WordProgressDots(total: 3, current: 1)
}
