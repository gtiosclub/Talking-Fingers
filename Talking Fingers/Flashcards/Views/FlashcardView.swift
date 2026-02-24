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
    let dummyID = UUID(uuidString: "a34a6e11-0fa6-4b52-abad-0454bd74ea5a")!
    FlashcardView(flashcard: FlashcardModel(
        term: "Test",
        id: dummyID,
        category: "Test",
        gifFileName: "a34a6e11-0fa6-4b52-abad-0454bd74ea5a.gif"
    ))
}
