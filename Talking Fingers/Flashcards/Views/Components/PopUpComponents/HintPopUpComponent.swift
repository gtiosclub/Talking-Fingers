//
//  HintPopUpComponent.swift
//  Talking Fingers
//
//  Created by Ria Sharma on 3/13/26.
//

import SwiftUI

struct HintPopUpComponent: View {
    let hintText: String
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 23) {
            Text("Hint")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Color(red: 0.93, green: 0.78, blue: 0.50))
                .padding(.top, 10)

            Text(hintText)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.black.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            Button {
                onDismiss()
            } label: {
                Text("Got it!")
                    .font(.system(size: 20, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(red: 159/255, green: 192/255, blue: 122/255))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .padding(.top, 4)
        }
        .padding(28)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.15), radius: 20)
        .padding(.horizontal, 24)
    }
}

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        HintPopUpComponent(hintText: "This sign resembles a B") {}
    }
}
