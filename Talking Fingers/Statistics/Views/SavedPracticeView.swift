import SwiftUI
import SwiftData

struct SavedPracticeView: View {
    @Environment(SwiftDataVM.self) private var dataVM
    @Query(sort: \SavedPracticeModel.date, order: .reverse) private var savedSessions: [SavedPracticeModel]

    @State private var expandedCardID: UUID?
    @State private var createPracticeSheetMode: CreatePracticeSheetMode?
    @State private var showSessionView = false
    @State private var sessionSentences: [AISentenceModel] = []
    @State private var lastCategories: Set<TermCategory>?
    @State private var lastPracticeTitle: String = ""
    @State private var lastModeSelection = PracticeModeSelection(signing: true, comprehension: false)
    @State private var savedSessionStartSentenceIndex: Int = 0
    @State private var practiceSessionIdentity = UUID()
    @State private var shouldPersistSessionOnFinish = true
    @State private var isExistingSavedPractice = false

    private func displayTitle(for session: SavedPracticeModel) -> String {
        if let t = session.title?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty {
            return t
        }
        return session.categories.joined(separator: " + ").capitalized
    }

    private func trainingItem(for session: SavedPracticeModel) -> TrainingItem {
        let completedCount = session.sentences.filter(\.completed).count
        let totalCount = session.sentences.count
        let isComplete = completedCount == totalCount && totalCount > 0
        let sessionModeSelection = modeSelection(for: session)

        let completedSentences = session.sentences.filter(\.completed)
        let accuracies = completedSentences.compactMap(\.accuracy)
        let averageAccuracy: Double? = {
            guard isComplete, !accuracies.isEmpty else { return nil }
            return accuracies.reduce(0, +) / Double(accuracies.count)
        }()
        let completionProgress: Double = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0

        return TrainingItem(
            id: session.id,
            title: displayTitle(for: session),
            subtitle: session.date.formatted(.dateTime.month(.abbreviated).day().hour().minute()),
            accuracy: averageAccuracy,
            isComplete: isComplete,
            completionProgress: completionProgress,
            iconName: sessionModeSelection.comprehension && !sessionModeSelection.signing ? "eye" : "hand.wave"
        )
    }

    var body: some View {
        mainContent
            .sheet(item: $createPracticeSheetMode) { sheetMode in
            let initialModeSelection = sheetMode.modeSelection
            GenerateSentencesView(initialModeSelection: initialModeSelection) { sentences, categories, practiceTitle in
                print("🟢 [SavedPracticeView] Generation callback fired")
                print("   - practiceTitle: \(practiceTitle)")
                print("   - categories: \(categories.map(\.rawValue))")
                print("   - sentences count: \(sentences.count)")
                lastModeSelection = initialModeSelection
                lastCategories = categories
                lastPracticeTitle = practiceTitle
                sessionSentences = sentences
                savedSessionStartSentenceIndex = 0
                practiceSessionIdentity = UUID()
                shouldPersistSessionOnFinish = true
                isExistingSavedPractice = false
                print("🟢 [SavedPracticeView] State updated, dismissing sheet")
                createPracticeSheetMode = nil
                // Wait for the sheet dismissal animation to fully complete before
                // presenting the full screen cover. This prevents SwiftUI from
                // capturing stale state values during the presentation transition.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    print("🟢 [SavedPracticeView] After 0.4s delay, showing session view")
                    print("   - lastPracticeTitle: \(lastPracticeTitle)")
                    print("   - lastCategories: \(lastCategories?.map(\.rawValue) ?? [])")
                    showSessionView = true
                }
            }
            .presentationDetents([.height(460), .medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.white)
        }
        .universalFullScreenCover(isPresented: $showSessionView) {
            let _ = print("🔵 [SavedPracticeView] fullScreenCover content closure evaluated")
            let _ = print("   - lastPracticeTitle: '\(lastPracticeTitle)'")
            let _ = print("   - lastCategories: \(lastCategories?.map(\.rawValue) ?? ["nil"])")
            let _ = print("   - sessionSentences count: \(sessionSentences.count)")
            let _ = print("   - practiceSessionIdentity: \(practiceSessionIdentity)")
            PracticeSessionView(
                sentences: $sessionSentences,
                practiceTitle: lastPracticeTitle.isEmpty ? "Practice" : lastPracticeTitle,
                selectedCategories: lastCategories,
                initialSentenceIndex: savedSessionStartSentenceIndex,
                isExistingSavedPractice: isExistingSavedPractice,
                onFinish: { shouldSave in
                    if shouldSave && shouldPersistSessionOnFinish {
                        saveSessionToDatabase()
                    }
                    showSessionView = false
                },
                onExtend: {
                    guard let categories = lastCategories else { return }
                    do {
                        let more = try await GenerateSentencesView.generateSentences(
                            categories: categories,
                            modeSelection: lastModeSelection
                        )
                        await MainActor.run {
                            sessionSentences.append(contentsOf: more)
                            shouldPersistSessionOnFinish = true
                        }
                    } catch {
                        // Keep current session state if extend fails.
                    }
                }
            )
            .id(practiceSessionIdentity)
        }
        .onChange(of: showSessionView) { oldValue, newValue in
            print("🔵 [SavedPracticeView] showSessionView changed: \(oldValue) → \(newValue)")
        }
        .onChange(of: practiceSessionIdentity) { oldValue, newValue in
            print("🔵 [SavedPracticeView] practiceSessionIdentity changed: \(oldValue) → \(newValue)")
        }
        .onChange(of: sessionSentences.count) { oldValue, newValue in
            print("🔵 [SavedPracticeView] sessionSentences.count changed: \(oldValue) → \(newValue)")
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        #if os(macOS)
        // On macOS, only the "My trainings" list scrolls — the header,
        // "Start a new practice" cards, and section title stay pinned.
        VStack(alignment: .leading, spacing: 0) {
            headerSection

            VStack(alignment: .leading, spacing: 20) {
                startNewPracticeSection
                trainingSectionTitle
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            ScrollView(showsIndicators: false) {
                trainingCardsSection
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
            }
        }
        .macCentered(widthFraction: 0.75)
        // Edge-to-edge gradient behind the header on macOS, rendered
        // *outside* the centered content so it spans the full window width
        // and extends into the top safe area.
        .background(alignment: .top) {
            LinearGradient(
                colors: [Color(hex: "#EEF6FB"), Color(hex: "#DEECF8")],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 125)
            .frame(maxWidth: .infinity)
            .ignoresSafeArea(edges: .top)
        }
        .background(Color.white.ignoresSafeArea())
        #else
        VStack(alignment: .leading, spacing: 0) {
            headerSection

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    startNewPracticeSection
                    trainingSectionTitle
                    trainingCardsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
        }
        .background(Color.white.ignoresSafeArea())
        #endif
    }

    private var headerSection: some View {
        Text("Practice")
            .font(.jakarta(size: 32, weight: .bold))
            .foregroundColor(Color(hex: "#2A7BBC"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            #if os(macOS)
            .padding(.top, 80)
            #else
            .padding(.top, 8)
            .padding(.bottom, 14)
            #endif
            #if os(iOS)
            .background(
                LinearGradient(
                    colors: [Color(hex: "#EEF6FB"), Color(hex: "#DEECF8")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 125)
                .ignoresSafeArea(edges: .top),
                alignment: .top
            )
            #endif
    }

    private var startNewPracticeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Start a new practice")
                .font(.jakarta(size: 20, weight: .semibold))
                .foregroundColor(.black.opacity(0.78))

            #if os(macOS)
            // Side-by-side on the wider macOS layout
            HStack(spacing: 20) {
                PracticeModeCard(
                    title: "Sign",
                    subtitle: "Sign sentences to someone else",
                    tint: Color(hex: "#71A046"),
                    backgroundTop: Color(hex: "#F4F9F1"),
                    backgroundBottom: Color(hex: "#EAF3E3"),
                    border: Color(hex: "#ADCE8F"),
                    imageAssetName: "SentencesSignFlowerPartial",
                    placeholderOnLeading: true
                ) {
                    createPracticeSheetMode = .signing
                }

                PracticeModeCard(
                    title: "Comprehend",
                    subtitle: "Understand sentences signed to you",
                    tint: Color(hex: "#5E9ECC"),
                    backgroundTop: Color(hex: "#EEF6FB"),
                    backgroundBottom: Color(hex: "#E6F1F9"),
                    border: Color(hex: "#A5C1D8"),
                    imageAssetName: "SentencesComprehendFlowerPartial",
                    placeholderOnLeading: false
                ) {
                    createPracticeSheetMode = .comprehension
                }
            }
            #else
            PracticeModeCard(
                title: "Sign",
                subtitle: "Sign sentences to\nsomeone else",
                tint: Color(hex: "#71A046"),
                backgroundTop: Color(hex: "#F4F9F1"),
                backgroundBottom: Color(hex: "#EAF3E3"),
                border: Color(hex: "#ADCE8F"),
                imageAssetName: "SentencesSignFlowerPartial",
                placeholderOnLeading: true
            ) {
                createPracticeSheetMode = .signing
            }

            PracticeModeCard(
                title: "Comprehend",
                subtitle: "Understand sentences\nsigned to you",
                tint: Color(hex: "#5E9ECC"),
                backgroundTop: Color(hex: "#EEF6FB"),
                backgroundBottom: Color(hex: "#E6F1F9"),
                border: Color(hex: "#A5C1D8"),
                imageAssetName: "SentencesComprehendFlowerPartial",
                placeholderOnLeading: false
            ) {
                createPracticeSheetMode = .comprehension
            }
            #endif
        }
    }

    private enum CreatePracticeSheetMode: String, Identifiable {
        case signing
        case comprehension

        var id: String { rawValue }

        var modeSelection: PracticeModeSelection {
            switch self {
            case .signing:
                return PracticeModeSelection(signing: true, comprehension: false)
            case .comprehension:
                return PracticeModeSelection(signing: false, comprehension: true)
            }
        }
    }

    private var trainingSectionTitle: some View {
        Text("My Practices")
            .font(.jakarta(size: 20, weight: .semibold))
            .foregroundColor(.black.opacity(0.78))
            .padding(.top, 6)
    }

    private var trainingCardsSection: some View {
        VStack(spacing: 14) {
            ForEach(savedSessions, id: \.id) { session in
                let item = trainingItem(for: session)
                TrainingCard(
                    item: item,
                    isExpanded: expandedCardID == item.id,
                    onTapCard: {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                            if expandedCardID == item.id {
                                expandedCardID = nil
                            } else {
                                expandedCardID = item.id
                            }
                        }
                    },
                    onReview: {
                        openSavedSession(session, kind: .review)
                    },
                    onRetry: {
                        openSavedSession(session, kind: .retry)
                    },
                    actionType: session.sentences.allSatisfy(\.completed) ? .retry : .continueSession
                )
            }
        }
    }

    private enum SavedSessionOpenKind {
        case review
        case retry
    }

    private func openSavedSession(_ session: SavedPracticeModel, kind: SavedSessionOpenKind) {
        switch kind {
        case .review:
            sessionSentences = session.sentences
            let firstIncomplete = session.sentences.firstIndex { !$0.completed }
            savedSessionStartSentenceIndex = firstIncomplete ?? session.sentences.count
            shouldPersistSessionOnFinish = true
        case .retry:
            sessionSentences = session.sentences.map { sentence in
                var copy = sentence
                copy.completed = false
                copy.score = nil
                copy.wordScores = nil
                copy.comprehensionAttempts = nil
                return copy
            }
            savedSessionStartSentenceIndex = 0
            shouldPersistSessionOnFinish = false
        }

        let mapped = Set(session.categories.compactMap { TermCategory(rawValue: $0) })
        lastCategories = mapped.isEmpty ? nil : mapped
        lastPracticeTitle = session.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        lastModeSelection = modeSelection(for: session)
        practiceSessionIdentity = UUID()
        isExistingSavedPractice = true
        showSessionView = true
    }

    private func modeSelection(for session: SavedPracticeModel) -> PracticeModeSelection {
        let hasComprehension = session.sentences.contains { $0.practiceType == .comprehension }
        let hasSigning = session.sentences.contains { $0.practiceType != .comprehension }
        return PracticeModeSelection(signing: hasSigning, comprehension: hasComprehension)
    }

    private func saveSessionToDatabase() {
        guard !sessionSentences.isEmpty else {
            sessionSentences = []
            return
        }
        let categoryStrings = lastCategories?.map { $0.rawValue } ?? ["General"]

        if let existingSession = savedSessions.first(where: { session in
            guard let a = session.sentences.first?.id, let b = sessionSentences.first?.id else { return false }
            return a == b
        }) {
            existingSession.sentences = sessionSentences
            existingSession.date = Date()
            let trimmed = lastPracticeTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            existingSession.title = trimmed.isEmpty ? nil : trimmed
            dataVM.persistModelContext()
        } else {
            dataVM.savePracticeSession(
                sentences: sessionSentences,
                categories: categoryStrings,
                title: lastPracticeTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }

        sessionSentences = []
        lastPracticeTitle = ""
    }
}

private struct PracticeModeCard: View {
    let title: String
    let subtitle: String
    let tint: Color
    let backgroundTop: Color
    let backgroundBottom: Color
    let border: Color
    let imageAssetName: String
    let placeholderOnLeading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 16) {
                if placeholderOnLeading {
                    imagePlaceholder
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.jakarta(size: 28, weight: .semibold))
                        .foregroundColor(tint)

                    #if os(iOS)
                    Text(subtitle)
                        .font(.jakarta(size: 15, weight: .medium))
                        .foregroundColor(.black.opacity(0.78))
                        .multilineTextAlignment(.leading)
                    #else
                    Text(subtitle)
                        .font(.jakarta(size: 17, weight: .medium))
                        .foregroundColor(.black.opacity(0.78))
                        .multilineTextAlignment(.leading)
                    #endif
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !placeholderOnLeading {
                    imagePlaceholder
                }
            }
            .padding(.horizontal, 18)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [backgroundTop, backgroundBottom],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(border, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private var imagePlaceholder: some View {
        Image(imageAssetName)
            .resizable()
            .scaledToFit()
            .frame(width: 130, height: 130)
    }
}

struct TrainingCard: View {
    enum ActionType {
        case continueSession
        case retry
    }

    let item: TrainingItem
    let isExpanded: Bool
    let onTapCard: () -> Void
    var onReview: () -> Void = {}
    var onRetry: () -> Void = {}
    var actionType: ActionType = .continueSession

    var body: some View {
        VStack(alignment: .leading, spacing: isExpanded ? 14 : 0) {
            HStack(alignment: .center, spacing: 14) {
                leftIcon

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(item.title)
                            .font(.jakarta(size: 17, weight: .medium))
                            .foregroundColor(.black)
                        completionTag
                    }
                    Text(item.subtitle)
                        .font(.jakarta(size: 16, weight: .regular))
                        .foregroundColor(.gray)
                }

                Spacer()
                accuracyCircle
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onTapCard()
            }

            if isExpanded {
                Button {
                    switch actionType {
                    case .continueSession:
                        onReview()
                    case .retry:
                        onRetry()
                    }
                } label: {
                    Text(actionType == .continueSession ? "Continue" : "Retry")
                        .font(.jakarta(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color(hex: "#97C171"))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(Color(hex: "#DDDDDD"), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if !isExpanded {
                onTapCard()
            }
        }
    }

    @ViewBuilder
    private var leftIcon: some View {
        Image(systemName: item.iconName)
            .font(.jakarta(size: 20, weight: .regular))
            .foregroundColor(Color(hex: "#FBDA92"))
            .frame(width: 28)
    }

    @ViewBuilder
    private var completionTag: some View {
        Text(item.isComplete ? "Complete" : "Incomplete")
            .font(.jakarta(size: 11, weight: .medium))
            .foregroundColor(item.isComplete ? Color(hex: "#4A7C3F") : Color.gray)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(item.isComplete ? Color(hex: "#EAF3E3") : Color.gray.opacity(0.15))
            )
    }

    @ViewBuilder
    private var accuracyCircle: some View {
        if let accuracy = item.accuracy {
            ZStack {
                Circle()
                    .fill(item.accuracyColor)
                    .frame(width: 54, height: 54)

                Circle()
                    .stroke(item.accuracyBorderColor, lineWidth: 2)
                    .frame(width: 54, height: 54)

                Text("\(Int(accuracy.rounded()))")
                    .font(.jakarta(size: 17, weight: .semibold))
                    .foregroundColor(item.accuracyTextColor)
            }
        } else {
            InProgressCircleView(progress: item.completionProgress)
        }
    }
}

struct InProgressCircleView: View {
    var progress: Double

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                .frame(width: 46, height: 46)

            Circle()
                .trim(from: 0, to: max(clampedProgress, 0.02))
                .stroke(
                    Color.gray,
                    style: StrokeStyle(lineWidth: 10, lineCap: .butt)
                )
                .frame(width: 46, height: 46)
                .rotationEffect(.degrees(-90))
        }
    }
}

struct TrainingItem: Identifiable {
    let id: UUID
    let title: String
    let subtitle: String
    let accuracy: Double?
    let isComplete: Bool
    let completionProgress: Double
    let iconName: String

    var accuracyColor: Color {
        guard let acc = accuracy else { return Color.gray }
        if acc >= 80 { return Color(hex: "#EAF3E3") }
        if acc >= 60 { return Color(hex: "#FACD6B") }
        return Color(hex: "#FA6B6E")
    }

    var accuracyTextColor: Color {
        guard let acc = accuracy else { return Color.gray }
        if acc >= 80 { return Color(hex: "#4A7C3F") }
        if acc >= 60 { return Color(hex: "#8B6914") }
        return Color(hex: "#A13B3D")
    }

    var accuracyBorderColor: Color {
        guard let acc = accuracy else { return Color.gray.opacity(0.75) }
        if acc >= 80 { return Color(hex: "#A8D4A0") }
        if acc >= 60 { return Color(hex: "#E5B84A") }
        return Color(hex: "#E55558")
    }
}

#Preview {
    let schema = Schema([SavedPracticeModel.self, FlashcardModel.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    let vm = SwiftDataVM(modelContext: container.mainContext)

    SavedPracticeView()
        .modelContainer(container)
        .environment(vm)
}
