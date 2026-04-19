import SwiftUI

struct SavedPracticeView: View {
    @State private var selectedFilter = "All"
    @State private var expandedCardID: UUID?
    @State private var showCreatePracticeView = false
    @State private var showSessionView = false
    @State private var sessionSentences: [AISentenceModel] = []
    @State private var lastCategories: Set<TermCategory>?
    @State private var lastModeSelection = PracticeModeSelection(signing: true, comprehension: false)

    private let filters = ["All", "Sign", "Comprehend", "Category"]

    private let trainings: [TrainingItem] = [
        TrainingItem(
            title: "Greetings Comprehension",
            subtitle: "Started 2 days ago",
            score: nil,
            kind: .comprehension
        ),
        TrainingItem(
            title: "Sports",
            subtitle: "Completed 4 days ago",
            score: 75,
            kind: .completed
        ),
        TrainingItem(
            title: "Greetings + goodbyes",
            subtitle: "Completed 6 days ago",
            score: 75,
            kind: .completed
        ),
        TrainingItem(
            title: "Untitled Practice",
            subtitle: "Completed 6 days ago",
            score: 75,
            kind: .completed
        ),
        TrainingItem(
            title: "Greetings + goodbyes",
            subtitle: "Completed 6 days ago",
            score: 75,
            kind: .completed
        )
    ]
    
    let orangeBorder = Color(hex: "#F8BC3A")
    let orangeBg = Color(hex: "#FDF2D8")
    let blackBorder = Color(hex: "#464646")

    var body: some View {
            ZStack(alignment: .leading) {
                Color(red: 0.96, green: 0.96, blue: 0.96)
                    .ignoresSafeArea(.container, edges: .top)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        headerSection
                        filterSection
                        //progressCard
                        trainingCardsSection
                    }
                    .padding(.horizontal, 64)
                    .padding(.top, 40)
                    .padding(.bottom, 40)
                }
                
                //floatingPlusButton
            }
            .sheet(isPresented: $showCreatePracticeView) {
                GenerateSentencesView { sentences, categories in
                    lastCategories = categories
                    sessionSentences = sentences
                    showCreatePracticeView = false
                    showSessionView = true
                }
            }
            .universalFullScreenCover(isPresented: $showSessionView) {
                PracticeSessionView(
                    sentences: $sessionSentences,
                    onFinish: { showSessionView = false },
                    onExtend: {
                        guard let categories = lastCategories else { return }
                        do {
                            let more = try await GenerateSentencesView.generateSentences(
                                categories: categories,
                                modeSelection: lastModeSelection
                            )
                            await MainActor.run {
                                sessionSentences.append(contentsOf: more)
                            }
                        } catch {
                            // Could set an error message state and show in session
                        }
                    }
                )
            }
    }

    private var headerSection: some View {
        Text("My Practices")
            .font(.system(size: 32, weight: .semibold))
            .foregroundColor(.black)
    }

    private var filterSection: some View {
        //ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filters, id: \.self) { filter in
                    let isSelected = (filter == selectedFilter)
                    Button {
                        selectedFilter = filter
                    } label: {
                        Text(filter)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(isSelected ? orangeBorder : .black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(isSelected ? (orangeBg ?? Color.clear) : Color.clear)
                            )
                            .overlay(
                                Capsule().strokeBorder(isSelected ? (orangeBorder ?? Color.black) : (blackBorder ?? Color.black), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                Button {
                    showCreatePracticeView = true
                } label: {
                    Label("New Practice", systemImage: "plus")
                        .font(.custom("SF Pro-Semibold", size: 17))
                        .foregroundColor(.white)
                        .frame(width: 157, height: 38)
                        .background(Color(hex: "#52A0DF"))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                
            }
        //}
    }

//    private var progressCard: some View {
//        VStack(alignment: .leading, spacing: 22) {
//            Text("You’re almost done with your Greetings Comprehension practice!")
//                .font(.system(size: 17, weight: .medium))
//                .foregroundColor(.black.opacity(0.55))
//                .fixedSize(horizontal: false, vertical: true)
//
//            HStack(spacing: 14) {
//                GeometryReader { geometry in
//                    ZStack(alignment: .leading) {
//                        Capsule()
//                            .fill(Color.gray.opacity(0.22))
//                            .frame(height: 12)
//
//                        Capsule()
//                            .fill(Color.gray.opacity(0.42))
//                            .frame(width: geometry.size.width * 0.8, height: 12)
//                    }
//                }
//                .frame(height: 12)
//
//                Text("80%")
//                    .font(.system(size: 18, weight: .semibold))
//                    .foregroundColor(.gray)
//            }
//
//            HStack {
//                Spacer()
//
//                Button {
//                    // continue action later
//                } label: {
//                    Text("Continue")
//                        .font(.system(size: 17, weight: .medium))
//                        .foregroundColor(.gray)
//                        .padding(.horizontal, 18)
//                        .padding(.vertical, 11)
//                        .background(
//                            RoundedRectangle(cornerRadius: 12)
//                                .fill(Color.gray.opacity(0.12))
//                        )
//                }
//                .buttonStyle(.plain)
//
//                Spacer()
//            }
//        }
//        .padding(.horizontal, 24)
//        .padding(.vertical, 26)
//        .background(
//            RoundedRectangle(cornerRadius: 20)
//                .fill(Color.gray.opacity(0.10))
//        )
//    }

    private var trainingCardsSection: some View {
        VStack(spacing: 16) {
            ForEach(trainings) { item in
                TrainingCard(
                    item: item,
                    isExpanded: expandedCardID == item.id,
                    onTapChevron: {
                        if expandedCardID == item.id {
                            expandedCardID = nil
                        } else {
                            expandedCardID = item.id
                        }
                    }
                )
            }
        }
    }

//    private var floatingPlusButton: some View {
//        VStack {
//            Spacer()
//
//            HStack {
//                Spacer()
//
//                Button {
//                    showCreatePracticeView = true
//                } label: {
//                    Image(systemName: "plus")
//                        .font(.system(size: 21, weight: .medium))
//                        .foregroundColor(.white)
//                        .frame(width: 66, height: 66)
//                        .background(
//                            Circle()
//                                .fill(Color.gray.opacity(0.95))
//                        )
//                        .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
//                }
//                .buttonStyle(.plain)
//                .padding(.trailing, 18)
//            }
//        }
//    }
}

struct TrainingCard: View {
    let item: TrainingItem
    let isExpanded: Bool
    let onTapChevron: () -> Void
    let blackBorder = Color(hex: "#464646")
    let custGray = Color(hex: "#737373")

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                leftIcon
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.title)
                        .font(.custom("Plus Jakarta Sans-Medium", size: 17))
                        .foregroundColor(blackBorder)

                    Text(item.subtitle)
                        .font(.custom("Plus Jakarta Sans", size: 13))
                        .foregroundColor(custGray)
                }

                Spacer()

                //rightStatusView

                Button(action: onTapChevron) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.gray)
                        .frame(width: 27, height: 16, alignment: .center)
                        .padding(8)
                }
                .buttonStyle(.plain)
            }

            if isExpanded {
                HStack(alignment: .center, spacing: 12) {

                    Button {
                        // review action later
                    } label: {
                        Text("Review")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(hex: "#4B6B2E"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: "#EAF3E3") ?? .clear)
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        // retry action later
                    } label: {
                        Text("Retry")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: "#97C171") ?? .clear)
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
        let orangeBorder = Color(hex: "#FBDA92")
        if item.kind == .comprehension {
            Image(systemName: "eye")
                .font(.custom("SF Pro-Regular", size: 20))
                .foregroundColor(orangeBorder)
                .frame(width: 27, height: 25)
        } else {
            Image(systemName: "hand.wave")
                .font(.custom("SF Pro-Regular", size: 20))
                .foregroundColor(orangeBorder)
                .frame(width: 27, height: 25)
        }
    }

//    @ViewBuilder
//    private var rightStatusView: some View {
//        if let score = item.score {
//            ZStack {
//                Circle()
//                    .stroke(Color.gray.opacity(0.75), lineWidth: 1.5)
//                    .frame(width: 58, height: 58)
//
//                Text("\(score)")
//                    .font(.system(size: 18, weight: .medium))
//                    .foregroundColor(.gray)
//            }
//        } else {
//            InProgressCircleView()
//        }
//    }
}

//struct InProgressCircleView: View {
//    var body: some View {
//        ZStack {
//            Circle()
//                .trim(from: 0, to: 0.85)
//                .stroke(
//                    Color.gray,
//                    style: StrokeStyle(lineWidth: 11, lineCap: .butt)
//                )
//                .frame(width: 48, height: 48)
//                .rotationEffect(.degrees(-90))
//        }
//    }
//}

struct TrainingItem: Identifiable {
    let id = UUID()
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
    SavedPracticeView()
}
