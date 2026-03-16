//
//  StartCardComponent.swift
//  Talking Fingers
//
//  Created by Na Hua on 3/2/26.
//
import SwiftUI

struct StartCardComponent: View {
    let modeTitle: String
    let topic: String
    let completed: Int
    let total: Int
    let imageName: String
    let primaryAction: () -> Void
    let secondaryAction: () -> Void
    let closeAction: () -> Void

    let learnFlashcard: FlashcardModel
    let learnProgress: Double

    @State private var showDashboard = false
    @State private var showLearn = false

    // Provide a VM for MultipleChoice spaced repetition and nextCard()
    @State private var flashcardVM = FlashcardVM()

    var progress: CGFloat {
        CGFloat(Double(completed) / Double(max(total, 1)))
    }

    var body: some View {
        VStack {
            HStack {
                Button(action: closeAction) {
                    Image(systemName: "xmark")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(.black)
                }
                Spacer()
            }
            .padding(.top, 12)

            VStack(spacing: 28) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 250)

                VStack(spacing: 6) {
                    Text("\(modeTitle):")
                        .font(.system(size: 34, weight: .bold))

                    Text(topic)
                        .font(.system(size: 34, weight: .bold))

                    Text("\(completed)/\(total) Words Completed")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(.primary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.25))
                            .frame(height: 12)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.6))
                            .frame(width: geo.size.width * progress, height: 12)
                    }
                }
                .frame(height: 12)
                .padding(.horizontal, 24)
            }
            .padding(.top, 16)

            Spacer()

            VStack(spacing: 18) {
                ActionButton(
                    title: "Let's Go!",
                    style: .primary,
                    action: {
                        showLearn = true
                    }
                )

                ActionButton(
                    title: "Go Home",
                    style: .secondary,
                    action: {
                        showDashboard = true
                    }
                )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 16)
        .onAppear {
            // Seed with the same dummy cards used in MultipleChoice.swift
            if flashcardVM.flashcards.isEmpty || flashcardVM.flashcards.count <= 1 {
                flashcardVM.flashcards = makeMultipleChoiceDummyFlashcards()
            }
        }
        .fullScreenCover(isPresented: $showDashboard) {
            DashboardView()
        }
        .fullScreenCover(isPresented: $showLearn) {
            MultipleChoiceFlow(
                initialCard: learnFlashcard,
                imageName: imageName,
                targetCount: 7,
                vm: flashcardVM
            ) {
                // Flow finished or user exited — dismiss cover
                showLearn = false
            }
            .environment(flashcardVM)
        }
    }

    // Simple duplicate of the helper in MultipleChoice.swift (since that one is file-private)
    private func buildOptions(for card: FlashcardModel, from pool: [FlashcardModel], count: Int = 4) -> [String] {
        var distractors = pool
            .filter { $0.id != card.id }
            .map { $0.term }
            .shuffled()
            .prefix(max(0, count - 1))

        var opts = Array(distractors)
        opts.append(card.term)
        return Array(Set(opts)).shuffled()
    }

    // Mirror of makeDummyFlashcards() from MultipleChoice.swift to use those dummy cards
    private func makeMultipleChoiceDummyFlashcards() -> [FlashcardModel] {
        func daysAgo(_ days: Int) -> Date {
            Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        }

        var cards: [FlashcardModel] = []

        // Greetings (mixed progress)
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

        // Numbers
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

        // Colors
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

        // Family
        cards += [
            FlashcardModel(term: "Mother", id: UUID(), lastSucceeded: daysAgo(9), starred: false, progress: .learning, category: "Family"),
            FlashcardModel(term: "Father", id: UUID(), lastSucceeded: daysAgo(4), starred: false, progress: .polishing, category: "Family"),
            FlashcardModel(term: "Brother", id: UUID(), lastSucceeded: nil, starred: false, progress: .new, category: "Family"),
            FlashcardModel(term: "Sister", id: UUID(), lastSucceeded: daysAgo(1), starred: false, progress: .mastered, category: "Family"),
            FlashcardModel(term: "Grandmother", id: UUID(), lastSucceeded: daysAgo(20), starred: false, progress: .learning, category: "Family"),
            FlashcardModel(term: "Grandfather", id: UUID(), lastSucceeded: daysAgo(2), starred: false, progress: .polishing, category: "Family"),
        ]

        // Common verbs
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
}

// MARK: - Flow wrapper that keeps asking until N questions are completed
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
            correctAnswer: currentCard.term,
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
        var distractors = pool
            .filter { $0.id != card.id }
            .map { $0.term }
            .shuffled()
            .prefix(max(0, count - 1))

        var opts = Array(distractors)
        opts.append(card.term)
        return Array(Set(opts)).shuffled()
    }
}

#Preview {
    // Dummy flashcard for preview
    let dummyCard = FlashcardModel(
        term: "Hello",
        id: UUID(),
        category: "Greetings"
    )

    return StartCardComponent(
        modeTitle: "Exercise",
        topic: "Greetings",
        completed: 0,
        total: 12,
        imageName: "greetingsIllustration",
        primaryAction: {},
        secondaryAction: {},
        closeAction: {},
        learnFlashcard: dummyCard,
        learnProgress: 0.25
    )
}
