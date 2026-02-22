//
//  AISentenceView.swift
//  Talking Fingers
//
//  Created by Aimee on 2/22/26.
//

import SwiftUI

struct AISentenceView: View {
    // Accepts the existing data model
    let sentenceModel: AISentenceModel
    
    // Mock state for the progress bar (can be dynamically calculated based on sentenceModel.score later)
    @State private var progress: Double = 0.3
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // 1. Top progress bar
            CustomProgressBar(progress: progress)
                .padding(.top, 20)
            
            // 2. Subtitle
            Text("New sentence!")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.gray)
            
            Spacer()
            // 3. Core sentence display & Gloss hint
            VStack(alignment: .leading, spacing: 40) {
                // The main sentence
                Text(sentenceModel.sentence)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                
                // The reveal gloss hint
                HStack(spacing: 6) {
                    Image(systemName: "eye")
                    Text("Tap to reveal gloss!")
                }
                .font(.subheadline)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            
            Spacer()
            
            // 4. Bottom CONTINUE button
            ContinueButton()
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 30)
    }
}

// MARK: - Subcomponents
struct CustomProgressBar: View {
    var progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: 16)
                    .opacity(0.3)
                    .foregroundColor(.gray)
                
                Rectangle()
                    .frame(width: min(CGFloat(progress) * geometry.size.width, geometry.size.width), height: 16)
                    .foregroundColor(.gray)
            }
        }
        .frame(height: 16)
    }
}

struct ContinueButton: View {
    var body: some View {
        Button(action: {
            // Placeholder: Does not do anything for now
            print("Continue tapped")
        }) {
            Text("Continue")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.gray)
                .cornerRadius(8)
        }
    }
}

// MARK: - Preview
#Preview {
    // Construct test data that fits the project logic, including gloss breakdown and dummy scores
    let sampleData = AISentenceModel(
        sentence: "I didn’t go to the store yesterday.",
        score: [0, 0, 0, 0, 0, 0, 0],
        practiceType: .words,
        difficulty: .medium,
        gloss: ["I", "NOT", "GO", "STORE", "YESTERDAY"]
    )
    
    AISentenceView(sentenceModel: sampleData)
}
