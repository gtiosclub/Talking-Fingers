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

    let flashcard: FlashcardModel

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
        state == .initial ? "Try" : "Next Word"
    }

    var buttonColor: Color {
        state == .initial ? .gray : .blue
    }

    var bulbColor: Color {
        state == .showingHint ? .yellow : .gray
    }

    var showHintButton: Bool {
        state != .initial
    }

    var showingCamera: Bool {
        state == .practicing
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
    }
}
