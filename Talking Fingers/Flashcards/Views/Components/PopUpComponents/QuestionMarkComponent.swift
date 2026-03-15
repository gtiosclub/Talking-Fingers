//
//  QuestionMarkComponent.swift
//  Talking Fingers
//
//  Created by Ria Sharma on 3/13/26.
//

import SwiftUI

struct QuestionMarkPopUpComponent: View {
    
    let explanationText: String
    var onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 23) {
            Spacer()
                .frame(height: 1)
            Text(explanationText)
                .font(.system(size: 27, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 1)
                
            Spacer()
                .frame(height: 5)
            Button {
                onDismiss()
            } label: {
                Text("Yes")
                    .font(.system(size: 18, weight: .semibold))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 132)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray, lineWidth: 2)
                    )
            }
            Button {
                onDismiss()
            } label: {
                Text("No")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.2, green: 0.2, blue: 0.2))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            Spacer()
                .frame(height: 1)
        }
        .padding(28)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 20)
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
}

#Preview {
    QuestionMarkPopUpComponent(
        explanationText: "Are you sure you want to move on?"
    ) {}
}
