//
//  AISentenceSigningViewMacOS.swift
//  Talking Fingers
//
//  Created by Judy Hsu on 2/23/26.
//

import SwiftUI

struct AISentenceSigningViewMacOS: View {
    // Accepts the existing data model
    let sentenceModel: AISentenceModel
    
    // Mock state for the progress bar (can be dynamically calculated based on sentenceModel.score later)
    @State private var progress: Double = 0.3
    @State private var showGloss: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            // 1. Top progress bar
            CustomProgressBarMacOS(progress: progress)
                .padding(.top, 40)
            
            // 2. Subtitle
            Text("New sentence!")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 48) {
                Text(sentenceModel.sentence)
                    .font(.system(size: 56, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(8)
                
                Button(action: {
                    showGloss.toggle()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: showGloss ? "eye.fill" : "eye")
                            .font(.system(size: 16))
                        Text(showGloss ? "Hide gloss" : "Tap to reveal gloss!")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .center)
                
                // Show gloss when revealed
                if showGloss {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ASL Gloss:")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        Text(sentenceModel.gloss.joined(separator: " → "))
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .transition(.opacity.combined(with: .scale))
                }
            }
            
            Spacer()
            
            // 4. Bottom button row
            HStack(spacing: 16) {
                // Skip button (optional, can be added if needed)
                Button(action: {
                    print("Skip tapped")
                }) {
                    Text("Skip")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
                
                // Continue button
                ContinueButtonMacOS()
            }
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 80)
        .frame(minWidth: 800, minHeight: 600)
        .animation(.easeInOut(duration: 0.3), value: showGloss)
    }
}

// MARK: - Subcomponents for macOS

struct CustomProgressBarMacOS: View {
    var progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .frame(width: geometry.size.width, height: 12)
                    .foregroundColor(.gray.opacity(0.2))
                
                // Progress fill
                RoundedRectangle(cornerRadius: 8)
                    .frame(width: min(CGFloat(progress) * geometry.size.width, geometry.size.width), height: 12)
                    .foregroundColor(.accentColor)
            }
        }
        .frame(height: 12)
    }
}

struct ContinueButtonMacOS: View {
    var body: some View {
        Button(action: {
            // Placeholder: Does not do anything for now
            print("Continue tapped")
        }) {
            Text("Continue")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.accentColor)
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    // Construct test data that fits the project logic, including gloss breakdown and dummy scores
    let sampleData = AISentenceModel(
        sentence: "I didn't go to the store yesterday.",
        score: nil,
        practiceType: .words,
        gloss: ["I", "NOT", "GO", "STORE", "YESTERDAY"],
        completed: false
    )
    
    AISentenceSigningViewMacOS(sentenceModel: sampleData)
        .frame(width: 1000, height: 700)
}
