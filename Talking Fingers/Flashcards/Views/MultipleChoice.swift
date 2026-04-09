//
//  MultipleChoice.swift
//  Talking Fingers
//
//  Created by Isha Jain on 3/16/26.
//

import SwiftUI
import SwiftData

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
    @Environment(SwiftDataVM.self) private var dataVM
    @Query private var users: [User]

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
            Color(hex: 0xFFFFFF).ignoresSafeArea()

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
                    Color(hex: 0xFFFFFF)
                        .overlay(
                            Rectangle()
                                .fill(Color.black.opacity(0.05))
                                .frame(height: 0.5)
                                .frame(maxHeight: .infinity, alignment: .top)
                        )
                )
            }
            .background(Color(hex: 0xFFFFFF))
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
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
                        .fill(Color(hex: 0xE5E5EA))
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
                    .fill(Color(hex: 0xFFFFFF))
                    .frame(height: 180)
                    .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)

                /*if imageName.isEmpty {
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
                }*/
                let gifFileName: String? = "helloGIF.gif"

                if let gifFileName = gifFileName {
                    GIFView(gifFileName: gifFileName)
                        .frame(width: 200, height: 150)
                } else {
                    Text("No GIF available")
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
                .fill(Color(hex: 0xFFFFFF))
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
                        .fill(Color(hex: 0xF2F2F7).opacity(0.6))
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
                    .foregroundColor(isSelected ? .black : .primary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color(red: 1, green: 0.85, blue: 0.5) : Color(hex: 0xF2F2F7))
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
        if let currentUser = users.first {
            flashcardVM.handleAnswer(for: currentCard, correct: isCorrect, user: currentUser, dataVM: dataVM)
        }

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
        FlashcardModel(term: .hello, id: UUID(), lastSucceeded: nil, starred: false, progress: .new, category: .greetings),
        FlashcardModel(term: .bye, id: UUID(), lastSucceeded: daysAgo(10), starred: false, progress: .learning, category: .greetings),
        FlashcardModel(term: .hi, id: UUID(), lastSucceeded: daysAgo(3), starred: true, progress: .polishing, category: .greetings),
        FlashcardModel(term: .whatUp, id: UUID(), lastSucceeded: daysAgo(1), starred: false, progress: .mastered, category: .greetings),
        FlashcardModel(term: .niceMeetYou, id: UUID(), lastSucceeded: daysAgo(20), starred: false, progress: .learning, category: .greetings),
        FlashcardModel(term: .goodMorning, id: UUID(), lastSucceeded: daysAgo(5), starred: false, progress: .polishing, category: .greetings),
        FlashcardModel(term: .goodNight, id: UUID(), lastSucceeded: daysAgo(1), starred: false, progress: .mastered, category: .greetings),
        FlashcardModel(term: .seeYouLater, id: UUID(), lastSucceeded: nil, starred: false, progress: .new, category: .greetings),
    ]

    cards += [
        FlashcardModel(term: .one, id: UUID(), lastSucceeded: daysAgo(8), starred: false, progress: .learning, category: .numbers),
        FlashcardModel(term: .two, id: UUID(), lastSucceeded: daysAgo(2), starred: false, progress: .polishing, category: .numbers),
        FlashcardModel(term: .three, id: UUID(), lastSucceeded: daysAgo(5), starred: true, progress: .polishing, category: .numbers),
        FlashcardModel(term: .four, id: UUID(), lastSucceeded: daysAgo(1), starred: false, progress: .mastered, category: .numbers),
        FlashcardModel(term: .five, id: UUID(), lastSucceeded: nil, starred: false, progress: .new, category: .numbers),
        FlashcardModel(term: .six, id: UUID(), lastSucceeded: daysAgo(15), starred: false, progress: .learning, category: .numbers),
        FlashcardModel(term: .seven, id: UUID(), lastSucceeded: daysAgo(3), starred: false, progress: .polishing, category: .numbers),
        FlashcardModel(term: .eight, id: UUID(), lastSucceeded: daysAgo(1), starred: false, progress: .mastered, category: .numbers),
        FlashcardModel(term: .nine, id: UUID(), lastSucceeded: nil, starred: false, progress: .new, category: .numbers),
        FlashcardModel(term: .ten, id: UUID(), lastSucceeded: daysAgo(30), starred: false, progress: .learning, category: .numbers),
    ]

    cards += [
        FlashcardModel(term: .happy, id: UUID(), lastSucceeded: daysAgo(1), starred: false, progress: .mastered, category: .feelingsEmotions),
        FlashcardModel(term: .sad, id: UUID(), lastSucceeded: daysAgo(2), starred: false, progress: .mastered, category: .feelingsEmotions),
        FlashcardModel(term: .angry, id: UUID(), lastSucceeded: daysAgo(3), starred: true, progress: .polishing, category: .feelingsEmotions),
        FlashcardModel(term: .excited, id: UUID(), lastSucceeded: daysAgo(1), starred: false, progress: .mastered, category: .feelingsEmotions),
        FlashcardModel(term: .tired, id: UUID(), lastSucceeded: daysAgo(12), starred: false, progress: .learning, category: .feelingsEmotions),
        FlashcardModel(term: .bored, id: UUID(), lastSucceeded: nil, starred: false, progress: .new, category: .feelingsEmotions),
        FlashcardModel(term: .scared, id: UUID(), lastSucceeded: daysAgo(6), starred: false, progress: .polishing, category: .feelingsEmotions),
        FlashcardModel(term: .surprised, id: UUID(), lastSucceeded: nil, starred: false, progress: .new, category: .feelingsEmotions),
    ]

    cards += [
        FlashcardModel(term: .mother, id: UUID(), lastSucceeded: daysAgo(9), starred: false, progress: .learning, category: .family),
        FlashcardModel(term: .father, id: UUID(), lastSucceeded: daysAgo(4), starred: false, progress: .polishing, category: .family),
        FlashcardModel(term: .brother, id: UUID(), lastSucceeded: nil, starred: false, progress: .new, category: .family),
        FlashcardModel(term: .sister, id: UUID(), lastSucceeded: daysAgo(1), starred: false, progress: .mastered, category: .family),
        FlashcardModel(term: .grandmother, id: UUID(), lastSucceeded: daysAgo(20), starred: false, progress: .learning, category: .family),
        FlashcardModel(term: .grandfather, id: UUID(), lastSucceeded: daysAgo(2), starred: false, progress: .polishing, category: .family),
    ]

    cards += [
        FlashcardModel(term: .eat, id: UUID(), lastSucceeded: daysAgo(7), starred: false, progress: .learning, category: .verbs),
        FlashcardModel(term: .drink, id: UUID(), lastSucceeded: daysAgo(3), starred: false, progress: .polishing, category: .verbs),
        FlashcardModel(term: .go, id: UUID(), lastSucceeded: daysAgo(14), starred: false, progress: .learning, category: .verbs),
        FlashcardModel(term: .come, id: UUID(), lastSucceeded: nil, starred: false, progress: .new, category: .verbs),
        FlashcardModel(term: .want, id: UUID(), lastSucceeded: daysAgo(1), starred: false, progress: .mastered, category: .verbs),
        FlashcardModel(term: .get, id: UUID(), lastSucceeded: daysAgo(5), starred: false, progress: .polishing, category: .verbs),
        FlashcardModel(term: .like, id: UUID(), lastSucceeded: nil, starred: false, progress: .new, category: .verbs),
    ]

    return cards
}

private func optionsFor(card: FlashcardModel, from pool: [FlashcardModel], count: Int = 4) -> [String] {
    var distractors = pool
        .filter { $0.id != card.id }
        .map { $0.term.displayName }
        .shuffled()
        .prefix(max(0, count - 1))

    var opts = Array(distractors)
    opts.append(card.term.displayName)
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
                    correctAnswer: current.term.displayName,
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
        term: .hello,
        id: UUID(),
        category: .greetings
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
