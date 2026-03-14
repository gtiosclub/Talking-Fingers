//
//  CategoryComponent.swift
//  Talking Fingers
//
//  Created by Isha Jain on 2/5/26.
//

import SwiftUI

struct CategoryComponent: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        HStack(spacing: 12) {
            CategoryComponent(title: "Alphabet")
            CategoryComponent(title: "Numbers")
        }
        .padding()
    }
}
