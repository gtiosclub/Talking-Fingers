//
//  SecondaryActionButtonComponent.swift
//  Talking Fingers
//
//  Created by Na Hua on 3/2/26.
//
import SwiftUI
struct SecondaryActionButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }
}
