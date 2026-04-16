//
//  FlexibleStartCardComponent.swift
//  Talking Fingers
//
//  Created by Sanvi Adusumilli on 4/16/26.
//
//  Builds on StartCardComponent - works for Learn, Exercise, or Daily Challenge
//

import SwiftUI

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
}

struct FlexibleStartCardComponent: View {
    let context: StartContext
    let completed: Int
    let total: Int
    let closeAction: () -> Void
    
    @State private var flashcardVM = FlashcardVM()
    @State private var isActive: Bool = false
    
    @Environment(SwiftDataVM.self) private var dataVM

    var progress: CGFloat {
        CGFloat(Double(completed) / Double(max(total, 1)))
    }

    var body: some View {
        Group {
            if isActive {
                switch context {
                case .learn(let category):
                    LearnFlow(
                        initialCard: flashcardVM.flashcards.first ?? FlashcardModel(term: .hello, id: UUID(), category: category),
                        targetCount: total,
                        vm: flashcardVM
                    ) {
                        isActive = false
                    }
                    
                case .exercise, .dailyChallenge:
                    MultipleChoiceFlow(
                        initialCard: flashcardVM.flashcards.first ?? FlashcardModel(term: .hello, id: UUID(), category: .greetings),
                        imageName: context.iconName,
                        targetCount: total,
                        vm: flashcardVM
                    ) {
                        isActive = false
                    }
                    .environment(flashcardVM)
                    .environment(dataVM)
                }
            } else {
                startView
            }
        }
    }

    // MARK: - Start View UI
    private var startView: some View {
        ZStack {
            VStack(spacing: 16) {
                let lightGreen = Color(red: 0.56, green: 0.72, blue: 0.44)
                let isDaily = context.title == "Daily Challenge"
                Image(systemName: context.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: isDaily ? 120 : 150)
                    .foregroundColor(isDaily ? .orange : lightGreen)
                    .padding(.bottom, 10)

                if case .dailyChallenge = context {
                    Text(context.title)
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(Color(red: 0.56, green: 0.72, blue: 0.44))
                } else {
                    Text(context.title)
                        .font(.system(size: 40))
                        .foregroundColor(.black.opacity(0.7))
                    
                    Text(context.subtitle)
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(Color(red: 0.58, green: 0.72, blue: 0.85))
                }

                Text("\(completed)/\(total) Words Completed")
                    .foregroundColor(.black)

                ProgressView(value: progress)
                    .tint(Color(red: 0.70, green: 0.80, blue: 0.90))
                    .scaleEffect(y: 1.5)
                    .padding(.horizontal, 60)

                Spacer().frame(height: 20)

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
            }
        }
        .padding(.horizontal, 16)
        .onAppear {
            if flashcardVM.flashcards.isEmpty || flashcardVM.flashcards.count <= 1 {
                 flashcardVM.flashcards = FlashcardVM.dummyFlashcards
            }
        }
    }
}

private struct MultipleChoiceFlow: View {
    @Environment(\.dismiss) private var dismiss

    @State private var currentCard: FlashcardModel
    @State private var options: [String] = []
    @State private var completedCount: Int = 0

    let imageName: String
    let targetCount: Int
    let vm: FlashcardVM
    let onFinished: () -> Void

    init(initialCard: FlashcardModel, imageName: String, targetCount: Int, vm: FlashcardVM, onFinished: @escaping () -> Void) {
        _currentCard = State(initialValue: initialCard)
        self.imageName = imageName
        self.targetCount = targetCount
        self.vm = vm
        self.onFinished = onFinished
    }

    var body: some View {
        MultipleChoice(
            question: "What sign is being shown?",
            imageName: imageName,
            options: options,
            correctAnswer: currentCard.term.displayName,
            explanationText: "People often confuse this sign with similar motions. Focus on handshape and movement.",
            currentCard: currentCard,
            onNext: { next in
                advance(to: next)
            },
            progress: Double(completedCount) / Double(targetCount)
        )
        .onAppear {
            options = buildOptions(for: currentCard, from: vm.flashcards)
        }
        .environment(vm)
    }

    private func advance(to next: FlashcardModel) {
        completedCount += 1
        if completedCount >= targetCount {
            onFinished()
            dismiss()
            return
        }
        let nextCard = next
        currentCard = nextCard
        options = buildOptions(for: nextCard, from: vm.flashcards)
    }

    private func buildOptions(for card: FlashcardModel, from pool: [FlashcardModel], count: Int = 4) -> [String] {
        let distractors = pool
            .filter { $0.id != card.id }
            .map { $0.term.displayName }
            .shuffled()
            .prefix(max(0, count - 1))

        var opts = Array(distractors)
        opts.append(card.term.displayName)
        return Array(Set(opts)).shuffled()
    }
}

private struct LearnFlow: View {
    @State private var currentCard: FlashcardModel
    @State private var completedCount: Int = 0
    let targetCount: Int
    let vm: FlashcardVM
    let onFinished: () -> Void
    
    init(initialCard: FlashcardModel, targetCount: Int, vm: FlashcardVM, onFinished: @escaping () -> Void) {
        _currentCard = State(initialValue: initialCard)
        self.targetCount = targetCount
        self.vm = vm
        self.onFinished = onFinished
    }
    
    var body: some View {
        let learnVM = LearnModeVM(flashcard: currentCard)
        learnVM.onNextCard = { advance() }
        
        return LearnModeView(vm: learnVM, progress: Double(completedCount) / Double(max(targetCount, 1)), onClose: onFinished)
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
        context: .learn(.greetings),
        completed: 0,
        total: 12,
        closeAction: {}
    )
    .environment(SwiftDataVM())
}
