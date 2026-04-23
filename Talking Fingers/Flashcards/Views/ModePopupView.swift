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
    
    var isExerciseUnlocked: Bool = true
    var onLearn: () -> Void
    var onExercise: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(animatePopup ? 0.3 : 0)
                .ignoresSafeArea()
                .onTapGesture {
                    closePopup()
                }
            
            VStack(spacing: 20) {
                
                Text("Select Mode")
                    .font(.jakartaTitle)
                    .fontWeight(.semibold)
                
#if os(macOS)
                VStack(spacing: 16) {
                    Button {
                        onLearn()
                        closePopup()
                    } label: {
                        HStack(spacing: 16) {
                            Image("SentencesComprehendFlowerFull")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 80)
                            
                            Text("Learn")
                                .font(.jakartaTitle)
                                .foregroundStyle(.black)
                            
                            Spacer()
                        }
//                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity, minHeight: 110)
                        .background(Color(red: 0.678, green: 0.808, blue: 0.561, opacity: 0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color(red: 0.678, green: 0.95, blue: 0.561), lineWidth: 1.5)
                        )
                        .cornerRadius(24)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        onExercise()
                        closePopup()
                    } label: {
                        HStack(spacing: 16) {
                            Image("SentencesSignFlowerFull")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 80)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Exercise")
                                    .font(.jakartaTitle)
                                    .foregroundStyle(.black)
                                
                                if !isExerciseUnlocked {
                                    Text("Complete Learn first")
                                        .font(.jakartaCaption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
//                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity, minHeight: 110)
                        .background(Color(red: 0.663, green: 0.808, blue: 0.985, opacity: isExerciseUnlocked ? 0.4 : 0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color(red: 0.663, green: 0.85, blue: 0.925).opacity(isExerciseUnlocked ? 1.0 : 0.5), lineWidth: 1.5)
                        )
                        .cornerRadius(24)
                    }
                    .buttonStyle(.plain)
                    .disabled(!isExerciseUnlocked)
                }
#else
                HStack(spacing: 10) {
                    
                    Button {
                        onLearn()
                        closePopup()
                    } label: {
                        VStack {
                            Image("SentencesComprehendFlowerFull")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 100)
                            
                            Text("Learn")
                                .font(.jakartaTitle2)
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
                            Image("SentencesSignFlowerFull")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 100)
                            
                            Text("Exercise")
                                .font(.jakartaTitle2)
                                .foregroundStyle(.black)
                            
                            if !isExerciseUnlocked {
                                Text("Complete Learn first")
                                    .font(.jakartaCaption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 220)
                        .background(Color(red: 0.663, green: 0.808, blue: 0.985, opacity: isExerciseUnlocked ? 0.4 : 0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color(red: 0.663, green: 0.85, blue: 0.925).opacity(isExerciseUnlocked ? 1.0 : 0.5), lineWidth: 1.5)
                        )
                        .cornerRadius(24)
                    }
                    .disabled(!isExerciseUnlocked)
                }
#endif
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
            .font(.jakartaLargeTitle)
        
        ModePopupView(
            isPresented: .constant(true),
            isExerciseUnlocked: false,
            onLearn: {print("learn tapped")},
            onExercise: {print("exercise tapped")}
        )
    }
}
