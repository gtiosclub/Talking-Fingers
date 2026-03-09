//
//  FlashcardView.swift
//  Talking Fingers
//
//  Created by Isha Jain on 1/29/26.
//
import SwiftUI
struct FlashcardView: View {
    var flashcard: FlashcardModel
    var body: some View {
        VStack {
            if let gifFileName = flashcard.gifFileName {
                GIFView(gifFileName: gifFileName)
                    .frame(width: 300, height: 300)
            } else {
                Text("No GIF available")
            }
            Text(flashcard.term)
                .font(.title)
        }
    }
}
#Preview {
    let dummyID = UUID(uuidString: "GifDiagramTest")!
    FlashcardView(flashcard: FlashcardModel(
        term: "Test",
        id: dummyID,
        category: "Test",
        gifFileName: "GifDiagramTest.gif"
    ))
}
