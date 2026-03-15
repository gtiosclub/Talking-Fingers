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
        .fullScreenCover(isPresented: $showDashboard) {
            DashboardView()
        }
        .fullScreenCover(isPresented: $showLearn) {
            LearnModeView(
                vm: LearnModeVM(flashcard: learnFlashcard),
                progress: learnProgress,
                onClose: {
                    // Dismiss LearnModeView and return to StartCardComponent
                    showLearn = false
                }
            )
        }
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
