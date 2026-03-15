//
//  MultipleChoiceView.swift
//  Talking Fingers
//

import SwiftUI

struct MultipleChoiceView: View {
    @State private var vm: MultipleChoiceVM
    private var flashcardVM: FlashcardVM
    var onDismiss: () -> Void

    init(
        deck: [FlashcardModel],
        allFlashcards: [FlashcardModel],
        flashcardVM: FlashcardVM,
        onDismiss: @escaping () -> Void
    ) {
        _vm = State(initialValue: MultipleChoiceVM(deck: deck, allFlashcards: allFlashcards))
        self.flashcardVM = flashcardVM
        self.onDismiss = onDismiss
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal)
                    .padding(.top)

                imageArea
                    .padding(.horizontal)
                    .padding(.top, 16)

                masteryDebugLabel
                    .padding(.horizontal)
                    .padding(.top, 6)

                choicesList
                    .padding(.horizontal)
                    .padding(.top, 12)

                submitButton
                    .padding(.horizontal)
                    .padding(.top, 12)

                imageModePicker
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
            }

            if vm.showHint || vm.showResult {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .zIndex(1)
                    .onTapGesture {
                        if vm.showHint {
                            withAnimation(.easeInOut(duration: 0.32)) {
                                vm.showHint = false
                            }
                        }
                    }
            }

            if vm.showHint {
                HintPopUpComponent(hintText: "The sign for this word is: \(vm.card.term)") {
                    withAnimation(.easeInOut(duration: 0.32)) {
                        vm.showHint = false
                    }
                }
                .transition(.move(edge: .bottom))
                .zIndex(2)
            }

            if vm.showResult {
                resultPopup
                    .transition(.move(edge: .bottom))
                    .zIndex(2)
            }
        }
        .animation(.easeInOut(duration: 0.32), value: vm.showHint)
        .animation(.easeInOut(duration: 0.35), value: vm.showResult)
        .navigationBarHidden(true)
        .onChange(of: vm.sessionComplete) { _, complete in
            if complete { onDismiss() }
        }
    }
}

// MARK: - Subviews

extension MultipleChoiceView {

    var header: some View {
        HStack(spacing: 12) {
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.gray)
            }

            Button {
                vm.card.starred.toggle()
            } label: {
                Image(systemName: vm.card.starred ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 20))
                    .foregroundStyle(.primary)
            }

            ProgressView(value: vm.deckProgress)
                .progressViewStyle(.linear)
                .frame(maxWidth: .infinity)

            Button {
                withAnimation(.easeInOut(duration: 0.32)) {
                    vm.showHint = true
                }
            } label: {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(vm.showHint ? .yellow : .gray)
            }
        }
    }

    var imageArea: some View {
        Group {
            switch vm.imageMode {
            case .flashcard:
                gifView
            case .camera:
                cameraPlaceholder
            case .both:
                HStack(spacing: 8) {
                    gifView
                    cameraPlaceholder
                }
            }
        }
        .frame(height: 200)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }

    private var gifView: some View {
        Group {
            if let fileName = vm.card.gifFileName {
                GIFView(gifFileName: fileName)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(.gray.opacity(0.35))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var cameraPlaceholder: some View {
        ZStack {
            Color.black.opacity(0.05)
            VStack(spacing: 8) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.gray.opacity(0.45))
                Text("Camera")
                    .font(.system(size: 12))
                    .foregroundStyle(.gray.opacity(0.5))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Debug label showing the current card's mastery level.
    var masteryDebugLabel: some View {
        Text("Mastery: \(vm.card.progress.rawValue)")
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    var choicesList: some View {
        VStack(spacing: 10) {
            ForEach(vm.choices, id: \.self) { choice in
                AnswerOptionRow(text: choice, state: rowState(for: choice)) {
                    vm.selectAnswer(choice)
                }
            }
        }
    }

    var submitButton: some View {
        let canSubmit = vm.selectedAnswer != nil && !vm.hasSubmitted
        return Button {
            withAnimation {
                vm.submit()
                flashcardVM.handleAnswer(for: vm.card, correct: vm.isCorrect)
            }
        } label: {
            Text("Submit")
                .font(.system(size: 18, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canSubmit ? Color.black.opacity(0.82) : Color.gray.opacity(0.25))
                .foregroundStyle(canSubmit ? Color.white : Color.gray)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!canSubmit)
        .animation(.easeInOut(duration: 0.2), value: canSubmit)
    }

    var imageModePicker: some View {
        Picker(
            "Image Mode",
            selection: Binding(get: { vm.imageMode }, set: { vm.imageMode = $0 })
        ) {
            ForEach(ImageMode.allCases, id: \.self) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    var resultPopup: some View {
        if vm.isCorrect {
            CorrectAnswerPopUpComponent {
                withAnimation(.easeInOut(duration: 0.32)) {
                    vm.showResult = false
                }
                vm.nextCard()
            }
        } else {
            IncorrectAnswerPopUp(correctAnswer: vm.card.term) {
                withAnimation(.easeInOut(duration: 0.32)) {
                    vm.showResult = false
                    vm.selectedAnswer = nil
                    vm.hasSubmitted = false
                }
            }
        }
    }

    private func rowState(for choice: String) -> AnswerOptionRow.RowState {
        guard vm.hasSubmitted else {
            return vm.selectedAnswer == choice ? .selected : .unselected
        }
        if choice == vm.card.term { return .correct }
        if choice == vm.selectedAnswer { return .incorrect }
        return .unselected
    }
}

// MARK: - Answer Option Row

struct AnswerOptionRow: View {
    enum RowState: Equatable {
        case unselected, selected, correct, incorrect
    }

    let text: String
    let state: RowState
    let action: () -> Void

    private var backgroundColor: Color {
        switch state {
        case .unselected: return .white
        case .selected:   return .black
        case .correct:    return Color(red: 0.18, green: 0.68, blue: 0.28)
        case .incorrect:  return Color(red: 0.82, green: 0.18, blue: 0.18)
        }
    }

    private var textColor: Color {
        state == .unselected ? .primary : .white
    }

    private var borderColor: Color {
        switch state {
        case .unselected: return Color.gray.opacity(0.35)
        case .selected:   return .black
        case .correct:    return Color(red: 0.18, green: 0.68, blue: 0.28)
        case .incorrect:  return Color(red: 0.82, green: 0.18, blue: 0.18)
        }
    }

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(backgroundColor)
                .foregroundStyle(textColor)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(borderColor, lineWidth: 1.5)
                )
        }
        .animation(.easeInOut(duration: 0.15), value: state)
    }
}

// MARK: - Incorrect Answer Popup

struct IncorrectAnswerPopUp: View {
    let correctAnswer: String
    let onTryAgain: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 5)

            Text("Not Quite!")
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)

            Text("The correct answer is:")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)

            Text(correctAnswer)
                .font(.system(size: 22, weight: .bold))

            Button(action: onTryAgain) {
                Text("Try Again")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.2, green: 0.2, blue: 0.2))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Spacer().frame(height: 5)
        }
        .padding(28)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 20)
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
}

// MARK: - Preview

#Preview {
    let cards = FlashcardVM.dummyFlashcards
    let testCard = FlashcardModel(
        term: "WHO",
        id: UUID(),
        lastSucceeded: nil,
        starred: false,
        progress: .learning,
        category: TermCategory.personalInformation.rawValue
    )
    MultipleChoiceView(
        deck: [testCard] + cards,
        allFlashcards: cards,
        flashcardVM: FlashcardVM(),
        onDismiss: {}
    )
}
