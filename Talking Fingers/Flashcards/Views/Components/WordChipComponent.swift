//
//  WordChipComponent.swift
//  Talking Fingers
//
//  Created by Na Hua on 2/19/26.
//
import SwiftUI

struct WordChipView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .overlay(
                Capsule().stroke(Color.gray.opacity(0.25), lineWidth: 1)
            )
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.06), radius: 1, x: 0, y: 1)
    }
}
