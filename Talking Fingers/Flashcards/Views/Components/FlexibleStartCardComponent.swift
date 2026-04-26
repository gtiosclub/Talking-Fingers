//
//  FlexibleStartCardComponent.swift
//  Talking Fingers
//
//  Created by Sanvi Adusumilli on 4/16/26.
//

import SwiftUI
import SwiftData

enum StartContext {
    case learn(TermCategory)
    case exercise(TermCategory)
    case dailyChallenge
    
    var title: String {
        switch self {
        case .learn: return "Learn"
        case .exercise: return "Exercise"
        case .dailyChallenge: return "Daily Challenge"
        }
    }
    
    var subtitle: String {
        switch self {
        case .learn(let cat), .exercise(let cat): return cat.displayName + "!"
        case .dailyChallenge: return ""
        }
    }
    
    var primaryButtonText: String {
        switch self {
        case .learn: return "Begin Learn"
        case .exercise: return "Begin Exercise"
        case .dailyChallenge: return "Let's Go!"
        }
    }
    
    var iconName: String {
        switch self {
        case .learn(let cat), .exercise(let cat):
            switch cat {
            case .alphabet:             return "a.square"
            case .numbers:              return "number"
            case .greetings:            return "hand.wave"
            case .personalInformation:  return "person.text.rectangle"
            case .family:               return "figure.2.and.child.holdinghands"
            case .verbs:                return "bolt"
            case .dateTime:             return "calendar"
            case .feelingsEmotions:     return "heart"
            case .locations:            return "mappin.and.ellipse"
            case .commonDescriptors:    return "text.magnifyingglass"
            case .commonObjects:        return "cube"
            }
        case .dailyChallenge:
            return "flame.fill"
        }
    }
    
    var heroImageName: String? {
        switch self {
        case .learn:
            return "SentencesComprehendFlowerFull"
        case .exercise:
            return "SentencesSignFlowerFull"
        case .dailyChallenge:
            return nil
        }
    }
    
    var id: String {
        switch self {
        case .learn(let cat):
            return "learn_\(cat.rawValue)"
        case .exercise(let cat):
            return "exercise_\(cat.rawValue)"
        case .dailyChallenge:
            return "dailyChallenge"
        }
    }
}

struct FlexibleStartCardComponent: View {
    @State var context: StartContext
    let completed: Int
    let total: Int
    let closeAction: () -> Void
    
    @State private var flashcardVM = FlashcardVM()
    @State private var isActive: Bool = false
    @State private var showEndScreen: Bool = false
    
    @Environment(SwiftDataVM.self) private var dataVM

    var progress: CGFloat {
        CGFloat(Double(completed) / Double(max(total, 1)))
    }

    var body: some View {
        Group {
            if showEndScreen {
                EndCardComponent(
                    context: context,
                    total: total,
                    onGoHome: closeAction,
                    onGoToExercise: {
                        if case .learn(let cat) = context {
                            context = .exercise(cat)
                            showEndScreen = false
                            isActive = false
                        }
                    }
                )
            } else if isActive {
                switch context {
                case .learn(let category):
                    LearnFlow(
                        initialCard: flashcardVM.flashcards.first ?? fallbackCard(for: category),
                        targetCount: total,
                        vm: flashcardVM,
                        onLeave: closeAction
                    ) {
                        markLearnCompletedIfNeeded()
                        showEndScreen = true
                    }
                    
                case .exercise(let category):
                    ExerciseSessionFlow(
                        initialCard: flashcardVM.flashcards.first ?? fallbackCard(for: category),
                        imageName: context.iconName,
                        targetCount: total,
                        vm: flashcardVM,
                        onLeave: closeAction
                    ) {
                        showEndScreen = true
                    }
                    .environment(flashcardVM)
                    .environment(dataVM)
                case .dailyChallenge:
                    ExerciseSessionFlow(
                        initialCard: flashcardVM.flashcards.first ?? FlashcardModel(term: .hello, id: UUID(), category: .greetings),
                        imageName: context.iconName,
                        targetCount: total,
                        vm: flashcardVM,
                        onLeave: closeAction
                    ) {
                        showEndScreen = true
                    }
                    .environment(flashcardVM)
                    .environment(dataVM)
                }
            } else {
                startView
            }
        }
    }

    private var startView: some View {
        ZStack {
            VStack(spacing: 16) {
                let lightGreen = Color(red: 0.56, green: 0.72, blue: 0.44)
                let isDaily = context.title == "Daily Challenge"

                Spacer()

                if let heroImageName = context.heroImageName {
                    Image(heroImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 165)
                        .padding(.bottom, 6)
                } else {
                    Image(systemName: context.iconName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: isDaily ? 120 : 150)
                        .foregroundColor(isDaily ? .orange : lightGreen)
                        .padding(.bottom, 10)
                }

                if case .dailyChallenge = context {
                    Text(context.title)
                        .font(.jakarta(size: 42, weight: .bold))
                        .foregroundColor(Color(red: 0.56, green: 0.72, blue: 0.44))
                } else {
                    Text(context.title)
                        .font(.jakarta(size: 40))
                        .foregroundColor(.black.opacity(0.7))
                        .multilineTextAlignment(.center)
                    
                    Text(context.subtitle)
                        .font(.jakarta(size: 42, weight: .bold))
                        .foregroundColor(context.title == "Learn" ? Color(red: 0.56, green: 0.72, blue: 0.44) : Color(red: 0.58, green: 0.72, blue: 0.85))
                        .multilineTextAlignment(.center)
                }

                if case .dailyChallenge = context {
                    Text("\(completed)/\(total) Words Completed")
                        .foregroundColor(.black)
                } else {
                    Text("\(total) words to go!")
                        .font(.jakarta(size: 16, weight: .medium))
                        .foregroundColor(Color.black.opacity(0.35))
                        .multilineTextAlignment(.center)
                }

                if case .dailyChallenge = context {
                    ProgressView(value: progress)
                        .tint(Color(red: 0.70, green: 0.80, blue: 0.90))
                        .scaleEffect(y: 1.5)
                        .padding(.horizontal, 60)
                }

                Spacer()

                Button(action: {
                    isActive = true
                }) {
                    Text(context.primaryButtonText)
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(red: 0.56, green: 0.72, blue: 0.44))
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 40)

                Button(action: {
                    closeAction()
                }) {
                    Text("Go Home")
                        .font(.headline)
                        .foregroundColor(Color(red: 0.30, green: 0.55, blue: 0.30))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(red: 0.56, green: 0.72, blue: 0.44).opacity(0.25))
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 40)

                Spacer()
            }
            .frame(maxHeight: .infinity)
        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal, 16)
        .onAppear {
            configureCardsForContext()
        }
        .onChange(of: context.id) { _, _ in
            configureCardsForContext()
        }
    }
    
    private func configureCardsForContext() {
        switch context {
        case .learn(let category), .exercise(let category):
            flashcardVM.flashcards = fallbackCards(for: category)
        case .dailyChallenge:
            flashcardVM.flashcards = FlashcardVM.dummyFlashcards
            flashcardVM.flashcards = flashcardVM.generateDailyReviewQueue(limit: total).cards
        }
        flashcardVM.lastCardID = nil
    }
    
    private func markLearnCompletedIfNeeded() {
        guard case .learn(let category) = context else { return }
        let key = "learnCompleted_\(category.rawValue)"
        UserDefaults.standard.set(true, forKey: key)
    }
    
    private func fallbackCards(for category: TermCategory) -> [FlashcardModel] {
        Term.words(for: category).map { term in
            FlashcardModel(term: term, id: UUID(), category: category)
        }
    }
    
    private func fallbackCard(for category: TermCategory) -> FlashcardModel {
        if let term = Term.words(for: category).first {
            return FlashcardModel(term: term, id: UUID(), category: category)
        }
        return FlashcardModel(term: .hello, id: UUID(), category: .greetings)
    }
}

private struct ExerciseSessionFlow: View {
    @State private var currentCard: FlashcardModel
    @State private var options: [String] = []
    @State private var completedCount: Int = 0
    /// Overall session setting chosen by the user via the menu.
    @State private var mode: ExerciseInputMode = .mixed
    /// Resolved modality for the *current* card — never `.mixed`.
    /// Re-resolved on each card advance and whenever the user changes `mode`.
    @State private var currentSlotMode: ExerciseInputMode = Bool.random() ? .camera : .flashcards

    let imageName: String
    let targetCount: Int
    let vm: FlashcardVM
    let onLeave: () -> Void
    let onFinished: () -> Void

    @Environment(SwiftDataVM.self) private var dataVM

    init(initialCard: FlashcardModel, imageName: String, targetCount: Int, vm: FlashcardVM, onLeave: @escaping () -> Void, onFinished: @escaping () -> Void) {
        _currentCard = State(initialValue: initialCard)
        self.imageName = imageName
        self.targetCount = targetCount
        self.vm = vm
        self.onLeave = onLeave
        self.onFinished = onFinished
    }

    var body: some View {
        Group {
            if currentSlotMode == .camera {
                VisionExerciseView(
                    currentCard: currentCard,
                    progress: Double(completedCount) / Double(targetCount),
                    inputMode: $mode,
                    onLeave: onLeave,
                    onNext: { next in advance(to: next) }
                )
                .id(currentCard.id)
            } else {
                flashcardsView
            }
        }
        .onAppear {
            options = buildOptions(for: currentCard, from: vm.flashcards)
        }
        // When the user changes the session mode mid-card, re-resolve the current slot immediately.
        .onChange(of: mode) { _, newMode in
            currentSlotMode = resolvedSlotMode(for: newMode)
        }
    }

    private var flashcardsView: some View {
        MultipleChoice(
            question: "What sign is being shown?",
            imageName: imageName,
            options: options,
            correctAnswer: currentCard.term.displayName,
            explanationText: "People often confuse this sign with similar motions. Focus on handshape and movement.",
            currentCard: currentCard,
            inputMode: $mode,
            onLeave: onLeave,
            onNext: { next in advance(to: next) },
            progress: Double(completedCount) / Double(targetCount)
        )
        .onAppear {
            options = buildOptions(for: currentCard, from: vm.flashcards)
        }
    }

    // MARK: - Helpers

    /// Resolves `.mixed` into either `.flashcards` or `.camera` at random.
    /// `.flashcards` and `.camera` pass through unchanged.
    private func resolvedSlotMode(for overallMode: ExerciseInputMode) -> ExerciseInputMode {
        switch overallMode {
        case .flashcards: return .flashcards
        case .camera:     return .camera
        case .mixed:      return Bool.random() ? .camera : .flashcards
        }
    }

    private func advance(to next: FlashcardModel) {
        completedCount += 1
        if completedCount >= targetCount {
            onFinished()
            return
        }
        currentCard = next
        options = buildOptions(for: next, from: vm.flashcards)
        currentSlotMode = resolvedSlotMode(for: mode)
    }

    private func buildOptions(for card: FlashcardModel, from pool: [FlashcardModel], count: Int = 4) -> [String] {
        let correct = card.term.displayName
        let targetCount = max(2, count)

        // Keep only unique distractor labels and never include the correct label.
        let distractors = Array(
            Set(
                pool
                    .filter { $0.id != card.id }
                    .map { $0.term.displayName }
                    .filter { $0 != correct }
            )
        )
        .shuffled()

        var options = Array(distractors.prefix(max(0, targetCount - 1)))
        options.append(correct)

        // If the category pool is too small, backfill with global unique terms.
        if options.count < targetCount {
            let existing = Set(options)
            let fallback = Term.allCases
                .map(\.displayName)
                .filter { !existing.contains($0) }
                .shuffled()
                .prefix(targetCount - options.count)
            options.append(contentsOf: fallback)
        }

        return Array(Set(options)).shuffled()
    }
}

private struct LearnFlow: View {
    @State private var currentCard: FlashcardModel
    @State private var completedCount: Int = 0
    let targetCount: Int
    let vm: FlashcardVM
    let onLeave: () -> Void
    let onFinished: () -> Void
    @Environment(SwiftDataVM.self) private var dataVM
    @Query private var users: [User]
    
    init(initialCard: FlashcardModel, targetCount: Int, vm: FlashcardVM, onLeave: @escaping () -> Void, onFinished: @escaping () -> Void) {
        _currentCard = State(initialValue: initialCard)
        self.targetCount = targetCount
        self.vm = vm
        self.onLeave = onLeave
        self.onFinished = onFinished
    }
    
    var body: some View {
        let learnVM = LearnModeVM(flashcard: currentCard)
        learnVM.onAnswer = { wasCorrect in
            if let currentUser = users.first {
                vm.handleAnswer(for: currentCard, correct: wasCorrect, user: currentUser, dataVM: dataVM)
            }
            advance()
        }
        
        return LearnModeView(vm: learnVM, progress: Double(completedCount) / Double(max(targetCount, 1)), onClose: onLeave)
            .id(currentCard.id)
    }
    
    private func advance() {
        completedCount += 1
        if completedCount >= targetCount {
            onFinished()
            return
        }
        if let next = vm.nextCard() { currentCard = next } else { onFinished() }
    }
}

#Preview {
    FlexibleStartCardComponent(
        context: .dailyChallenge,
        completed: 0,
        total: 5,
        closeAction: {}
    )
    .environment(SwiftDataVM())
}
