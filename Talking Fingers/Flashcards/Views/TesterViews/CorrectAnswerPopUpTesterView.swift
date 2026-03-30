//
//  CorrectAnswerPopUpTesterView.swift
//  Talking Fingers
//
//  Created by Ria Sharma on 3/13/26.
//

import SwiftUI

struct CorrectAnswerPopUpTesterView: View {
    
    @State private var showPopup = false
    @State private var showDim = false
    
    var body: some View {
        ZStack {
            
            // ── Main screen ───────────────────────────────
            VStack(spacing: 20) {
                
                // Header
                HStack {
                    Button {
                        
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.black)
                    }
                    
                    ProgressView(value: 0.25)
                        .tint(.gray)
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                
                // Word
                Text("Hello")
                    .font(.system(size: 40, weight: .bold))
                
                
                // Image card
                ZStack(alignment: .top) {
                    
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: 0xF2F2F7))
                        .overlay(
                            Image(systemName: "person.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.gray)
                                .padding(40)
                        )
                    
                    
                    // Bookmark + lightbulb icons
                    HStack {
                        
                        Button {
                            
                        } label: {
                            Image(systemName: "bookmark")
                                .font(.system(size: 22))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Button {
                            
                        } label: {
                            Image(systemName: "lightbulb")
                                .font(.system(size: 22))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(12)
                }
                .frame(height: 320)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.3))
                )
                .padding(.horizontal)
                
                
                Spacer()
                
                
                // ── Answer choices ─────────────────────────
                
                Button {
                    showCorrectPopup()
                } label: {
                    Text("Hello")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal)
                
                
                Button {
                    
                } label: {
                    Text("Goodbye")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray)
                        )
                }
                .padding(.horizontal)
                
                
                Button {
                    
                } label: {
                    Text("Please")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray)
                        )
                }
                .padding(.horizontal)
                
            }
            .padding(.top)
            
            
            // ── Dim background ───────────────────────────
            if showDim {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(1)
            }
            
            
            // ── Popup ────────────────────────────────────
            if showPopup {
                VStack {
                    Spacer()
                    
                    CorrectAnswerPopUpComponent {
                        dismiss()
                    }
                }
                .transition(.move(edge: .bottom))
                .ignoresSafeArea(edges: .bottom)
                .zIndex(2)
            }
        }
    }
    
    
    // ── Show popup ─────────────────────────────────────
    
    func showCorrectPopup() {
        withAnimation(.easeInOut(duration: 0.32)) {
            showDim = true
            showPopup = true
        }
    }
    
    
    // ── Dismiss popup ──────────────────────────────────
    
    func dismiss() {
        withAnimation(.easeInOut(duration: 0.35)) {
            showPopup = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.35)) {
                showDim = false
            }
        }
    }
}

#Preview {
    CorrectAnswerPopUpTesterView()
}
