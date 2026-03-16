//
//  CircleButton.swift
//  Talking Fingers
//

import SwiftUI

struct CircleButton: View {

    let icon: String
    var isHighlighted: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isHighlighted ? .white : .primary)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(isHighlighted ? Color.accentColor : Color.gray.opacity(0.2))
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack(spacing: 20) {
        CircleButton(icon: "checkmark") {}
        CircleButton(icon: "eye.fill", isHighlighted: true) {}
        CircleButton(icon: "lock.fill") {}
    }
}
