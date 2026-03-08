//
//  StartCardComponent.swift
//  Talking Fingers
//
//  Created by Na Hua on 3/2/26.
//
import SwiftUI
struct StartCardComponent: View {
    let modeTitle: String
    let topic: String
    let completed: Int
    let total: Int
    let imageName: String
    let primaryAction: () -> Void
    let secondaryAction: () -> Void
    
    var body: some View {
        VStack{
            VStack(spacing: 30){
                
                Image("greetingsIllustration")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 180)
                
                VStack(spacing: 8) {
                    Text("\(modeTitle):")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                    
                    Text(topic)
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                    
                    Text("\(completed)/\(total) Words Completed")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                ProgressView(value: Double(completed),
                             total: Double(total))
                    .tint(.gray)
                    .frame(maxWidth: .infinity)
                    .scaleEffect(x: 1, y: 2.5, anchor: .center)
                    .padding(.top, 8)
            }
            .padding(.top, 60)
            Spacer()
            VStack(spacing: 12) {
                PrimaryActionButton(title: "Let's Go", action: primaryAction)
                
                SecondaryActionButton(title: "Go Home", action: secondaryAction)
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal)
    }
}
#Preview {
    StartCardComponent(
        modeTitle: "Learn",
        topic: "Greetings",
        completed: 0,
        total: 12,
        imageName: "greetingsIllustration",
        primaryAction: {},
        secondaryAction: {}
    )
}
