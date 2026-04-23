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
    /// Random category bar targets (0…1); animated values climb from 0 on the completion screen.
    @State private var completionBarAnimatedProgress: [String: Double] = [:]

    /// Shared camera VM kept alive for the whole session so sentence changes
    /// don't tear the AVCaptureSession down and build a new one (which was
    /// causing visible lag on the camera feed + overlay after the first
    /// sentence transition).
    @State private var sessionCameraVM = CameraVM()

    private let barBlue = Color(hex: "#58A0DA")
    private let barTrack = Color(hex: "#A9CEEC26")
    private let extendFill = Color(hex: "#D6ECC4")
    private let extendText = Color(hex: "#3D6B2A")
    private let finishGreen = Color(hex: "#97C171")
    private let subtitleBlue = Color(hex: "#2A7BBC")

    // MARK: Completion screen — score tier (same cutoffs: ≥80 / ≥60 / else)
    private let completionCardShadow = Color.black.opacity(0.12)
    private let completionAccentHigh = Color(hex: "#71A046")
    private let completionAccentMed = Color(hex: "#ECA509")
    private let completionAccentLow = Color(hex: "#F46769")
    /// Fills only the large session score ring (softer than accent).
    private let completionScoreRingFillHigh = Color(hex: "#B1D094")
    private let completionScoreRingFillMed = Color(hex: "#FACD6B")
    private let completionScoreRingFillLow = Color(hex: "#FF6F71")
    private let completionScoreInnerText = Color.white
    private let completionGradientTopHigh = Color(hex: "#F0F6EA")
    private let completionGradientBottomHigh = Color(hex: "#FAFCF8")
    private let completionGradientTopMed = Color(hex: "#FFF5E0")
    private let completionGradientBottomMed = Color(hex: "#FFFCF5")
    private let completionGradientTopLow = Color(hex: "#FFE0E0")
    private let completionGradientBottomLow = Color(hex: "#FFF5F5")

    private enum SessionScoreTier {
        case high, medium, low

        init(accuracy: Double) {
            if accuracy >= 80 { self = .high }
            else if accuracy >= 60 { self = .medium }
            else { self = .low }
        }

        var bloomMessage: String {
            switch self {
            case .high: return "You're in full bloom!"
            case .medium: return "You're growing!"
            case .low: return "You're getting there!"
            }
        }
    }

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

    private var sessionScoreTier: SessionScoreTier {
        SessionScoreTier(accuracy: sessionAccuracy)
    }

    private var completionBarRowSpecs: [(key: String, title: String)] {
        let fromDisplay = displayCategories
        if !fromDisplay.isEmpty {
            return fromDisplay.map { ($0.rawValue, $0.displayName) }
        }
        if !sessionCategories.isEmpty {
            return sessionCategories.map { ($0.rawValue, $0.displayName) }
        }
        return [("practice", "Practice")]
    }

    private func runCompletionBarIntroAnimation() {
        let specs = completionBarRowSpecs
        var targets: [String: Double] = [:]
        for spec in specs {
            targets[spec.key] = Double.random(in: 0.18 ... 0.97)
        }
        completionBarAnimatedProgress = Dictionary(uniqueKeysWithValues: specs.map { ($0.key, 0) })
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 1.05)) {
                completionBarAnimatedProgress = targets
            }
        }
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
            Spacer(minLength: 8)

            completionResultsCard
                .padding(.horizontal, 20)

            Spacer(minLength: 12)

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
        .onAppear {
            runCompletionBarIntroAnimation()
        }
        .onChange(of: currentSentenceIndex) { _, newValue in
            if newValue >= sentences.count {
                runCompletionBarIntroAnimation()
            }
        }
    }

    private var completionResultsCard: some View {
        let tier = sessionScoreTier
        let scoreInt = Int(min(100, max(0, sessionAccuracy.rounded())))

        return VStack(spacing: 0) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(completionScoreRingFill(for: tier))
                        .frame(width: 180, height: 180)

                    VStack(spacing: 2) {
                        Text("\(scoreInt)")
                            .font(.system(size: 76, weight: .semibold))
                            .foregroundColor(completionScoreInnerText)
                        Text("of 100")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(completionScoreInnerText.opacity(0.92))
                    }
                }

                Text(completionTopMessage(for: tier))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(completionTierAccent(for: tier))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 10)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            .background { completionTopSectionBackground(for: tier) }

            VStack(alignment: .leading, spacing: 18) {
                Text(tier.bloomMessage)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(completionTierAccent(for: tier))

                ForEach(completionBarRowSpecs, id: \.key) { spec in
                    completionAnimatedCategoryRow(
                        tier: tier,
                        title: spec.title,
                        progress: completionBarAnimatedProgress[spec.key] ?? 0
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color(hex: "#F0F0F0"), lineWidth: 1.5)
        )
    }

    @ViewBuilder
    private func completionTopSectionBackground(for tier: SessionScoreTier) -> some View {
        let gradient = LinearGradient(
            colors: completionGradientPair(for: tier),
            startPoint: .top,
            endPoint: .bottom
        )
        gradient
    }

    private func completionGradientPair(for tier: SessionScoreTier) -> [Color] {
        switch tier {
        case .high:
            return [completionGradientTopHigh, completionGradientBottomHigh]
        case .medium:
            return [completionGradientTopMed, completionGradientBottomMed]
        case .low:
            return [completionGradientTopLow, completionGradientBottomLow]
        }
    }

    private func completionScoreRingFill(for tier: SessionScoreTier) -> Color {
        switch tier {
        case .high: return completionScoreRingFillHigh
        case .medium: return completionScoreRingFillMed
        case .low: return completionScoreRingFillLow
        }
    }

    /// Message shown directly below the large score ring.
    private func completionTopMessage(for tier: SessionScoreTier) -> String {
        switch tier {
        case .high: return "Superb work!"
        case .medium: return "Solid stuff!"
        case .low: return "Room to improve!"
        }
    }

    private func completionTierAccent(for tier: SessionScoreTier) -> Color {
        switch tier {
        case .high: return completionAccentHigh
        case .medium: return completionAccentMed
        case .low: return completionAccentLow
        }
    }

    private func completionBarTrackColor(for tier: SessionScoreTier) -> Color {
        completionTierAccent(for: tier).opacity(0.22)
    }

    private func completionAnimatedCategoryRow(
        tier: SessionScoreTier,
        title: String,
        progress: Double
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(hex: "#464646"))

            HStack(alignment: .center, spacing: 12) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(hex: "#A9CEEC26"))
                            .frame(height: 8)
                        Capsule()
                            .fill(Color(hex: "#58A0DA"))
                            .frame(width: max(6, CGFloat(progress) * geo.size.width), height: 8)
                    }
                }
                .frame(height: 8)

                Image(systemName: "medal.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(hex: "#A9CEEC"))
                    .frame(width: 22, alignment: .center)
            }
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
