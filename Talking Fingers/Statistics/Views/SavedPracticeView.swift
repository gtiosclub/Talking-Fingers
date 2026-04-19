import SwiftUI
import SwiftData

struct SavedPracticeView: View {
    @Environment(SwiftDataVM.self) private var dataVM
    @Query(sort: \SavedPracticeModel.date, order: .reverse) private var savedSessions: [SavedPracticeModel]

    @State private var selectedFilter = "All"
    @State private var selectedCategoryFilters: Set<TermCategory> = []
    @State private var expandedCardID: UUID?
    @State private var showCreatePracticeView = false
    @State private var showSessionView = false
    @State private var sessionSentences: [AISentenceModel] = []
    @State private var lastCategories: Set<TermCategory>?
    @State private var lastPracticeTitle: String = ""
    @State private var lastModeSelection = PracticeModeSelection(signing: true, comprehension: false)
    @State private var savedSessionStartSentenceIndex: Int = 0
    @State private var practiceSessionIdentity = UUID()
    @State private var shouldPersistSessionOnFinish = true

    private let filters = ["All", "Sign", "Comprehend", "Category"]
    private let selectedBubbleFill = Color(hex: "#FDF2D8")
    private let selectedBubbleAccent = Color(hex: "#ECA509")
    private let defaultBubbleFill = Color.white
    private let defaultBubbleBorder = Color(hex: "#464646")

    private var filteredSessions: [SavedPracticeModel] {
        let base: [SavedPracticeModel]
        switch selectedFilter {
        case "Sign":
            base = savedSessions.filter { session in
                session.sentences.contains { $0.practiceType != .comprehension }
            }
        case "Comprehend":
            base = savedSessions.filter { session in
                session.sentences.contains { $0.practiceType == .comprehension }
            }
        case "Category":
            if selectedCategoryFilters.isEmpty {
                base = savedSessions
            } else {
                let selectedRaw = Set(selectedCategoryFilters.map(\.rawValue))
                base = savedSessions.filter { session in
                    !selectedRaw.isDisjoint(with: Set(session.categories))
                }
            }
        default:
            base = savedSessions
        }
        return base
    }

    private func displayTitle(for session: SavedPracticeModel) -> String {
        if let t = session.title?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty {
            return t
        }
        return session.categories.joined(separator: " + ").capitalized
    }

    private func trainingItem(for session: SavedPracticeModel) -> TrainingItem {
        let completedCount = session.sentences.filter(\.completed).count
        let totalCount = session.sentences.count
        let score = totalCount > 0 ? (completedCount * 100 + totalCount / 2) / totalCount : 0
        let isComprehension = session.sentences.first?.practiceType == .comprehension
        return TrainingItem(
            id: session.id,
            title: displayTitle(for: session),
            subtitle: "Saved \(session.date.formatted(.dateTime.month().day().year()))",
            score: score,
            kind: score >= 100 ? .completed : (isComprehension ? .comprehension : .completed)
        )
    }

    var body: some View {
            ZStack(alignment: .bottom) {
                Color.white
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        headerSection
                        filterSection

                        if let latest = filteredSessions.first,
                           latest.sentences.filter({ $0.completed }).count < latest.sentences.count {
                            progressCard(for: latest)
                        }

                        trainingCardsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 80)
                }

                floatingPlusButton
            }
            .sheet(isPresented: $showCreatePracticeView) {
                GenerateSentencesView { sentences, categories, practiceTitle in
                    lastCategories = categories
                    lastPracticeTitle = practiceTitle
                    sessionSentences = sentences
                    savedSessionStartSentenceIndex = 0
                    practiceSessionIdentity = UUID()
                    shouldPersistSessionOnFinish = true
                    showCreatePracticeView = false
                    showSessionView = true
                }
            }
            .universalFullScreenCover(isPresented: $showSessionView) {
                PracticeSessionView(
                    sentences: $sessionSentences,
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
                                // After extending (e.g. from a retry), persist partial/full progress when the user leaves.
                                shouldPersistSessionOnFinish = true
                            }
                        } catch {
                            // Could set an error message state and show in session
                        }
                    }
                )
                .id(practiceSessionIdentity)
            }
    }

    private var headerSection: some View {
        Text("My Practices")
            .font(.system(size: 31, weight: .bold))
            .foregroundColor(.black)
            .padding(.top, 8)
    }

    @ViewBuilder
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(filters, id: \.self) { filter in
                    let isSelected = selectedFilter == filter
                    Button {
                        selectedFilter = filter
                        if filter != "Category" {
                            selectedCategoryFilters.removeAll()
                        }
                    } label: {
                        Text(filter)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isSelected ? selectedBubbleAccent : .black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 11)
                            .background(
                                RoundedRectangle(cornerRadius: 22)
                                    .fill(isSelected ? selectedBubbleFill : defaultBubbleFill)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .strokeBorder(isSelected ? selectedBubbleAccent : defaultBubbleBorder, lineWidth: 0.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        if selectedFilter == "Category" {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(TermCategory.allCases, id: \.self) { category in
                        let selected = selectedCategoryFilters.contains(category)
                        Button {
                            if selected {
                                selectedCategoryFilters.remove(category)
                            } else {
                                selectedCategoryFilters.insert(category)
                            }
                        } label: {
                            Text(category.rawValue.capitalized)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(selected ? selectedBubbleAccent : .black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(selected ? selectedBubbleFill : defaultBubbleFill)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .strokeBorder(selected ? selectedBubbleAccent : defaultBubbleBorder, lineWidth: 0.5)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func progressCard(for session: SavedPracticeModel) -> some View {
        let completedCount = session.sentences.filter(\.completed).count
        let total = session.sentences.count
        let percent = total > 0 ? Double(completedCount) / Double(total) : 0
        VStack(alignment: .leading, spacing: 22) {
            Text("You’re almost done with your \(displayTitle(for: session)) practice!")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.black.opacity(0.55))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 14) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.22))
                            .frame(height: 12)

                        Capsule()
                            .fill(Color.gray.opacity(0.42))
                            .frame(width: geometry.size.width * percent, height: 12)
                    }
                }
                .frame(height: 12)

                Text("\(Int(percent * 100))%")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.gray)
            }

            HStack {
                Spacer()

                Button {
                    openSavedSession(session, kind: .resume)
                } label: {
                    Text("Continue")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 11)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 26)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.10))
        )
    }

    private var trainingCardsSection: some View {
        VStack(spacing: 16) {
            ForEach(filteredSessions, id: \.id) { session in
                let item = trainingItem(for: session)
                TrainingCard(
                    item: item,
                    isExpanded: expandedCardID == item.id,
                    onTapChevron: {
                        if expandedCardID == item.id {
                            expandedCardID = nil
                        } else {
                            expandedCardID = item.id
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
        case resume
    }

    private func openSavedSession(_ session: SavedPracticeModel, kind: SavedSessionOpenKind) {
        switch kind {
        case .review, .resume:
            sessionSentences = session.sentences
            let firstIncomplete = session.sentences.firstIndex { !$0.completed }
            savedSessionStartSentenceIndex = firstIncomplete ?? session.sentences.count
            shouldPersistSessionOnFinish = true
        case .retry:
            sessionSentences = session.sentences.map { sentence in
                var copy = sentence
                copy.completed = false
                copy.score = nil
                return copy
            }
            savedSessionStartSentenceIndex = 0
            // Retry should not overwrite saved completion progress.
            shouldPersistSessionOnFinish = false
        }

        let mapped = Set(session.categories.compactMap { TermCategory(rawValue: $0) })
        lastCategories = mapped.isEmpty ? nil : mapped
        lastPracticeTitle = session.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        practiceSessionIdentity = UUID()
        showSessionView = true
    }

    private var floatingPlusButton: some View {
        VStack {
            Spacer()

            HStack {
                Spacer()

                Button {
                    showCreatePracticeView = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 21, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 66, height: 66)
                        .background(
                            Circle()
                                .fill(Color(hex: "#52A0DF"))
                        )
                        .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 18)
            }
        }
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

struct TrainingCard: View {
    enum ActionType {
        case continueSession
        case retry
    }

    let item: TrainingItem
    let isExpanded: Bool
    let onTapChevron: () -> Void
    var onReview: () -> Void = {}
    var onRetry: () -> Void = {}
    var actionType: ActionType = .continueSession

    var body: some View {
        VStack(alignment: .leading, spacing: isExpanded ? 18 : 0) {
            HStack(alignment: .center, spacing: 14) {
                leftIcon

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)

                    Text(item.subtitle)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.gray)
                }

                Spacer()

                rightStatusView

                Button(action: onTapChevron) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.gray)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
            }

            if isExpanded {
                HStack(spacing: 0) {
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
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(
                                        Color(hex: "#97C171")
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.gray.opacity(0.55), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var leftIcon: some View {
        let symbols = ["eye", "hand.wave"]
        let index = abs(item.id.uuidString.hashValue) % symbols.count
        Image(systemName: symbols[index])
            .font(.system(size: 22, weight: .regular))
            .foregroundColor(Color(hex: "#FBDA92"))
            .frame(width: 30)
    }

    @ViewBuilder
    private var rightStatusView: some View {
        if let score = item.score {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.75), lineWidth: 1.5)
                    .frame(width: 58, height: 58)

                Text("\(score)")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.gray)
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
                    style: StrokeStyle(lineWidth: 11, lineCap: .butt)
                )
                .frame(width: 48, height: 48)
                .rotationEffect(.degrees(-90))
        }
    }
}

struct TrainingItem: Identifiable {
    let id: UUID
    let title: String
    let subtitle: String
    let score: Int?
    let kind: TrainingKind
}

enum TrainingKind {
    case comprehension
    case completed
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
