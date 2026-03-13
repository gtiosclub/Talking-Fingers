//
//  ModePopupView.swift
//  Talking Fingers
//
//  Created by Sanvi Adusumilli on 3/12/26.
//

import SwiftUI

struct ModePopupView: View {
    
    @Binding var isPresented: Bool
    @State private var animatePopup = false
    
    var onLearn: () -> Void
    var onExercise: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(animatePopup ? 0.3 : 0)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.25), value: animatePopup)
                .onTapGesture {
                    closePopup()
                }
            
            VStack(spacing: 20) {
                
                Text("Select Mode")
                    .font(.headline)
                
                HStack(spacing: 20) {
                    
                    Button {
                        onLearn()
                        closePopup()
                    } label: {
                        VStack {
                            Image(systemName: "brain.head.profile")
                                .font(.largeTitle)
                            
                            Text("Learn")
                                .font(.headline)
                        }
                        .frame(width: 120, height: 140)
                        .background(Color.green.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.green, lineWidth: 3)
                        )
                        .cornerRadius(16)
                    }
                    
                    Button {
                        onExercise()
                        closePopup()
                    } label: {
                        VStack {
                            Image(systemName: "hand.tap")
                                .font(.largeTitle)
                            
                            Text("Exercise")
                                .font(.headline)
                        }
                        .frame(width: 120, height: 140)
                        .background(Color.blue.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.blue, lineWidth: 3)
                        )
                        .cornerRadius(16)
                    }
                }
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding(.horizontal, 40)
            
            .scaleEffect(animatePopup ? 1 : 0.85)
            .opacity(animatePopup ? 1 : 0)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: animatePopup)
        }
        .onAppear {
            animatePopup = true
        }
    }
    
    private func closePopup() {
        animatePopup = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isPresented = false
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2)
            .ignoresSafeArea()
        Text("Home Page")
            .font(.largeTitle)
        
        ModePopupView(
            isPresented: .constant(true),
            onLearn: {print("learn tapped")},
            onExercise: {print("exercise tapped")}
        )
    }
}
