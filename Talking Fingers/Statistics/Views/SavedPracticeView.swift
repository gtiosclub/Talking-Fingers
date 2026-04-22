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
        let averageAccuracy: Double? = accuracies.isEmpty ? nil : accuracies.reduce(0, +) / Double(accuracies.count)

        return TrainingItem(
            id: session.id,
            title: displayTitle(for: session),
            subtitle: session.date.formatted(.dateTime.month(.abbreviated).day().hour().minute()),
            accuracy: averageAccuracy,
            isComplete: isComplete,
            iconName: sessionModeSelection.comprehension && !sessionModeSelection.signing ? "eye" : "hand.wave"
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    startNewPracticeSection
                    trainingSectionTitle
                    trainingCardsSection
                }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .sheet(item: $createPracticeSheetMode) { sheetMode in
            let initialModeSelection = sheetMode.modeSelection
            GenerateSentencesView(initialModeSelection: initialModeSelection) { sentences, categories, practiceTitle in
                lastModeSelection = initialModeSelection
                lastCategories = categories
                lastPracticeTitle = practiceTitle
                sessionSentences = sentences
                savedSessionStartSentenceIndex = 0
                practiceSessionIdentity = UUID()
                shouldPersistSessionOnFinish = true
                createPracticeSheetMode = nil
                showSessionView = true
            }
            .presentationDetents([.height(460), .medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.white)
        }
        .universalFullScreenCover(isPresented: $showSessionView) {
            PracticeSessionView(
                sentences: $sessionSentences,
                practiceTitle: lastPracticeTitle.isEmpty ? "Practice" : lastPracticeTitle,
                selectedCategories: lastCategories,
                initialSentenceIndex: savedSessionStartSentenceIndex,
                onFinish: {
                    if shouldPersistSessionOnFinish {
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
    }

    private var headerSection: some View {
        Text("Practice")
            .font(.system(size: 32, weight: .bold))
            .foregroundColor(Color(hex: "#2A7BBC"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 14)
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
    }

    private var startNewPracticeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Start a new practice")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.black.opacity(0.78))

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
            .font(.system(size: 20, weight: .semibold))
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
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(tint)

                    Text(subtitle)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.black.opacity(0.78))
                        .multilineTextAlignment(.leading)
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
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.black)
                        completionTag
                    }
                    Text(item.subtitle)
                        .font(.system(size: 16, weight: .regular))
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
                        .font(.system(size: 17, weight: .semibold))
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
            .font(.system(size: 20, weight: .regular))
            .foregroundColor(Color(hex: "#FBDA92"))
            .frame(width: 28)
    }

    @ViewBuilder
    private var completionTag: some View {
        Text(item.isComplete ? "Complete" : "Incomplete")
            .font(.system(size: 11, weight: .medium))
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
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(item.accuracyTextColor)
            }
        } else {
            InProgressCircleView()
        }
    }
}

struct InProgressCircleView: View {
    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: 0.85)
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
