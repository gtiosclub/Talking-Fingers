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
    var practiceTitle: String
    var selectedCategories: Set<TermCategory>?
    var onFinish: () -> Void
    var onExtend: () async -> Void

    @State private var currentSentenceIndex: Int
    @State private var isExtending: Bool = false
    @State private var showPracticeEntry: Bool = true
    @State private var signingSubtitle: String = "New sentence!"
    @State private var signingPageIndex: Int = 1
    @State private var showSigningSentenceCompletionOverlay: Bool = false
    @State private var signingSentenceAverageScore: Double = 0
    @State private var isSigningSentenceFavorited: Bool = false

    /// Shared camera VM kept alive for the whole session so sentence changes
    /// don't tear the AVCaptureSession down and build a new one (which was
    /// causing visible lag on the camera feed + overlay after the first
    /// sentence transition).
    @State private var sessionCameraVM = CameraVM()

    private let completionBlue = Color(hex: "#3A5A9C")
    private let accentYellow = Color(hex: "#E8A317")
    private let barBlue = Color(hex: "#58A0DA")
    private let barTrack = Color(hex: "#A9CEEC26")
    private let extendFill = Color(hex: "#D6ECC4")
    private let extendText = Color(hex: "#3D6B2A")
    private let finishGreen = Color(hex: "#97C171")
    private let subtitleBlue = Color(hex: "#2A7BBC")
    
    // Accuracy color scheme
    private let highAccuracyBg = Color(hex: "#EAF3E3")
    private let highAccuracyBorder = Color(hex: "#A8D4A0")
    private let highAccuracyText = Color(hex: "#4A7C3F")
    private let medAccuracyBg = Color(hex: "#FACD6B")
    private let medAccuracyBorder = Color(hex: "#E5B84A")
    private let medAccuracyText = Color(hex: "#8B6914")
    private let lowAccuracyBg = Color(hex: "#FA6B6E")
    private let lowAccuracyBorder = Color(hex: "#E55558")
    private let lowAccuracyText = Color(hex: "#A13B3D")

    init(
        sentences: Binding<[AISentenceModel]>,
        practiceTitle: String = "Practice",
        selectedCategories: Set<TermCategory>? = nil,
        initialSentenceIndex: Int = 0,
        onFinish: @escaping () -> Void,
        onExtend: @escaping () async -> Void
    ) {
        self._sentences = sentences
        self.practiceTitle = practiceTitle
        self.selectedCategories = selectedCategories
        self.onFinish = onFinish
        self.onExtend = onExtend
        let count = sentences.wrappedValue.count
        let clamped = min(max(0, initialSentenceIndex), count)
        self._currentSentenceIndex = State(initialValue: clamped)
        
        print("🟡 [PracticeSessionView] init called")
        print("   - practiceTitle: \(practiceTitle)")
        print("   - selectedCategories: \(selectedCategories?.map(\.rawValue) ?? ["nil"])")
        print("   - sentences count: \(count)")
        print("   - initialSentenceIndex: \(initialSentenceIndex) → clamped: \(clamped)")
    }

    private var sessionProgress: Double {
        guard !sentences.isEmpty else { return 0 }
        return Double(currentSentenceIndex) / Double(sentences.count)
    }

    /// Categories touched by gloss in this session (stable order).
    private var sessionCategories: [TermCategory] {
        let present = Set(sentences.flatMap { $0.gloss.map(\.category) })
        return TermCategory.allCases.filter { present.contains($0) }
    }

    private var displayCategories: [TermCategory] {
        if let selectedCategories, !selectedCategories.isEmpty {
            return TermCategory.allCases.filter { selectedCategories.contains($0) }
        }
        return sessionCategories
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

    private var remainingSentenceCount: Int {
        max(0, sentences.count - currentSentenceIndex)
    }

    private var entryModeIsComprehension: Bool {
        guard currentSentenceIndex < sentences.count else {
            return sentences.allSatisfy { $0.practiceType == .comprehension } && !sentences.isEmpty
        }
        return sentences[currentSentenceIndex].practiceType == .comprehension
    }

    private var entryFlowerAssetName: String {
        entryModeIsComprehension ? "SentencesComprehendFlowerFull" : "SentencesSignFlowerFull"
    }

    private var currentTopProgress: Double {
        if showPracticeEntry { return overallSessionProgress }
        if currentSentenceIndex < sentences.count {
            return min(1, sessionProgress + 0.03)
        }
        return 1
    }

    private var currentTopSubtitle: String {
        if showPracticeEntry { return "Here we go!" }
        if currentSentenceIndex >= sentences.count { return "Practice completed!" }
        if sentences[currentSentenceIndex].practiceType == .comprehension { return "New sentence!" }
        if signingPageIndex == 2 { return "" }
        return signingSubtitle
    }

    private var currentTopSubtitleColor: Color { subtitleBlue }

    /// Hide the session bar while on the live camera / per-word signing step;
    /// it returns on the sentence intro + gloss page (page 1) for the next sentence.
    private var shouldShowSessionProgressBar: Bool {
        if showPracticeEntry { return true }
        guard currentSentenceIndex < sentences.count else { return true }
        if sentences[currentSentenceIndex].practiceType == .comprehension { return true }
        return signingPageIndex != 2
    }

    private var primaryActionButtonTitle: String? {
        if showPracticeEntry { return "Start" }
        guard currentSentenceIndex < sentences.count else { return nil }
        let currentSentence = sentences[currentSentenceIndex]
        if currentSentence.practiceType != .comprehension && signingPageIndex == 1 {
            return "Continue"
        }
        return nil
    }
    
    private var sessionAccuracy: Double {
        let completedSentences = sentences.filter(\.completed)
        let accuracies = completedSentences.compactMap(\.accuracy)
        guard !accuracies.isEmpty else { return 0 }
        return accuracies.reduce(0, +) / Double(accuracies.count)
    }
    
    private var accuracyBackgroundColor: Color {
        if sessionAccuracy >= 80 { return highAccuracyBg }
        if sessionAccuracy >= 60 { return medAccuracyBg }
        return lowAccuracyBg
    }
    
    private var accuracyBorderColor: Color {
        if sessionAccuracy >= 80 { return highAccuracyBorder }
        if sessionAccuracy >= 60 { return medAccuracyBorder }
        return lowAccuracyBorder
    }
    
    private var accuracyTextColor: Color {
        if sessionAccuracy >= 80 { return highAccuracyText }
        if sessionAccuracy >= 60 { return medAccuracyText }
        return lowAccuracyText
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
            signingPageIndex = 1
            showSigningSentenceCompletionOverlay = false
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                HStack {
                    Button(action: onFinish) {
                        HStack(spacing: 6) {
                            Image(systemName: "door.left.hand.open")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "#B3B3B3"))
                            Text("Leave")
                                .foregroundColor(Color(hex: "#B3B3B3"))
                                .font(.system(size: 16, weight: .medium))
                        }
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text("Practice: \(practiceTitle)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#B3B3B3"))
                }
                .padding(.horizontal, 24)
                .padding(.top, 30)
                .padding(.bottom, 4)

                sessionTopChrome

                if showPracticeEntry {
                    PracticeEntryView(
                        practiceTitle: practiceTitle,
                        remainingSentenceCount: remainingSentenceCount,
                        categories: displayCategories,
                        flowerAssetName: entryFlowerAssetName
                    )
                } else if currentSentenceIndex < sentences.count {
                    if sentences[currentSentenceIndex].practiceType == .comprehension {
                        AISentenceComprehensionView(
                            sentenceModel: $sentences[currentSentenceIndex],
                            onSentenceComplete: {
                                markCurrentSentenceCompletedAndAdvance()
                            }
                        )
                        .id(currentSentenceIndex)
                    } else {
                        AISentenceSigningView(
                            sentenceModel: $sentences[currentSentenceIndex],
                            currentPage: $signingPageIndex,
                            onSentenceComplete: {
                                markCurrentSentenceCompletedAndAdvance()
                            },
                            onSentenceFinished: { average in
                                print("🟠 [PracticeSessionView] onSentenceFinished called - average: \(average)")
                                print("   - practiceTitle at this moment: \(practiceTitle)")
                                print("   - showPracticeEntry: \(showPracticeEntry)")
                                signingSentenceAverageScore = average
                                isSigningSentenceFavorited = false
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showSigningSentenceCompletionOverlay = true
                                }
                                print("🟠 [PracticeSessionView] set showSigningSentenceCompletionOverlay = true")
                            },
                            onSubtitleChange: { subtitle in
                                signingSubtitle = subtitle
                            },
                            glossUniformColor: showSigningSentenceCompletionOverlay
                                ? SentenceCompletionOverlay.glossAndButtonColor(for: signingSentenceAverageScore)
                                : nil,
                            externalCameraVM: sessionCameraVM
                        )
                        .id(currentSentenceIndex)
                    }
                } else {
                    completionContent
                }

                if let primaryActionButtonTitle {
                    Button(action: handlePrimaryActionButtonTap) {
                        Text(primaryActionButtonTitle)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(finishGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(!showSigningSentenceCompletionOverlay)

            if showSigningSentenceCompletionOverlay {
                SentenceCompletionOverlay(
                    averageScore: signingSentenceAverageScore,
                    isFavorited: $isSigningSentenceFavorited,
                    onContinue: continueAfterSigningSentenceOverlay
                )
                .frame(maxWidth: .infinity)
                .ignoresSafeArea(edges: .bottom)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            #if os(iOS)
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            #elseif os(macOS)
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()
            #else
            Color.white
                .ignoresSafeArea()
            #endif
        }
        .onAppear {
            print("🟡 [PracticeSessionView] onAppear - practiceTitle: \(practiceTitle), showPracticeEntry: \(showPracticeEntry)")
            #if os(macOS)
            sessionCameraVM.isMirrored = true
            #endif
            signingPageIndex = 1
            sessionCameraVM.checkPermission()
        }
        .task {
            try? await Task.sleep(for: .milliseconds(300))
            sessionCameraVM.start()
        }
        .onDisappear {
            print("🟡 [PracticeSessionView] onDisappear - practiceTitle: \(practiceTitle)")
            sessionCameraVM.stop()
        }
    }

    private var completionContent: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)

            Text("Practice completed!")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(completionBlue)
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            Spacer(minLength: 20)

            ZStack {
                Circle()
                    .fill(accuracyBackgroundColor)
                    .frame(width: 196, height: 196)
                
                Circle()
                    .stroke(accuracyBorderColor, lineWidth: 8)
                    .frame(width: 196, height: 196)
                
                Text("\(Int(sessionAccuracy.rounded()))")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundColor(accuracyTextColor)
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

    private var sessionTopChrome: some View {
        Group {
            if shouldShowSessionProgressBar || !currentTopSubtitle.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    if shouldShowSessionProgressBar {
                        CustomProgressBar(
                            progress: currentTopProgress,
                            trackColor: barTrack,
                            trackOpacity: 1.0,
                            fillColor: barBlue,
                            barHeight: 10
                        )
                    }

                    if !currentTopSubtitle.isEmpty {
                        Text(currentTopSubtitle)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(currentTopSubtitleColor)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
            }
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
                signingPageIndex = 1
                showPracticeEntry = true
                showSigningSentenceCompletionOverlay = false
            }
        }
    }

    private func handlePrimaryActionButtonTap() {
        if showPracticeEntry {
            print("🟡 [PracticeSessionView] Start tapped - transitioning from entry to signing")
            print("   - practiceTitle: \(practiceTitle)")
            print("   - selectedCategories: \(selectedCategories?.map(\.rawValue) ?? ["nil"])")
            signingSubtitle = "New sentence!"
            signingPageIndex = 1
            showPracticeEntry = false
            return
        }

        guard currentSentenceIndex < sentences.count else { return }
        if sentences[currentSentenceIndex].practiceType != .comprehension && signingPageIndex == 1 {
            withAnimation {
                signingPageIndex = 2
            }
        }
    }

    private func continueAfterSigningSentenceOverlay() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showSigningSentenceCompletionOverlay = false
        }
        markCurrentSentenceCompletedAndAdvance()
    }
}
