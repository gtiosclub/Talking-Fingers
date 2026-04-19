//
//  DashboardView.swift
//  Talking Fingers
//
//  Created by Isha Jain on 2/5/26.
//

import SwiftUI

enum ActiveFlow: Identifiable {
    case learn(TermCategory)
    case exercise(TermCategory)
    case dailyChallenge
    
    var id: String {
        switch self {
        case .learn(let cat): return "learn_\(cat.rawValue)"
        case .exercise(let cat): return "exercise_\(cat.rawValue)"
        case .dailyChallenge: return "dailyChallenge"
        }
    }
}

struct DashboardView: View {
    @State private var flashcardVM = FlashcardVM()
    @State private var currentView: String = "Home"
    
    // for learn/exercise popup
    @State private var showModePopup: Bool = false
    @State private var selectedCategoryForPopup: TermCategory? = nil
    
    @State private var activeFlow: ActiveFlow? = nil
    
    @Environment(SwiftDataVM.self) private var dataVM
    
    // Compute categories that are in progress (have at least one non-new and non-mastered card)
    private var inProgressCategories: [(category: TermCategory, progress: Float, mode: String)] {
        let grouped = Dictionary(grouping: flashcardVM.fakeFlashcards) { $0.category }
        return grouped.compactMap { (category, cards) in
            let progress = flashcardVM.returnProgress(flashcards: cards)
            // Only show categories that are actually in progress (not 0% and not 100%)
            guard progress > 0 && progress < 100 else { return nil }
            
            // Decide mode based on average progress
            let mode = progress < 50 ? "Learn" : "Exercise"
            return (category: category, progress: progress, mode: mode)
        }
        .sorted { $0.progress > $1.progress }
        .prefix(2)
        .map { $0 }
    }
    
    private var allCategories: [String] {
        TermCategory.allCases.map { $0.rawValue.capitalized }
    }
    
    private var dailyQueue: DailyReviewQueue {
        flashcardVM.generateDailyReviewQueue(limit: 5)
    }
    
    var body: some View {
#if os(macOS)
        macLayout
#else
        iosLayout
#endif
    }
    var iosLayout: some View {
        NavigationStack{
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // MARK: - Search icon
                    HStack {
                        Spacer()
                        NavigationLink {
                            SearchView()
                                .navigationBarBackButtonHidden(true)
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 22))
                                .foregroundStyle(.black)
                        }
                    }
                    .padding(.horizontal)
                    
                    // MARK: - In Progress
                    if !inProgressCategories.isEmpty {
                        Text("In Progress")
                            .font(.system(size: 26, weight: .bold))
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(inProgressCategories.enumerated()), id: \.element.category) { index, item in
                                    Button {
                                        if item.mode == "Learn" {
                                            activeFlow = .learn(item.category)
                                        } else {
                                            activeFlow = .exercise(item.category)
                                        }
                                    } label: {
                                        InProgressCard(
                                            category: item.category,
                                            mode: item.mode,
                                            progress: item.progress,
                                            backgroundColor: Color.blue.opacity(0.15)
                                        )
                                        .frame(width: 180)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // MARK: - Daily Challenge
                    Text("Daily Challenge")
                        .font(.system(size: 26, weight: .bold))
                        .padding(.horizontal)
                    
                    Button {
                        activeFlow = .dailyChallenge
                    } label: {
                        DailyChallengeCard(
                            streak: 3,
                            completed: dailyQueue.cards.count,
                            total: dailyQueue.requestedLimit
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    
                    // MARK: - Categories
                    Text("Categories")
                        .font(.system(size: 26, weight: .bold))
                        .padding(.horizontal)
                    
                    let columns = [
                        GridItem(.flexible(), spacing: 12)
                    ]
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(TermCategory.allCases, id: \.self) { category in
                            Button {
                                selectedCategoryForPopup = category
                                showModePopup = true
                            } label: {
                                CategoryComponent(title: category.displayName)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 80)
                }
                .padding(.top, 8)
            }
            .background(Color.categoryComponentColor)
            
            .popupHost(isPresented: $showModePopup) {
                ModePopupView(
                    isPresented: $showModePopup,
                    onLearn: {
                        if let cat = selectedCategoryForPopup {
                            activeFlow = .learn(cat)
                        }
                    },
                    onExercise: {
                        if let cat = selectedCategoryForPopup {
                            activeFlow = .exercise(cat)
                        }
                    }
                )
            }
#if os(iOS)
            .fullScreenCover(item: $activeFlow) { flow in
                switch flow {
                case .learn(let category):
                    FlexibleStartCardComponent(context: .learn(category), completed: 0, total: 12) {
                        activeFlow = nil
                    }
                    .environment(dataVM)
                case .exercise(let category):
                    FlexibleStartCardComponent(context: .exercise(category), completed: 0, total: 12) {
                        activeFlow = nil
                    }
                    .environment(dataVM)
                case .dailyChallenge:
                    FlexibleStartCardComponent(context: .dailyChallenge, completed: 0, total: 5) {
                        activeFlow = nil
                    }
                    .environment(dataVM)
                }
            }
#else
            .sheet(item: $activeFlow) { flow in
                switch flow {
                case .learn(let category):
                    FlexibleStartCardComponent(context: .learn(category), completed: 0, total: 12) {
                        activeFlow = nil
                    }
                    .environment(dataVM)
                    .frame(minWidth: 700, minHeight: 600)
                case .exercise(let category):
                    FlexibleStartCardComponent(context: .exercise(category), completed: 0, total: 12) {
                        activeFlow = nil
                    }
                    .environment(dataVM)
                    .frame(minWidth: 700, minHeight: 600)
                case .dailyChallenge:
                    FlexibleStartCardComponent(context: .dailyChallenge, completed: 0, total: 5) {
                        activeFlow = nil
                    }
                    .environment(dataVM)
                    .frame(minWidth: 700, minHeight: 600)
                }
            }
#endif
        }
    }
    
    // MARK: - Mac Layout
    var macLayout: some View {
        HStack(spacing: 0) {
            
            // MAIN CONTENT
            Group {
                if let flow = activeFlow {
                    macFlowView(for: flow)
                } else if currentView == "Home" {
                    dashboardContent
                } else {
                    categoryDetailView(currentView)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .background(Color.categoryComponentColor)
        .popupHost(isPresented: $showModePopup) {
            ModePopupView(
                isPresented: $showModePopup,
                onLearn: {
                    if let cat = selectedCategoryForPopup {
                        activeFlow = .learn(cat)
                    }
                },
                onExercise: {
                    if let cat = selectedCategoryForPopup {
                        activeFlow = .exercise(cat)
                    }
                }
            )
        }
    }

    @ViewBuilder
    private func macFlowView(for flow: ActiveFlow) -> some View {
        switch flow {
        case .learn(let category):
            FlexibleStartCardComponent(context: .learn(category), completed: 0, total: 12) {
                activeFlow = nil
            }
            .environment(dataVM)
        case .exercise(let category):
            FlexibleStartCardComponent(context: .exercise(category), completed: 0, total: 12) {
                activeFlow = nil
            }
            .environment(dataVM)
        case .dailyChallenge:
            FlexibleStartCardComponent(context: .dailyChallenge, completed: 0, total: 5) {
                activeFlow = nil
            }
            .environment(dataVM)
        }
    }
    
    var dashboardContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                HStack {
                    TextField("Search for a word or phrase...", text: .constant(""))
                        .textFieldStyle(.roundedBorder)
                    Image(systemName: "magnifyingglass")
                }
                
                Text("In Progress")
                    .font(.title)
                
                HStack(spacing: 16) {
                    ForEach(Array(inProgressCategories.enumerated()), id: \.element.category) { index, item in
                        Button {
                            if item.mode == "Learn" {
                                activeFlow = .learn(item.category)
                            } else {
                                activeFlow = .exercise(item.category)
                            }
                        } label: {
                            InProgressCard(
                                category: item.category,
                                mode: item.mode,
                                progress: item.progress,
                                backgroundColor: Color.blue.opacity(0.15)
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // MARK: - Daily Challenge
                Text("Daily Challenge")
                    .font(.title)

                Button {
                    activeFlow = .dailyChallenge
                } label: {
                    DailyChallengeCard(
                        streak: 3,
                        completed: dailyQueue.cards.count,
                        total: dailyQueue.requestedLimit
                    )
                }
                .buttonStyle(.plain)
                
                Text("Categories")
                    .font(.title)
                
                VStack(spacing: 12) {
                    ForEach(allCategories, id: \.self) { category in
                        Button {
                            let normalized = category.lowercased()
                            if let cat = TermCategory.allCases.first(where: { $0.rawValue.lowercased() == normalized }) {
                                selectedCategoryForPopup = cat
                                showModePopup = true
                            }
                        } label: {
                            CategoryComponent(title: category)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    func categoryDetailView(_ category: String) -> some View {
        VStack {
            HStack {
                Button {
                    currentView = "Home"
                } label: {
                    Image(systemName: "arrow.left")
                }
                
                Spacer()
            }
            
            Text(category)
                .font(.largeTitle)
            
            Spacer()
        }
        .padding()
    }
}
    
// MARK: - In Progress Card

private struct InProgressCard: View {
    let category: TermCategory
    let mode: String
    let progress: Float
    let backgroundColor: Color
    var iconName: String {
        switch category {
        case .alphabet:             return "a.square"
        case .numbers:              return "number"
        case .greetings:            return "hand.wave"
        case .personalInformation:  return "person.text.rectangle"
        case .family:               return "figure.2.and.child.holdinghands"
        case .verbs:                return "bolt"
        case .dateTime:             return "calendar"
        case .feelingsEmotions:     return "heart"
        case .locations:            return "mappin.and.ellipse"
        case .commonDescriptors:    return "text.magnifyingglass"
        case .commonObjects:        return "cube"
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            
            Spacer(minLength: 0)

            Image(systemName: iconName)
                .resizable()
                .scaledToFit()
                .frame(height: 70)

            VStack(spacing: 4) {
                Text("Continue \(mode)")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)

                Text(category.displayName.capitalized)
                    .font(.system(size: 20, weight: .bold))
                    .multilineTextAlignment(.center)
            }

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.6))

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(red: 0.45, green: 0.65, blue: 0.25))
                            .frame(width: geo.size.width * CGFloat(progress / 100))
                    }
                }
                .frame(height: 8)

                Text("\(Int(progress))%")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .background(backgroundColor)
        .cornerRadius(20)
    }
}

// MARK: - Daily Challenge Card

private struct DailyChallengeCard: View {
    let streak: Int
    let completed: Int
    let total: Int

    var progress: CGFloat {
        CGFloat(Double(completed) / Double(max(total, 1)))
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Text("\(streak) Day Streak")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.orange)
                    Text("🔥")
                        .font(.system(size: 14))
                }

                Text("Start Challenge")
                    .font(.system(size: 24, weight: .bold))

                // Progress bar
                HStack(spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.5))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(red: 0.45, green: 0.65, blue: 0.25))
                                .frame(width: geo.size.width * progress, height: 8)
                        }
                    }
                    .frame(height: 8)

                    Text("\(completed)/\(total)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Placeholder icon for the lunchbox illustration
            Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                .font(.system(size: 50))
                .foregroundStyle(Color.brown.opacity(0.6))
        }
        .padding(18)
        .background(Color(red: 0.96, green: 0.90, blue: 0.72))
        .cornerRadius(20)
    }
}

#Preview {
    DashboardView()
        .environment(SwiftDataVM())
}
