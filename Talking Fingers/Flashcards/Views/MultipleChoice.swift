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

    // MARK: - State
    @State private var selectedAnswer: String? = nil
    @State private var isSaved: Bool = false
    @State private var showHintPopup: Bool = false
    @State private var showCorrectPopup: Bool = false
    @State private var showIncorrectPopup: Bool = false
    @Environment(\.dismiss) private var dismiss

    // Progress (0.0 – 1.0) — in a real app this would come from a parent view model
    var progress: Double = 0.15

    // MARK: - Body
    var body: some View {
        ZStack {
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
                }

                // ── Submit ─────────────────────────────────────────────────
                submitButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                    .padding(.top, 12)
            }
            .background(Color(.systemGroupedBackground))
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
        // Correct answer popup (redesigned to match screenshot)
        .popupHost(isPresented: $showCorrectPopup) {
            CorrectResultPopUpComponent(
                message: explanationText,
                onNext: {
                    showCorrectPopup = false
                }
            )
        }
        // Incorrect answer popup (new)
        .popupHost(isPresented: $showIncorrectPopup) {
            IncorrectResultPopUpComponent(
                message: explanationText,
                onNext: {
                    showIncorrectPopup = false
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
                        .foregroundColor(isSaved ? .white : Color(.label))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(isSaved ? Color.green : Color(.systemGray5))
                        )
                }

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showHintPopup = true
                    }
                } label: {
                    Image(systemName: "lightbulb.fill")
                        .font(.title3)
                        .foregroundColor(.orange)
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

    // MARK: - Option Row
    @ViewBuilder
    private func optionRow(_ option: String) -> some View {
        let isSelected = selectedAnswer == option

        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedAnswer = option
            }
        } label: {
            HStack {
                Text(option)
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
                .padding(.vertical, 18)
                .background(
                    Capsule()
                        .fill(selectedAnswer == nil
                              ? Color.green.opacity(0.6)
                              : Color.green)
                )
        }
        .disabled(selectedAnswer == nil)
        .animation(.easeInOut(duration: 0.2), value: selectedAnswer)
    }

    private func handleSubmission() {
        guard let selected = selectedAnswer else { return }
        if selected == correctAnswer {
            withAnimation(.easeInOut(duration: 0.25)) {
                showCorrectPopup = true
            }
        } else {
            withAnimation(.easeInOut(duration: 0.25)) {
                showIncorrectPopup = true
            }
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
            titleColor: Color.orange,
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
            titleColor: Color.orange,
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
                    .background(Color.white)
                    .foregroundColor(.gray)
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

// MARK: - Preview
#Preview {
    MultipleChoice(
        question: "What sign is being shown?",
        imageName: "greetingsIllustration",           // replace with your asset name
        options: ["Hello", "Goodbye", "Wassup", "See you"],
        correctAnswer: "Hello",
        explanationText: "People often confuse this sign with Goodbye because the hand motion looks similar at a glance."
    )
}
