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
                #if os(iOS)
                GIFView(gifFileName: gifFileName)
                    .frame(width: 300, height: 300)
                #endif
            } else {
                Text("No GIF available")
            }
            Text(flashcard.term.rawValue)
                .font(.title)
        }
    }
}
#Preview {
    let dummyID = UUID(uuidString: "GifDiagramTest") ?? UUID()
    FlashcardView(flashcard: FlashcardModel(
        term: .hello,
        id: dummyID,
        category: .commonObjects,
        gifFileName: "GifDiagramTest.gif"
    ))
}
