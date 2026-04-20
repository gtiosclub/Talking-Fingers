//
//  VisionExerciseView.swift
//  Talking Fingers
//

import SwiftUI
import SwiftData

/// Camera-based exercise view that grades the user's sign in real time.
/// Mirrors the layout and top-bar conventions of `MultipleChoice` and `LearnModeView`.
struct VisionExerciseView: View {

    // MARK: - Configuration
    let currentCard: FlashcardModel
    var progress: Double
    @Binding var inputMode: ExerciseInputMode
    /// Called when the user taps Leave; on macOS (inline) this replaces dismiss().
    var onLeave: (() -> Void)? = nil
    var onNext: (FlashcardModel) -> Void = { _ in }

    // MARK: - Environment
    @Environment(FlashcardVM.self) private var flashcardVM
    @Environment(\.dismiss) private var dismiss
    @Environment(SwiftDataVM.self) private var dataVM
    @Query private var users: [User]

    // MARK: - State
    @State private var isSaved: Bool = false
    @State private var showHintPopup: Bool = false
    @State private var showStuckPopup: Bool = false
    @State private var isPassed: Bool = false
    @State private var confidenceScore: Double = 0
    /// Captured at runtime so the camera card scales to the available window/screen height.
    @State private var viewHeight: CGFloat = 600

    // MARK: - Constants
    private let passThreshold: Double = 70
    private let tfGreen      = Color(red: 159/255, green: 192/255, blue: 122/255)
    private let tfGreenText  = Color(red: 82/255,  green: 106/255, blue: 54/255)

    /// 58 % of the view height, clamped so it never looks tiny on small phones or
    /// absurdly tall on large displays / macOS windows.
    private var cameraHeight: CGFloat {
        min(max(viewHeight * 0.58, 280), 560)
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            Color(hex: 0xFFFFFF).ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                ScrollView {
                    VStack(spacing: 20) {
                        cameraCard

                        if isPassed {
                            nextWordButton
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .frame(maxWidth: 1100)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .background(Color(hex: 0xFFFFFF))
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
        }
        // Capture the runtime view height so cameraHeight can adapt.
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { viewHeight = geo.size.height }
                    .onChange(of: geo.size.height) { _, h in viewHeight = h }
            }
        )
        // Hint popup
        .popupHost(isPresented: $showHintPopup) {
            HintPopUpComponent(
                hintText: hintText
            ) {
                showHintPopup = false
            }
        }
        // Stuck popup
        .popupHost(isPresented: $showStuckPopup) {
            StuckPopUpComponent(
                onKeepTrying: {
                    showStuckPopup = false
                },
                onNextWord: {
                    showStuckPopup = false
                    handleSkip()
                }
            )
        }
        // Reset local state whenever the card changes
        .onChange(of: currentCard.id) { _, _ in
            isPassed = false
            confidenceScore = 0
            isSaved = false
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

    // MARK: - Camera Card
    private var cameraCard: some View {
        VStack(spacing: 16) {

            // Word title
            Text(currentCard.term.displayName)
                .font(.system(size: 45, weight: .bold))
                .padding(.top, 4)

            // Action buttons row: save | stuck | hint
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
                    showStuckPopup = true
                } label: {
                    Image(systemName: "exclamationmark")
                        .foregroundColor(.orange)
                        .padding(14)
                        .background(
                            Circle().fill(Color.orange.opacity(showStuckPopup ? 0.3 : 0.15))
                        )
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
                        .background(
                            Circle().fill(Color.orange.opacity(showHintPopup ? 0.3 : 0.2))
                        )
                        .scaleEffect(1.1)
                }
                .buttonStyle(.plain)
            }

            // Live graded camera feed
            SigningPracticeView(signName: currentCard.term.displayName,
                                onConfidenceChange: { score in
                confidenceScore = score
                if score >= passThreshold && !isPassed {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isPassed = true
                    }
                }
            })
            .frame(height: cameraHeight)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
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

    // MARK: - Next Word Button
    private var nextWordButton: some View {
        Button {
            handlePass()
        } label: {
            Text("Next Word")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(tfGreen)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers
    private var hintText: String {
        "Focus on the handshape for '\(currentCard.term.displayName)'"
    }

    private func handlePass() {
        if let currentUser = users.first {
            flashcardVM.handleAnswer(for: currentCard, correct: true, user: currentUser, dataVM: dataVM)
        }
        advanceToNext()
    }

    private func handleSkip() {
        if let currentUser = users.first {
            flashcardVM.handleAnswer(for: currentCard, correct: false, user: currentUser, dataVM: dataVM)
        }
        advanceToNext()
    }

    private func advanceToNext() {
        isPassed = false
        confidenceScore = 0
        if let next = flashcardVM.nextCard() {
            onNext(next)
        } else {
            #if os(macOS)
            onLeave?()
            #else
            dismiss()
            #endif
        }
    }
}

// MARK: - Stuck Popup

private struct StuckPopUpComponent: View {
    let onKeepTrying: () -> Void
    let onNextWord: () -> Void

    private let tfGreen = Color(red: 159/255, green: 192/255, blue: 122/255)

    var body: some View {
        VStack(spacing: 20) {

            Text("Stuck?")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color(red: 0.93, green: 0.78, blue: 0.50))
                .padding(.top, 8)

            Text("Would you like to move on?")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.black.opacity(0.8))
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Button(action: onKeepTrying) {
                    Text("Keep Trying")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.45), lineWidth: 1.5)
                                )
                        )
                }
                .buttonStyle(.plain)

                Button(action: onNextWord) {
                    Text("Next Word")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(tfGreen)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 4)
        }
        .padding(28)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.15), radius: 20)
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
}

// MARK: - Preview

#Preview("Vision Exercise") {
    let vm = FlashcardVM()
    vm.flashcards = FlashcardVM.dummyFlashcards
    let card = FlashcardModel(term: .hello, id: UUID(), category: .greetings)
    return VisionExerciseView(
        currentCard: card,
        progress: 0.3,
        inputMode: .constant(.camera),
        onNext: { _ in }
    )
    .environment(vm)
    .environment(SwiftDataVM())
}
