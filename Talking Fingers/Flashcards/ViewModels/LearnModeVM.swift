//
//  LearnModeVM.swift
//  Talking Fingers
//
//  Created by Sanvi Adusumilli on 3/8/26.
//

import SwiftUI
import Combine

class LearnModeVM: ObservableObject {

    enum LearnState {
        case initial
        case practicing
        case showingHint
    }

    @Published var state: LearnState = .initial
    
    var onNextCard: (() -> Void)? = nil

    let flashcard: FlashcardModel
    
    private let tfGreen = Color(red: 159/255, green: 192/255, blue: 122/255)
    
    init(flashcard: FlashcardModel) {
        self.flashcard = flashcard
    }

    var word: String {
        flashcard.term.rawValue
    }

    var signImageName: String {
        "dummySign"
        // later: flashcard.gifFileName
    }

    var cameraImageName: String {
        "dummyCamera"
    }

    var buttonText: String {
        state == .initial ? "Try Signing" : "Next Word"
    }

    var buttonColor: Color {
        tfGreen
    }

    var bulbColor: Color {
        state == .showingHint ? .orange : .gray.opacity(0.5)
    }

    var showHintButton: Bool {
        state != .initial
    }

    var showingCamera: Bool {
        state == .practicing || state == .showingHint
    }

    var showingHint: Bool {
        state == .showingHint
    }

    func tapHint() {
        guard state != .initial else { return }

        if state == .practicing {
            state = .showingHint
        } else if state == .showingHint {
            state = .practicing
        }
    }

    func tapMainButton() {
        switch state {
        case .initial:
            state = .practicing
        case .practicing, .showingHint:
            nextWord()
        }
    }

    func nextWord() {
        print("next word")
        // reset for next flashcard later
        state = .initial
        onNextCard?()
    }
}
