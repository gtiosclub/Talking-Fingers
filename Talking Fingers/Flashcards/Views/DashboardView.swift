//
//  DashboardView.swift
//  Talking Fingers
//
//  Created by Isha Jain on 2/5/26.
//

import SwiftUI
import SwiftData

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
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @State private var selectedTab: Int = 0
    
    // Compute categories that are in progress (have at least one non-new and non-mastered card)
    private var inProgressCategories: [(category: TermCategory, progress: Float, mode: String)] {
        let grouped = Dictionary(grouping: categoryScopedCards) { $0.category }
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
    
    private var categoryScopedCards: [FlashcardModel] {
        // Guard against mismatched remote records: category views should only show
        // cards whose term actually belongs to that category.
        flashcardVM.flashcards.filter { $0.term.category == $0.category }
    }
    
    private var foundationsCompleted: Bool {
        isLearnCompleted(for: .alphabet) && isLearnCompleted(for: .numbers)
    }
    
    private func isLearnCompleted(for category: TermCategory) -> Bool {
        categoryScopedCards.contains { $0.category == category && $0.progress != .new }
    }
    
    private func canAccessCategory(_ category: TermCategory) -> Bool {
        if category == .alphabet || category == .numbers { return true }
        return foundationsCompleted
    }
    
    private func category(from title: String) -> TermCategory? {
        let normalized = title.lowercased()
        return TermCategory.allCases.first(where: { $0.rawValue.lowercased() == normalized })
    }
    
    private func isExerciseUnlocked(for category: TermCategory) -> Bool {
        isLearnCompleted(for: category)
    }
    
    var body: some View {
#if os(macOS)
        // MARK: - Mac Layout
        NavigationStack {
            HStack(spacing: 0) {
                
                // MAIN CONTENT
                Group {
                    if currentView == "Home" {
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
                    isExerciseUnlocked: selectedCategoryForPopup.map { canAccessCategory($0) && isExerciseUnlocked(for: $0) } ?? false,
                    onLearn: {
                        if let cat = selectedCategoryForPopup {
                            guard canAccessCategory(cat) else { return }
                            activeFlow = .learn(cat)
                        }
                    },
                    onExercise: {
                        if let cat = selectedCategoryForPopup {
                            guard canAccessCategory(cat) else { return }
                            activeFlow = .exercise(cat)
                        }
                    }
                )
            }
            .overlay {
                if let flow = activeFlow {
                    ZStack {
                        Color(NSColor.windowBackgroundColor)
                            .ignoresSafeArea()
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .onAppear {
                loadUserFlashcardsIfNeeded()
            }
         }
#else
        // MARK: - iOS Layout
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color(red: 0.96, green: 0.97, blue: 0.99)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // MARK: - Top Nav
                        HStack {
                            Spacer()
                            Text("Talking Fingers")
                                .font(.jakarta(size: 18))
                                .fontWeight(.medium)
                                .foregroundColor(Color.gray.opacity(0.8))
                                .padding(.leading, 24)
                            Spacer()
                            
                            NavigationLink {
                                SearchView()
                                    .navigationBarBackButtonHidden(true)
                            } label: {
                                Image(systemName: "magnifyingglass")
                                    .font(.jakarta(size: 20))
                                    .foregroundColor(Color(red: 0.569, green: 0.724, blue: 0.879)) // TF Blue
                            }                            
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        // MARK: - Welcome Header
                        HStack(spacing: 16) {
                            Image("DashboardWelcome")
                                .font(.jakarta(size: 45))
                                .foregroundColor(Color(red: 0.85, green: 0.8, blue: 0.3))
                            
                            VStack(alignment: .leading, spacing: 0) {
                                if let userName = users.first?.name, !userName.isEmpty {
                                    Text("Welcome back,")
                                        .font(.jakarta(size: 26))
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color.black.opacity(0.7))
                                    
                                    Text(userName)
                                        .font(.jakarta(size: 26))
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color(red: 0.30, green: 0.55, blue: 0.85)) // TF Blue
                                } else {
                                    Text("Welcome back!")
                                        .font(.jakarta(size: 26))
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color.black.opacity(0.7))
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        // MARK: - Jump back in! (White Bubble)
                        if !inProgressCategories.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Jump back in!")
                                    .font(.jakarta(size: 20))
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.black.opacity(0.8))
                                    .padding(.horizontal, 20)
                                    .padding(.top, 20)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(Array(inProgressCategories.enumerated()), id: \.element.category) { index, item in
                                            Button {
                                                guard canAccessCategory(item.category) else { return }
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
                                                    backgroundColor: item.mode == "Exercise" ? Color(red: 0.931, green: 0.956, blue: 0.981) : Color(red: 0.942, green: 0.964, blue: 0.942),
                                                    borderColor: item.mode == "Exercise" ? Color(red: 0.691, green: 0.803, blue: 0.914) : Color(red: 0.704, green: 0.804, blue: 0.585)
                                                )
                                                .frame(width: 155) // Keeps cards properly sized within the bubble
                                                .opacity(canAccessCategory(item.category) ? 1.0 : 0.5)
                                            }
                                            .buttonStyle(.plain)
                                            .disabled(!canAccessCategory(item.category))
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 20)
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(24)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .strokeBorder(Color.gray.opacity(0.6), lineWidth: 2)
                            )
                            .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
                            .padding(.horizontal, 16)
                        }
                        
                        // MARK: - Daily Challenge
                        Text("Keep up your streak!")
                            .font(.jakarta(size: 20))
                            .fontWeight(.semibold)
                            .foregroundColor(Color.black.opacity(0.8))
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
                            .font(.jakarta(size: 20))
                            .fontWeight(.semibold)
                            .foregroundColor(Color.black.opacity(0.8))
                            .padding(.horizontal)
                        
                        let columns = [
                            GridItem(.flexible(), spacing: 12)
                        ]
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(TermCategory.allCases, id: \.self) { category in
                                Button {
                                    guard canAccessCategory(category) else { return }
                                    selectedCategoryForPopup = category
                                    showModePopup = true
                                } label: {
                                    CategoryComponent(title: category.displayName)
                                        .frame(maxWidth: .infinity)
                                        .opacity(canAccessCategory(category) ? 1.0 : 0.5)
                                }
                                .buttonStyle(.plain)
                                .disabled(!canAccessCategory(category))
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 120) // Give space for the floating tab bar
                    }
                    .padding(.top, 8)
                    .background(alignment: .top) {
                        LinearGradient(
                            colors: [
                                Color(red: 238/255, green: 246/255, blue: 251/255), // #EEF6FB
                                Color(red: 222/255, green: 236/255, blue: 248/255)  // #DEECF8
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 320)
                        .ignoresSafeArea(edges: .top)
                    }
                }
                
                // MARK: - Floating Tab Bar Overlay
                FloatingTabBar(selectedTab: $selectedTab)
            }
            .popupHost(isPresented: $showModePopup) {
                ModePopupView(
                    isPresented: $showModePopup,
                    isExerciseUnlocked: selectedCategoryForPopup.map { canAccessCategory($0) && isExerciseUnlocked(for: $0) } ?? false,
                    onLearn: {
                        if let cat = selectedCategoryForPopup {
                            guard canAccessCategory(cat) else { return }
                            activeFlow = .learn(cat)
                        }
                    },
                    onExercise: {
                        if let cat = selectedCategoryForPopup {
                            guard canAccessCategory(cat) else { return }
                            activeFlow = .exercise(cat)
                        }
                    }
                )
            }
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
            .onAppear {
                loadUserFlashcardsIfNeeded()
            }
        }
        
#endif
    }
    
    
    var dashboardContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // MARK: - Search
                NavigationLink {
                    SearchView()
                } label: {
                    HStack {
                        Text("Search for a word or phrase...")
                            .foregroundColor(.gray)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        Image(systemName: "magnifyingglass")
                            .font(.jakarta(size: 20))
                            .foregroundColor(Color(red: 0.569, green: 0.724, blue: 0.879)) // TF Blue
                            .padding(.leading, 8)
                    }
                }
                .buttonStyle(.plain)
                
                // MARK: - Welcome Header
                HStack(spacing: 16) {
                    Image(systemName: "DashboardWelcome")
                        .font(.jakarta(size: 45))
                        .foregroundColor(Color(red: 0.85, green: 0.8, blue: 0.3))
                    
                    VStack(alignment: .leading, spacing: 0) {
                        if let userName = users.first?.name, !userName.isEmpty {
                            Text("Welcome back,")
                                .font(.jakarta(size: 26))
                                .fontWeight(.semibold)
                                .foregroundColor(Color.black.opacity(0.7))
                            
                            Text(userName)
                                .font(.jakarta(size: 26))
                                .fontWeight(.semibold)
                                .foregroundColor(Color(red: 0.30, green: 0.55, blue: 0.85)) // TF Blue
                        } else {
                            Text("Welcome back!")
                                .font(.jakarta(size: 26))
                                .fontWeight(.semibold)
                                .foregroundColor(Color.black.opacity(0.7))
                        }
                    }
                    Spacer()
                }
                .padding(.top, 10)
                
                // MARK: - Mac Jump Back In
                if !inProgressCategories.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Jump back in!")
                            .font(.jakartaTitle)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        
                        HStack(spacing: 16) {
                            ForEach(Array(inProgressCategories.enumerated()), id: \.element.category) { index, item in
                                Button {
                                    guard canAccessCategory(item.category) else { return }
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
                                        backgroundColor: item.mode == "Exercise" ? Color(red: 0.931, green: 0.956, blue: 0.981) : Color(red: 0.942, green: 0.964, blue: 0.942),
                                        borderColor: item.mode == "Exercise" ? Color(red: 0.691, green: 0.803, blue: 0.914) : Color(red: 0.704, green: 0.804, blue: 0.585),
                                    )
                                    .frame(maxWidth: .infinity)
                                    .opacity(canAccessCategory(item.category) ? 1.0 : 0.5)
                                }
                                .buttonStyle(.plain)
                                .disabled(!canAccessCategory(item.category))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    .background(Color.white)
                    .cornerRadius(24)
                    .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
                }
                
                // MARK: - Mac Daily Challenge
                Text("Daily Challenge")
                    .font(.jakartaTitle)

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
                
                // MARK: - Categories
                Text("Categories")
                    .font(.jakartaTitle)
                
                VStack(spacing: 12) {
                    ForEach(allCategories, id: \.self) { category in
                        let resolvedCategory = self.category(from: category)
                        let isAccessible = resolvedCategory.map(canAccessCategory) ?? true
                        Button {
                            if let cat = resolvedCategory {
                                guard canAccessCategory(cat) else { return }
                                selectedCategoryForPopup = cat
                                showModePopup = true
                            }
                        } label: {
                            CategoryComponent(title: category)
                                .frame(maxWidth: .infinity)
                                .opacity(isAccessible ? 1.0 : 0.5)
                        }
                        .buttonStyle(.plain)
                        .disabled(!isAccessible)
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
                .font(.jakartaLargeTitle)
            
            Spacer()
        }
        .padding()
    }
}
    
extension DashboardView {
    private func loadUserFlashcardsIfNeeded() {
        guard flashcardVM.flashcards.isEmpty, !flashcardVM.isLoading else { return }
        Task {
            await flashcardVM.loadFlashcards(modelContext: modelContext)
        }
    }
}
    
// MARK: - In Progress Card

private struct InProgressCard: View {
    let category: TermCategory
    let mode: String
    let progress: Float
    let backgroundColor: Color
    let borderColor: Color
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
                .foregroundColor(borderColor)

            VStack(spacing: 4) {
                Text("Continue \(mode)")
                    .font(.jakarta(size: 15))
                    .foregroundStyle(.secondary)

                Text(category.displayName.capitalized)
                    .font(.jakarta(size: 20))
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(borderColor)

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
                    .font(.jakarta(size: 12))
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .background(backgroundColor)
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .strokeBorder(borderColor, lineWidth: 2)
        )
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
            VStack(alignment: .leading, spacing: 14) {
                
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                       // .font(.jakarta(size: 14))
                        .foregroundColor(Color(red: 0.90, green: 0.72, blue: 0.30))
                    Text("\(streak) Day Streak")
                        .font(.jakarta(size: 14))
                        .fontWeight(.medium)
                        .foregroundColor(Color(red: 0.5, green: 0.35, blue: 0.1))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color(red: 0.98, green: 0.88, blue: 0.65))
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Practice Missed Signs")
                        .font(.jakarta(size: 22))
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))

                    Text("+20XP")
                        .font(.jakarta(size: 15))
                        .fontWeight(.medium)
                        .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3).opacity(0.8))
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.7))

                        Capsule()
                            .fill(Color(red: 0.30, green: 0.55, blue: 0.85))
                            .frame(width: geo.size.width * progress)
                    }
                }
                .frame(height: 10)
            }

            Spacer()

            Image(systemName: "medal.fill")
                .resizable()
                .scaledToFit()
                .frame(height: 65)
                .foregroundColor(Color(red: 0.90, green: 0.72, blue: 0.30))
                .padding(.trailing, 8)
        }
        .padding(24)
        .background(Color(red: 0.99, green: 0.95, blue: 0.86))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .strokeBorder(Color(red: 0.963, green: 0.86, blue: 0.609), lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Floating Tab Bar Components

private struct FloatingTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack {
            Spacer()
            TabBarButton(icon: "house.fill", title: "Home", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            Spacer()
            TabBarButton(icon: "hand.raised.fill", title: "Practice", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            Spacer()
            TabBarButton(icon: "person.fill", title: "Profile", isSelected: selectedTab == 2) {
                selectedTab = 2
            }
            Spacer()
        }
        .padding(.vertical, 12)
        .background(Color.white)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.08), radius: 15, x: 0, y: 5)
        .padding(.horizontal, 30)
        .padding(.bottom, 20)
    }
}

private struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.jakarta(size: 22))
                Text(title)
                    .font(.jakarta(size: 10))
                    .fontWeight(.semibold)
            }
            .foregroundColor(isSelected ? Color(red: 0.30, green: 0.55, blue: 0.85) : Color.gray.opacity(0.6))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color(red: 0.30, green: 0.55, blue: 0.85).opacity(0.15) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DashboardView()
        .environment(SwiftDataVM())
}
