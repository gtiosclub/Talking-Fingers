//
//  PracticeSessionView.swift
//  Talking Fingers
//
//  Session that runs AISentenceSigningView for each sentence, then shows
//  completion screen with Extend (add 5 more) / Finish (return to Saved Practice).
//

import SwiftUI

struct PracticeSessionView: View {
    @Binding var sentences: [AISentenceModel]
    var onFinish: () -> Void
    var onExtend: () async -> Void

    @State private var currentSentenceIndex: Int
    @State private var isExtending: Bool = false

    /// Shared camera VM kept alive for the whole session so sentence changes
    /// don't tear the AVCaptureSession down and build a new one (which was
    /// causing visible lag on the camera feed + overlay after the first
    /// sentence transition).
    @State private var sessionCameraVM = CameraVM()

    private let completionBlue = Color(hex: "#3A5A9C")
    private let scoreRing = Color(hex: "#F0DEB0")
    private let scoreNumber = Color(hex: "#E8A317")
    private let accentYellow = Color(hex: "#E8A317")
    private let barBlue = Color(hex: "#58A0DA")
    private let barTrack = Color(hex: "#A9CEEC26")
    private let extendFill = Color(hex: "#D6ECC4")
    private let extendText = Color(hex: "#3D6B2A")
    private let finishGreen = Color(hex: "#97C171")

    init(
        sentences: Binding<[AISentenceModel]>,
        initialSentenceIndex: Int = 0,
        onFinish: @escaping () -> Void,
        onExtend: @escaping () async -> Void
    ) {
        self._sentences = sentences
        self.onFinish = onFinish
        self.onExtend = onExtend
        let count = sentences.wrappedValue.count
        let clamped = min(max(0, initialSentenceIndex), count)
        self._currentSentenceIndex = State(initialValue: clamped)
    }

    private var sessionProgress: Double {
        guard !sentences.isEmpty else { return 0 }
        return Double(currentSentenceIndex + 1) / Double(sentences.count)
    }

    /// Categories touched by gloss in this session (stable order).
    private var sessionCategories: [TermCategory] {
        let present = Set(sentences.flatMap { $0.gloss.map(\.category) })
        return TermCategory.allCases.filter { present.contains($0) }
    }

    private func progressInCategory(_ category: TermCategory) -> Double {
        let relevant = sentences.filter { sentence in
            sentence.gloss.contains { $0.category == category }
        }
        guard !relevant.isEmpty else { return 0 }
        return Double(relevant.filter(\.completed).count) / Double(relevant.count)
    }

    private var overallSessionProgress: Double {
        guard !sentences.isEmpty else { return 0 }
        return Double(sentences.filter(\.completed).count) / Double(sentences.count)
    }

    private var encouragementHeadline: String {
        let ratio = overallSessionProgress
        if ratio >= 1.0 {
            return "🔥 You're heating up!"
        }
        if ratio >= 0.5 {
            return "🔥 Great momentum!"
        }
        return "💪 Keep practicing!"
    }

    private func markCurrentSentenceCompletedAndAdvance() {
        withAnimation {
            if sentences.indices.contains(currentSentenceIndex) {
                var updated = sentences
                updated[currentSentenceIndex].completed = true
                sentences = updated
            }
            currentSentenceIndex += 1
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onFinish) {
                    HStack(spacing: 6) {
                        Image(systemName: "door.left.hand.open")
                            .font(.body.weight(.medium))
                        Text("Leave")
                    }
                    .font(.body)
                    .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 4)

            if currentSentenceIndex < sentences.count {
                let currentSentence = sentences[currentSentenceIndex]

                if currentSentence.practiceType == .comprehension {
                    AISentenceComprehensionView(
                        sentenceModel: currentSentence,
                        sessionProgress: sessionProgress,
                        onSentenceComplete: {
                            markCurrentSentenceCompletedAndAdvance()
                        }
                    )
                    .id(currentSentenceIndex)
                } else {
                    AISentenceSigningView(
                        sentenceModel: currentSentence,
                        sessionProgress: sessionProgress,
                        onSentenceComplete: {
                            markCurrentSentenceCompletedAndAdvance()
                        },
                        externalCameraVM: sessionCameraVM
                    )
                    .id(currentSentenceIndex)
                }
            } else {
                completionContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            #if os(iOS)
            Color(uiColor: .systemBackground)
            #elseif os(macOS)
            Color(nsColor: .windowBackgroundColor)
            #else
            Color.white
            #endif
        }
        .onAppear {
            #if os(macOS)
            sessionCameraVM.isMirrored = true
            #endif
            sessionCameraVM.checkPermission()
        }
        .task {
            try? await Task.sleep(for: .milliseconds(300))
            sessionCameraVM.start()
        }
        .onDisappear {
            sessionCameraVM.stop()
        }
    }

    private var completionContent: some View {
        VStack(spacing: 0) {
            CustomProgressBar(
                progress: 1.0,
                trackColor: barTrack,
                trackOpacity: 1.0,
                fillColor: barBlue,
                barHeight: 10
            )
            .padding(.horizontal, 24)
            .padding(.top, 12)

            Spacer(minLength: 12)

            Text("Practice completed!")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(completionBlue)
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            Spacer(minLength: 20)

            ZStack {
                Circle()
                    .stroke(scoreRing, lineWidth: 14)
                    .frame(width: 196, height: 196)
                Text("100")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundColor(scoreNumber)
            }

            Spacer(minLength: 24)

            performanceCard
                .padding(.horizontal, 24)

            Spacer()

            HStack(spacing: 14) {
                Button(action: extendTapped) {
                    Text("Extend")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(extendText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(extendFill)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isExtending)

                Button(action: onFinish) {
                    Text("Finish")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(finishGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
    }

    private var performanceCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(encouragementHeadline)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(accentYellow)

            if sessionCategories.isEmpty {
                categoryRow(title: "Practice", progress: overallSessionProgress)
            } else {
                ForEach(sessionCategories, id: \.self) { category in
                    categoryRow(title: category.displayName, progress: progressInCategory(category))
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.gray.opacity(0.35), lineWidth: 1)
        )
    }

    private func categoryRow(title: String, progress: Double) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(barTrack)
                            .frame(height: 8)
                        Capsule()
                            .fill(barBlue)
                            .frame(width: max(8, CGFloat(progress) * geo.size.width), height: 8)
                    }
                }
                .frame(height: 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "medal.fill")
                .font(.system(size: 22))
                .foregroundColor(barBlue.opacity(0.85))
                .frame(width: 28, alignment: .center)
        }
    }

    private func extendTapped() {
        guard !isExtending else { return }
        isExtending = true
        Task {
            await onExtend()
            await MainActor.run {
                isExtending = false
            }
        }
    }
}
