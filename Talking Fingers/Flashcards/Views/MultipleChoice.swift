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

    // Mode binding — lets the user toggle Camera vs Flashcards mid-session
    @Binding var inputMode: ExerciseInputMode

    // Called when the user taps Leave; on macOS (inline) this replaces dismiss().
    var onLeave: (() -> Void)? = nil

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
    /// Captured at runtime so the GIF scales to the available window/screen height.
    @State private var viewHeight: CGFloat = 500

    // MARK: - Brand Colors
    private let tfGreen = Color(red: 159/255, green: 192/255, blue: 122/255)
    private let tfGreenText = Color(red: 82/255, green: 106/255, blue: 54/255)

    /// 28 % of the view height, clamped between 140 pt (small phones) and 280 pt (large displays).
    private var gifHeight: CGFloat {
        min(max(viewHeight * 0.28, 140), 280)
    }

    // MARK: - Init
    init(
        question: String,
        imageName: String,
        options: [String],
        correctAnswer: String,
        explanationText: String = "People often confuse this sign with Goodbye because...",
        currentCard: FlashcardModel,
        inputMode: Binding<ExerciseInputMode> = .constant(.flashcards),
        onLeave: (() -> Void)? = nil,
        onNext: @escaping (FlashcardModel) -> Void = { _ in },
        progress: Double
    ) {
        self.question = question
        self.imageName = imageName
        self.options = options
        self.correctAnswer = correctAnswer
        self.explanationText = explanationText
        self.currentCard = currentCard
        self._inputMode = inputMode
        self.onLeave = onLeave
        self.onNext = onNext
        self.progress = progress
    }

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
                    }
                    .frame(maxWidth: 1100)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }

                // ── Submit (bottom area) + private tiny level badge ───────
                VStack(spacing: 6) {
                    submitButton
                        .frame(maxWidth: 1100)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    HStack {
                        tinyProgressBadge
                        Spacer()
                    }
                    .frame(maxWidth: 1100)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                }
                .frame(maxWidth: .infinity)
            }
            .background(Color(hex: 0xFFFFFF))
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
        }
        // Capture the runtime view height so gifHeight can adapt.
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { viewHeight = geo.size.height }
                    .onChange(of: geo.size.height) { _, h in viewHeight = h }
            }
        )
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
                message: "You got it right!",
                onNext: {
                    advanceToNextCard()
                }
            )
        }
        // Incorrect answer popup
        .popupHost(isPresented: $showIncorrectPopup) {
            IncorrectResultPopUpComponent(
                message: "Correct answer: \(correctAnswer)",
                onNext: {
                    advanceToNextCard()
                }
            )
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    #if os(macOS)
                    onLeave?()
                    #else
                    dismiss()
                    #endif
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 16, weight: .medium))

                        Text("Leave")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.gray)
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            
            HStack(spacing: 12) {

                GeometryReader { geo in
                    ZStack(alignment: .leading) {

                        Capsule()
                            .fill(Color(red: 0.88, green: 0.92, blue: 0.96))

                        Capsule()
                            .fill(Color(red: 0.30, green: 0.55, blue: 0.85))
                            .frame(width: geo.size.width * CGFloat(progress))
                    }
                }
                .frame(height: 10)

                ExerciseSettingsMenu(mode: $inputMode)
            }
            .padding(.horizontal, 20)

        }
        .padding(.top, 10)
    }

    // MARK: - Question Card
    private var questionCard: some View {
        VStack(spacing: 16) {

            // Save + Hint
            HStack {
                Button {
                    isSaved.toggle()
                } label: {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .foregroundColor(tfGreenText)
                        .padding(14)
                        .background(Circle().fill(tfGreen.opacity(0.25)))
                        .scaleEffect(1.1)
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    showHintPopup = true
                } label: {
                    Image(systemName: "lightbulb")
                        .foregroundColor(.orange)
                        .padding(14)
                        .background(Circle().fill(Color.orange.opacity(0.2)))
                        .scaleEffect(1.1)
                }
                .buttonStyle(.plain)
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
                if let gifFileName = currentCard.gifFileName ?? currentCard.term.defaultGifFileName {
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
                    optionRow(option, isSelected: selectedAnswer == option)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.blue.opacity(0.25), lineWidth: 1.5)
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 8)
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
    func optionRow(_ text: String, isSelected: Bool) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedAnswer = text
            }
        } label: {
            HStack {
                Text(text)
                    .font(.body.weight(isSelected ? .semibold : .regular))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isSelected
                        ? Color(red: 0.93, green: 0.78, blue: 0.50)
                        : Color.white
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1.2)
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
        .buttonStyle(.plain)
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
            // No more cards — return to parent
            #if os(macOS)
            onLeave?()
            #else
            dismiss()
            #endif
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
            isCorrect: true,
            message: message,
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
            isCorrect: false,
            message: message,
            onNext: onNext
        )
    }
}

private struct ResultCard: View {
    let title: String
    let isCorrect: Bool
    let message: String
    let onNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // TITLE ROW
            HStack {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isCorrect ? .green : .red)

                Text(isCorrect ? "Amazing!" : "Not quite!")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(isCorrect ? Color.green : Color.red)
            }

            Text(message)
                .foregroundColor(isCorrect ? Color.green : Color.red)
                .font(.system(size: 16, weight: .medium))

            // BUTTON
            Button {
                onNext()
            } label: {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isCorrect
                                  ? Color(red: 0.56, green: 0.72, blue: 0.44)
                                  : Color.red.opacity(0.8))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .frame(maxWidth: 1100)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(isCorrect
                      ? Color(red: 0.90, green: 0.95, blue: 0.85)
                      : Color(red: 0.95, green: 0.85, blue: 0.85))
        )
        .padding(.horizontal, 20)
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
        FlashcardModel(term: .zero, id: UUID(), lastSucceeded: nil, starred: false, progress: .new, category: .numbers),
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
    let distractors = pool
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
                    inputMode: .constant(.flashcards),
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
    MultipleChoice(
        question: "What sign is being shown?",
        imageName: "greetingsIllustration",
        options: ["Hello", "Goodbye", "Wassup", "See you"],
        correctAnswer: "Hello",
        explanationText: "People often confuse this sign with 'Goodbye' because the hand motion looks similar at a glance.",
        currentCard: card,
        inputMode: .constant(.flashcards),
        onNext: { _ in },
        progress: 0.0
    )
    .environment(vm)
    .environment(SwiftDataVM())
    .modelContainer(for: [FlashcardModel.self, User.self], inMemory: true)
}

#Preview("Zero GIF") {
    let vm = FlashcardVM()
    let card = FlashcardModel(
        term: .zero,
        id: UUID(),
        category: .numbers
    )
    return MultipleChoice(
        question: "What sign is being shown?",
        imageName: "greetingsIllustration",
        options: ["0", "1", "2", "3"],
        correctAnswer: "0",
        explanationText: "This card verifies that the zero flashcard loads zero.gif.",
        currentCard: card,
        onNext: { _ in },
        progress: 0.0
    )
    .environment(vm)
    .environment(SwiftDataVM())
    .modelContainer(for: [FlashcardModel.self, User.self], inMemory: true)
}

#Preview("Spaced Repetition Tester") {
    MultipleChoiceSRTester()
}
