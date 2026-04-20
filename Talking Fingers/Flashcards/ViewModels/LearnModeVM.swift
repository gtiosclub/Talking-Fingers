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
    @Published private(set) var hasGoodConfidence: Bool = false
    
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
        switch state {
        case .initial:
            return "Try Signing"
        case .practicing, .showingHint:
            return hasGoodConfidence ? "Next Word" : "Keep Signing"
        }
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
    
    var canAdvanceToNextWord: Bool {
        state == .practicing || state == .showingHint ? hasGoodConfidence : true
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
            guard hasGoodConfidence else { return }
            nextWord()
        }
    }
    
    func updateConfidence(_: Double) {
        // Vision pipeline already decides when the user reached "Good";
        // this callback is treated as a pass signal.
        if !hasGoodConfidence { hasGoodConfidence = true }
    }

    func nextWord() {
        print("next word")
        // reset for next flashcard later
        state = .initial
        hasGoodConfidence = false
        onNextCard?()
    }
}
