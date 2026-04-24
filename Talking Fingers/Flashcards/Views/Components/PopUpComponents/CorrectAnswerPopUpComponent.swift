//
//  CorrectAnswerPopUpComponent.swift
//  Talking Fingers
//
//  Created by Ria Sharma on 3/13/26.
//

import SwiftUI

struct CorrectAnswerPopUpComponent: View {
    
    var onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 25) {
            
            Spacer()
                .frame(height: 5)
            
            Text("Great Job!")
                .font(.jakarta(size: 28))
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            Spacer()
                .frame(height: 2)
            Button {
                onNext()
            } label: {
                Text("Next Word")
                    .font(.jakarta(size: 18))
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.2, green: 0.2, blue: 0.2))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Spacer()
                .frame(height: 5)
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
    CorrectAnswerPopUpComponent {
        print("Next word tapped")
    }
}
