//
//  HintPopUpTesterView.swift
//  Talking Fingers
//
//  Created by Ria Sharma on 3/13/26.
//

import SwiftUI
 
struct HintPopUpTesterView: View {
    @State private var showHint = false
    @State private var showDim = false
    
    var body: some View {
        ZStack {
            // ── Main screen content ──────────────────────────────
            VStack(spacing: 20) {
                
                // Header
                HStack {
                    Button {
                        // exit (tester only)
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
                
                // Image card with lightbulb button
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 16)
//                        .fill(Color(.systemGray6))
                        .overlay(
                            Image(systemName: "person.fill")
                                .resizable()
                                .scaledToFit()
//                                .foregroundColor(Color(.systemGray3))
                                .padding(40)
                        )
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.32)) {
                            showDim = true
                            showHint = true
                        }
                    } label: {
                        Image(systemName: "lightbulb.fill")
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
                
                // Main button
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
            
            // Dim overlap once hint is pushed.
            if showDim {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        dismiss()
                    }
                    .transition(.opacity)
                    .zIndex(1)
            }
            
            // Popup sliding up from bottom
            if showHint {
                VStack {
                    Spacer()
                    HintPopUpComponent(hintText: "This sign resembles a B shape") {
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
            showHint = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.35)) {
                    showDim = false
                }
            }
    }
    
}
 
#Preview {
    HintPopUpTesterView()
}
