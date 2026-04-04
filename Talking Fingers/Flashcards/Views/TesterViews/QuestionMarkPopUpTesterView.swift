//
//  QuestionMarkPopUpTesterView.swift
//  Talking Fingers
//
//  Created by Ria Sharma on 3/13/26.
//

import SwiftUI

struct QuestionMarkPopUpTesterView: View {
    
    @State private var showQuestion = false
    @State private var showDim = false
    
    var body: some View {
        ZStack {
            
            // ── Main screen content ──────────────────────────────
            VStack(spacing: 20) {
                
                // Header
                HStack {
                    Button {
                        // exit placeholder
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.gray)
                    }
                    
                    ProgressView(value: 0.25)
                        .progressViewStyle(.linear)
                        .tint(.green)
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // Word
                Text("Hello")
                    .font(.system(size: 45, weight: .bold))
                
                // Image card with question mark button
                ZStack(alignment: .topTrailing) {
                    
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: 0xF2F2F7))
                        .overlay(
                            Image(systemName: "person.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(Color(hex: 0xC7C7CC))
                                .padding(40)
                        )
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.32)) {
                            showDim = true
                            showQuestion = true
                        }
                    } label: {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                            .padding(10)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                    .padding(12)
                }
                .frame(maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal)
                
                Spacer()
                
                // Main button placeholder
                Button {
                    // next action placeholder
                } label: {
                    Text("Next")
                        .font(.system(size: 20, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .padding(.horizontal)
            }
            .padding(.top)
            
            
            // ── Dim background ───────────────────────────────────
            if showDim {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        dismiss()
                    }
                    .zIndex(1)
            }
            
            
            // ── Popup sliding from bottom ────────────────────────
            if showQuestion {
                VStack {
                    Spacer()
                    
                    QuestionMarkPopUpComponent(
                        explanationText: "Are you sure you want to move on?"
                    ) {
                        dismiss()
                    }
                }
                .transition(.move(edge: .bottom))
                .ignoresSafeArea(edges: .bottom)
                .zIndex(2)
            }
        }
    }
    
    
    func dismiss() {
        withAnimation(.easeInOut(duration: 0.35)) {
            showQuestion = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.35)) {
                showDim = false
            }
        }
    }
}

#Preview {
    QuestionMarkPopUpTesterView()
}
