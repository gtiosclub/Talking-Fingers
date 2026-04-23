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
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        SessionTopBar(
            progress: progress,
            onLeave: {
                #if os(macOS)
                onLeave?()
                #else
                dismiss()
                #endif
            }
        ) {
            ExerciseSettingsMenu(mode: $inputMode)
        }
    }

    // MARK: - Camera Card
    private var cameraCard: some View {
        SigningCameraCard(
            word: currentCard.term.displayName,
            cameraHeight: cameraHeight,
            isHintActive: showHintPopup,
            isStuckActive: showStuckPopup,
            onConfidenceChange: { score in
                confidenceScore = score
                if score >= passThreshold && !isPassed {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isPassed = true
                    }
                }
            },
            onHintTap: { showHintPopup = true },
            onStuckTap: { showStuckPopup = true }
        )
        .id(currentCard.id)
    }

    // MARK: - Next Word Button
    private var nextWordButton: some View {
        Button {
            handlePass()
        } label: {
            Text("Next Word")
                .font(.jakartaHeadline)
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

// MARK: - Session Top Bar

/// Progress bar + Leave button shared by every exercise / learn screen.
/// Pass a `@ViewBuilder` trailing block to add items (e.g. `ExerciseSettingsMenu`)
/// next to the progress bar; omit it for just the bar.
struct SessionTopBar<Trailing: View>: View {
    var progress: Double
    var onLeave: () -> Void
    private let trailing: Trailing

    init(
        progress: Double,
        onLeave: @escaping () -> Void,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.progress = progress
        self.onLeave = onLeave
        self.trailing = trailing()
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button { onLeave() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.jakarta(size: 16, weight: .medium))
                        Text("Leave")
                            .font(.jakarta(size: 16, weight: .medium))
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

                trailing
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 10)
    }
}

extension SessionTopBar where Trailing == EmptyView {
    init(progress: Double, onLeave: @escaping () -> Void) {
        self.init(progress: progress, onLeave: onLeave, trailing: { EmptyView() })
    }
}

// MARK: - Shared Camera Card

/// Reusable camera card used by both VisionExerciseView (all buttons shown) and
/// LearnModeView (save + stuck hidden). Pass showSaveButton/showStuckButton = false
/// to suppress the corresponding action button.
struct SigningCameraCard: View {
    let word: String
    var showSaveButton: Bool = true
    var showStuckButton: Bool = true
    var showWordTitle: Bool = true
    /// Fixed height for the live camera feed. Pass nil to fill available space.
    var cameraHeight: CGFloat? = nil
    var isHintActive: Bool = false
    var isStuckActive: Bool = false
    var onConfidenceChange: (Double) -> Void = { _ in }
    var onHintTap: () -> Void = {}
    var onStuckTap: () -> Void = {}

    @State private var isSaved: Bool = false

    private let tfGreen     = Color(red: 159/255, green: 192/255, blue: 122/255)
    private let tfGreenText = Color(red: 82/255,  green: 106/255, blue: 54/255)
    private let circleSize: CGFloat = 48

    var body: some View {
        VStack(spacing: 16) {
            if showWordTitle {
                Text(word)
                    .font(.jakarta(size: 45, weight: .bold))
                    .padding(.top, 4)
            }

            HStack {
                if showSaveButton {
                    Button { isSaved.toggle() } label: {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            .foregroundColor(tfGreenText)
                            .frame(width: circleSize, height: circleSize)
                            .background(Circle().fill(tfGreen.opacity(0.25)))
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                HStack(spacing: 12) {
                    if showStuckButton {
                        Button { onStuckTap() } label: {
                            Image(systemName: "exclamationmark")
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                                .frame(width: circleSize, height: circleSize)
                                .background(Circle().fill(Color.orange.opacity(isStuckActive ? 0.3 : 0.15)))
                        }
                        .buttonStyle(.plain)
                    }

                    Button { onHintTap() } label: {
                        Image(systemName: isHintActive ? "lightbulb.max.fill" : "lightbulb.max")
                            .foregroundColor(.orange)
                            .frame(width: circleSize, height: circleSize)
                            .background(Circle().fill(Color.orange.opacity(isHintActive ? 0.3 : 0.2)))
                    }
                    .buttonStyle(.plain)
                }
            }

            SigningPracticeView(signName: word, onConfidenceChange: onConfidenceChange)
                .frame(
                    maxWidth: .infinity,
                    minHeight: cameraHeight,
                    maxHeight: cameraHeight ?? .infinity
                )
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
}

// MARK: - Stuck Popup

private struct StuckPopUpComponent: View {
    let onKeepTrying: () -> Void
    let onNextWord: () -> Void

    private let tfGreen = Color(red: 159/255, green: 192/255, blue: 122/255)

    var body: some View {
        VStack(spacing: 20) {

            Text("Stuck?")
                .font(.jakarta(size: 28, weight: .bold))
                .foregroundColor(Color(red: 0.93, green: 0.78, blue: 0.50))
                .padding(.top, 8)

            Text("Would you like to move on?")
                .font(.jakarta(size: 20, weight: .medium))
                .foregroundColor(.black.opacity(0.8))
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Button(action: onKeepTrying) {
                    Text("Keep Trying")
                        .font(.jakarta(size: 16, weight: .semibold))
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
                        .font(.jakarta(size: 16, weight: .semibold))
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
