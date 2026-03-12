//
//  ActionButtonComponent.swift
//  Talking Fingers
//
//  Created by Na Hua on 3/8/26.
//

import SwiftUI

enum ActionButtonStyle {
    case primary
    case secondary
}

struct ActionButton: View {
    let title: String
    let style: ActionButtonStyle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .foregroundStyle(style == .primary ? .white : .black)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(style == .primary ? Color.black.opacity(0.75) : Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(style == .secondary ? Color.black : Color.clear, lineWidth: 1)
                )
        }
    }
}
