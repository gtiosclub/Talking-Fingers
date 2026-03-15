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
                .font(.system(size: 27, weight: .bold))
                .padding(10)

            Text(hintText)
                .font(.system(size: 23, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
            Button {
                onDismiss()
            } label: {
                Text("Got it!")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.2, green: 0.2, blue: 0.2))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 4)
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
    HintPopUpComponent(hintText: "This sign resembles a B shape") {}
}
 
