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
                    .font(.title)
                    .fontWeight(.semibold)
                
                HStack(spacing: 10) {
                    
                    Button {
                        onLearn()
                        closePopup()
                    } label: {
                        VStack {
                            Image("learnModeIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 100)
                            
                            Text("Learn")
                                .font(.title2)
                                .foregroundStyle(.black)
                        }
                        .frame(maxWidth: .infinity, minHeight: 220)
                        .background(Color(red: 0.678, green: 0.808, blue: 0.561, opacity: 0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color(red: 0.678, green: 0.95, blue: 0.561), lineWidth: 1.5)
                        )
                        .cornerRadius(24)
                    }
                    
                    Button {
                        onExercise()
                        closePopup()
                    } label: {
                        VStack {
                            Image("exerciseModeIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 100)
                            
                            Text("Exercise")
                                .font(.title2)
                                .foregroundStyle(.black)
                        }
                        .frame(maxWidth: .infinity, minHeight: 220)
                        .background(Color(red: 0.663, green: 0.808, blue: 0.985, opacity: 0.4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color(red: 0.663, green: 0.85, blue: 0.925), lineWidth: 1.5)
                        )
                        .cornerRadius(24)
                    }
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding(.horizontal, 40)
            .frame(maxWidth: 560)
            
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
