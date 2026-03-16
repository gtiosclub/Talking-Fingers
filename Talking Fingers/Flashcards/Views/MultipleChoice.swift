//
//  MultipleChoice.swift
//  Talking Fingers
//
//  Created by Isha Jain on 3/16/26.
//

import SwiftUI

struct MultipleChoice: View {

    // MARK: - Configuration
    let question: String
    let imageName: String          // SF Symbol or asset name for the sign illustration
    let options: [String]
    let correctAnswer: String
    var explanationText: String = "People often confuse this sign with Goodbye because..."

    // Spaced repetition integration
    let currentCard: FlashcardModel
    var onNext: (FlashcardModel) -> Void = { _ in }

    // Progress (0.0 – 1.0) — passed in by the caller to reflect real progress
    var progress: Double

    // MARK: - Environment (Observation framework)
    @Environment(FlashcardVM.self) private var flashcardVM
    @Environment(\.dismiss) private var dismiss

    // MARK: - State
    @State private var selectedAnswer: String? = nil
    @State private var isSaved: Bool = false
    @State private var showHintPopup: Bool = false
    @State private var showCorrectPopup: Bool = false
    @State private var showIncorrectPopup: Bool = false

    // MARK: - Brand Colors
    private let tfGreen = Color(red: 159/255, green: 192/255, blue: 122/255)
    private let tfGreenText = Color(red: 82/255, green: 106/255, blue: 54/255)

    // MARK: - Body
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Top bar ────────────────────────────────────────────────
                topBar

                // ── Card ───────────────────────────────────────────────────
                ScrollView {
                    VStack(spacing: 20) {
                        questionCard
                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    // Ensure content can scroll above the bottom button area
                    .padding(.bottom, 120)
                }

                // ── Submit (bottom area) + private tiny level badge ───────
                VStack(spacing: 6) {
                    submitButton
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    // Tiny, muted badge bottom-left so only you notice it
                    HStack {
                        tinyProgressBadge
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                }
                .background(
                    Color(.systemBackground)
                        .overlay(
                            Rectangle()
                                .fill(Color.black.opacity(0.05))
                                .frame(height: 0.5)
                                .frame(maxHeight: .infinity, alignment: .top)
                        )
                )
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
        // Hint popup like LearnModeView
        .popupHost(isPresented: $showHintPopup) {
            HintPopUpComponent(
                hintText: "This sign resembles a B shape"
            ) {
                showHintPopup = false
            }
        }
        // Correct answer popup
        .popupHost(isPresented: $showCorrectPopup) {
            CorrectResultPopUpComponent(
                message: explanationText,
                onNext: {
                    advanceToNextCard()
                }
            )
        }
        // Incorrect answer popup
        .popupHost(isPresented: $showIncorrectPopup) {
            IncorrectResultPopUpComponent(
                message: explanationText,
                onNext: {
                    advanceToNextCard()
                }
            )
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        VStack(spacing: 8) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Label("Leave", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            .padding(.horizontal, 20)
            .padding(.top, 12)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                    Capsule()
                        .fill(Color.blue)
                        .frame(width: geo.size.width * CGFloat(progress), height: 6)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Question Card
    private var questionCard: some View {
        VStack(spacing: 16) {

            // Save / Hint row
            HStack {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isSaved.toggle()
                    }
                } label: {
                    Label(isSaved ? "Saved" : "Save",
                          systemImage: isSaved ? "bookmark.fill" : "bookmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(tfGreenText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(tfGreen)
                        )
                }

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showHintPopup = true
                    }
                } label: {
                    Image(systemName: "lightbulb")
                        .font(.title3)
                        .foregroundColor(Color(red: 239/255, green: 190/255, blue: 85/255))
                        .padding(10)
                        .background(
                            Circle()
                                .fill(Color.orange.opacity(0.15))
                        )
                }
            }

            // Sign illustration placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .frame(height: 180)
                    .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)

                if imageName.isEmpty {
                    // Fallback sketch-style placeholder
                    Image(systemName: "hand.wave.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                        .foregroundColor(.black.opacity(0.8))
                } else {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 160)
                        .padding(12)
                }
            }

            // Question text (if desired)
            if !question.isEmpty {
                Text(question)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Answer options
            VStack(spacing: 10) {
                ForEach(options, id: \.self) { option in
                    optionRow(option)
                }
            }

            // Add a little spacing at the end of the card
            Spacer(minLength: 8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.blue.opacity(0.25), lineWidth: 1.5)
                )
        )
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    // Tiny, subtle badge for internal use only (bottom-left under submit)
    private var tinyProgressBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color(for: currentCard.progress))
                .frame(width: 6, height: 6)
            Text("Level: \(title(for: currentCard.progress))")
                .font(.caption2)
                .foregroundColor(Color.secondary.opacity(0.7))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6).opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.black.opacity(0.05), lineWidth: 0.5)
        )
        .accessibilityHidden(true)
    }

    private func title(for progress: ProgressType) -> String {
        switch progress {
        case .new: return "New"
        case .learning: return "Learning"
        case .polishing: return "Polishing"
        case .mastered: return "Mastered"
        }
    }

    private func color(for progress: ProgressType) -> Color {
        switch progress {
        case .new: return .gray
        case .learning: return .orange
        case .polishing: return .blue
        case .mastered: return .green
        }
        }
    // MARK: - Option Row
    @ViewBuilder
    private func optionRow(_ option: String) -> some View {
        let isSelected = selectedAnswer == option
        let isCorrectOption = option == correctAnswer

        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedAnswer = option
            }
        } label: {
            HStack {
                Text(isCorrectOption ? "\(option) *" : option)
                    .font(.body.weight(isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .black : Color(.label))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color(red: 1, green: 0.85, blue: 0.5) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.orange.opacity(0.6) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Submit Button
    private var submitButton: some View {
        Button {
            handleSubmission()
        } label: {
            Text("Submit")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(tfGreen)
                )
        }
        .disabled(selectedAnswer == nil)
        .animation(.easeInOut(duration: 0.2), value: selectedAnswer)
    }

    private func handleSubmission() {
        guard let selected = selectedAnswer else { return }
        let isCorrect = (selected == correctAnswer)

        // Update spaced repetition progress
        flashcardVM.handleAnswer(for: currentCard, correct: isCorrect)

        if isCorrect {
            withAnimation(.easeInOut(duration: 0.25)) {
                showCorrectPopup = true
            }
        } else {
            withAnimation(.easeInOut(duration: 0.25)) {
                showIncorrectPopup = true
            }
        }
    }

    private func advanceToNextCard() {
        // Close popups
        showCorrectPopup = false
        showIncorrectPopup = false

        // Ask VM for next card
        if let next = flashcardVM.nextCard() {
            // Reset selection state
            selectedAnswer = nil
            isSaved = false
            // Delegate navigation/presentation to parent
            onNext(next)
        } else {
            // No more cards — dismiss or keep current view
            dismiss()
        }
    }
}

// MARK: - Popups (local components to match screenshot)

private struct CorrectResultPopUpComponent: View {
    var message: String
    var onNext: () -> Void

    var body: some View {
        ResultCard(
            title: "Great Job!",
            titleColor: Color(red: 239/255, green: 190/255, blue: 85/255),
            message: message,
            buttonTitle: "Next Question",
            onNext: onNext
        )
    }
}

private struct IncorrectResultPopUpComponent: View {
    var message: String
    var onNext: () -> Void

    var body: some View {
        ResultCard(
            title: "Not Quite...",
            titleColor: Color(red: 239/255, green: 190/255, blue: 85/255),
            message: message,
            buttonTitle: "Next Question",
            onNext: onNext
        )
    }
}

private struct ResultCard: View {
    let title: String
    let titleColor: Color
    let message: String
    let buttonTitle: String
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(titleColor)
                .padding(.top, 8)

            Text(message)
                .font(.system(size: 16, weight: .regular))
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .padding(.horizontal, 8)

            Button {
                onNext()
            } label: {
                Text(buttonTitle)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(red: 159/255, green: 192/255, blue: 122/255))
                    .foregroundColor(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 4)
        }
        .padding(24)
        .frame(maxWidth: 560)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 20)
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
}

// MARK: - Dummy data + SR helpers (unchanged)

private func daysAgo(_ days: Int) -> Date {
    Calendar.current.date(byAdding: .day, value: -days, to: Date())!
}

private func makeDummyFlashcards() -> [FlashcardModel] {
    var cards: [FlashcardModel] = []

    cards += [
        FlashcardModel(term: "Hello", id: UUID(), lastSucceeded: nil, starred: false, progress: .new, category: "Greetings"),
        FlashcardModel(term: "Goodbye", id: UUID(), lastSucceeded: daysAgo(10), starred: false, progress: .learning, category: "Greetings"),
        FlashcardModel(term: "Thank You", id: UUID(), lastSucceeded: daysAgo(3), starred: true, progress: .polishing, category: "Greetings"),
        FlashcardModel(term: "Please", id: UUID(), lastSucceeded: daysAgo(1), starred: false, progress: .mastered, category: "Greetings"),
        FlashcardModel(term: "Nice To Meet You", id: UUID(), lastSucceeded: daysAgo(20), starred: false, progress: .learning, category: "Greetings"),
        FlashcardModel(term: "Good Morning", id: UUID(), lastSucceeded: daysAgo(5), starred: false, progress: .polishing, category: "Greetings"),
        FlashcardModel(term: "Good Night", id: UUID(), lastSucceeded: daysAgo(1), starred: false, progress: .mastered, category: "Greetings"),
        FlashcardModel(term: "See You", id: UUID(), lastSucceeded: nil, starred: false, progress: .new, category: "Greetings"),
    ]

    cards += [
        FlashcardModel(term: "One", id: UUID(), lastSucceeded: daysAgo(8), starred: false, progress: .learning, category: "Numbers"),
        FlashcardModel(term: "Two", id: UUID(), lastSucceeded: daysAgo(2), starred: false, progress: .polishing, category: "Numbers"),
        FlashcardModel(term: "Three", id: UUID(), lastSucceeded: daysAgo(5), starred: true, progress: .polishing, category: "Numbers"),
        FlashcardModel(term: "Four", id: UUID(), lastSucceeded: daysAgo(1), starred: false, progress: .mastered, category: "Numbers"),
        FlashcardModel(term: "Five", id: UUID(), lastSucceeded: nil, starred: false, progress: .new, category: "Numbers"),
        FlashcardModel(term: "Six", id: UUID(), lastSucceeded: daysAgo(15), starred: false, progress: .learning, category: "Numbers"),
        FlashcardModel(term: "Seven", id: UUID(), lastSucceeded: daysAgo(3), starred: false, progress: .polishing, category: "Numbers"),
        FlashcardModel(term: "Eight", id: UUID(), lastSucceeded: daysAgo(1), starred: false, progress: .mastered, category: "Numbers"),
        FlashcardModel(term: "Nine", id: UUID(), lastSucceeded: nil, starred: false, progress: .new, category: "Numbers"),
        FlashcardModel(term: "Ten", id: UUID(), lastSucceeded: daysAgo(30), starred: false, progress: .learning, category: "Numbers"),
    ]

    cards += [
        FlashcardModel(term: "Red", id: UUID(), lastSucceeded: daysAgo(1), starred: false, progress: .mastered, category: "Colors"),
        FlashcardModel(term: "Blue", id: UUID(), lastSucceeded: daysAgo(2), starred: false, progress: .mastered, category: "Colors"),
        FlashcardModel(term: "Green", id: UUID(), lastSucceeded: daysAgo(3), starred: true, progress: .polishing, category: "Colors"),
        FlashcardModel(term: "Yellow", id: UUID(), lastSucceeded: daysAgo(1), starred: false, progress: .mastered, category: "Colors"),
        FlashcardModel(term: "Orange", id: UUID(), lastSucceeded: daysAgo(12), starred: false, progress: .learning, category: "Colors"),
        FlashcardModel(term: "Purple", id: UUID(), lastSucceeded: nil, starred: false, progress: .new, category: "Colors"),
        FlashcardModel(term: "Black", id: UUID(), lastSucceeded: daysAgo(6), starred: false, progress: .polishing, category: "Colors"),
        FlashcardModel(term: "White", id: UUID(), lastSucceeded: nil, starred: false, progress: .new, category: "Colors"),
    ]

    cards += [
        FlashcardModel(term: "Mother", id: UUID(), lastSucceeded: daysAgo(9), starred: false, progress: .learning, category: "Family"),
        FlashcardModel(term: "Father", id: UUID(), lastSucceeded: daysAgo(4), starred: false, progress: .polishing, category: "Family"),
        FlashcardModel(term: "Brother", id: UUID(), lastSucceeded: nil, starred: false, progress: .new, category: "Family"),
        FlashcardModel(term: "Sister", id: UUID(), lastSucceeded: daysAgo(1), starred: false, progress: .mastered, category: "Family"),
        FlashcardModel(term: "Grandmother", id: UUID(), lastSucceeded: daysAgo(20), starred: false, progress: .learning, category: "Family"),
        FlashcardModel(term: "Grandfather", id: UUID(), lastSucceeded: daysAgo(2), starred: false, progress: .polishing, category: "Family"),
    ]

    cards += [
        FlashcardModel(term: "Eat", id: UUID(), lastSucceeded: daysAgo(7), starred: false, progress: .learning, category: "Verbs"),
        FlashcardModel(term: "Drink", id: UUID(), lastSucceeded: daysAgo(3), starred: false, progress: .polishing, category: "Verbs"),
        FlashcardModel(term: "Go", id: UUID(), lastSucceeded: daysAgo(14), starred: false, progress: .learning, category: "Verbs"),
        FlashcardModel(term: "Come", id: UUID(), lastSucceeded: nil, starred: false, progress: .new, category: "Verbs"),
        FlashcardModel(term: "Want", id: UUID(), lastSucceeded: daysAgo(1), starred: false, progress: .mastered, category: "Verbs"),
        FlashcardModel(term: "Need", id: UUID(), lastSucceeded: daysAgo(5), starred: false, progress: .polishing, category: "Verbs"),
        FlashcardModel(term: "Like", id: UUID(), lastSucceeded: nil, starred: false, progress: .new, category: "Verbs"),
    ]

    return cards
}

private func optionsFor(card: FlashcardModel, from pool: [FlashcardModel], count: Int = 4) -> [String] {
    var distractors = pool
        .filter { $0.id != card.id }
        .map { $0.term }
        .shuffled()
        .prefix(max(0, count - 1))

    var opts = Array(distractors)
    opts.append(card.term)
    // Ensure unique and random order
    return Array(Set(opts)).shuffled()
}

struct MultipleChoiceSRTester: View {
    @State private var vm = FlashcardVM()
    @State private var current: FlashcardModel?
    @State private var currentOptions: [String] = []
    @State private var completed: Int = 0
    let target = 7

    var body: some View {
        Group {
            if let current {
                MultipleChoice(
                    question: "What sign is being shown?",
                    imageName: "greetingsIllustration",
                    options: currentOptions,
                    correctAnswer: current.term,
                    explanationText: "People often confuse this sign with similar motions. Focus on handshape and movement.",
                    currentCard: current,
                    onNext: { next in
                        completed += 1
                        self.current = next
                        self.currentOptions = optionsFor(card: next, from: vm.flashcards)
                    },
                    progress: Double(completed) / Double(target)
                )
                .environment(vm)
            } else {
                ProgressView("Loading cards...")
                    .onAppear {
                        seedAndStart()
                    }
            }
        }
        .padding()
    }

    private func seedAndStart() {
        vm.flashcards = makeDummyFlashcards()
        if let first = vm.nextCard() {
            current = first
            currentOptions = optionsFor(card: first, from: vm.flashcards)
        }
    }
}

// MARK: - Previews

#Preview("Single Card (original)") {
    let vm = FlashcardVM()
    let card = FlashcardModel(
        term: "Hello",
        id: UUID(),
        category: "Greetings"
    )
    return MultipleChoice(
        question: "What sign is being shown?",
        imageName: "greetingsIllustration",
        options: ["Hello", "Goodbye", "Wassup", "See you"],
        correctAnswer: "Hello",
        explanationText: "People often confuse this sign with 'Goodbye' because the hand motion looks similar at a glance.",
        currentCard: card,
        onNext: { _ in },
        progress: 0.0
    )
    .environment(vm)
}

#Preview("Spaced Repetition Tester") {
    MultipleChoiceSRTester()
}
