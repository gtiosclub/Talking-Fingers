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
            .map { $0.term.displayName }
            .shuffled()
            .prefix(max(0, count - 1))

        var opts = Array(distractors)
        opts.append(card.term.displayName)
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
            FlashcardModel(term: .hello, id: UUID(), lastSucceeded: nil, starred: false, progress: .new, category: .greetings),
            FlashcardModel(term: .bye, id: UUID(), lastSucceeded: daysAgo(10), starred: false, progress: .learning, category: .greetings),
            FlashcardModel(term: .hi, id: UUID(), lastSucceeded: daysAgo(3), starred: true, progress: .polishing, category: .greetings),
            FlashcardModel(term: .whatUp, id: UUID(), lastSucceeded: daysAgo(1), starred: false, progress: .mastered, category: .greetings),
            FlashcardModel(term: .niceMeetYou, id: UUID(), lastSucceeded: daysAgo(20), starred: false, progress: .learning, category: .greetings),
            FlashcardModel(term: .goodMorning, id: UUID(), lastSucceeded: daysAgo(5), starred: false, progress: .polishing, category: .greetings),
            FlashcardModel(term: .goodNight, id: UUID(), lastSucceeded: daysAgo(1), starred: false, progress: .mastered, category: .greetings),
            FlashcardModel(term: .seeYouLater, id: UUID(), lastSucceeded: nil, starred: false, progress: .new, category: .greetings),
        ]

        // Numbers
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

        // Feelings / Emotions (replacing Colors, which has no Term enum equivalent)
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

        // Family
        cards += [
            FlashcardModel(term: .mother, id: UUID(), lastSucceeded: daysAgo(9), starred: false, progress: .learning, category: .family),
            FlashcardModel(term: .father, id: UUID(), lastSucceeded: daysAgo(4), starred: false, progress: .polishing, category: .family),
            FlashcardModel(term: .brother, id: UUID(), lastSucceeded: nil, starred: false, progress: .new, category: .family),
            FlashcardModel(term: .sister, id: UUID(), lastSucceeded: daysAgo(1), starred: false, progress: .mastered, category: .family),
            FlashcardModel(term: .grandmother, id: UUID(), lastSucceeded: daysAgo(20), starred: false, progress: .learning, category: .family),
            FlashcardModel(term: .grandfather, id: UUID(), lastSucceeded: daysAgo(2), starred: false, progress: .polishing, category: .family),
        ]

        // Verbs
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
        var distractors = pool
            .filter { $0.id != card.id }
            .map { $0.term.displayName }
            .shuffled()
            .prefix(max(0, count - 1))

        var opts = Array(distractors)
        opts.append(card.term.displayName)
        return Array(Set(opts)).shuffled()
    }
}

#Preview {
    // Dummy flashcard for preview
    let dummyCard = FlashcardModel(
        term: .hello,
        id: UUID(),
        category: .greetings
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
