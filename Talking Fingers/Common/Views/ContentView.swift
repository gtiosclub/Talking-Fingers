//
//  ContentView.swift
//  Talking Fingers
//
//  Created by Nikola Cao on 1/24/26.
//
import SwiftUI
import SwiftData
struct ContentView: View {
    @Environment(AuthenticationViewModel.self) var authVM
    @Environment(SwiftDataVM.self) private var dataVM
    @Environment(\.scenePhase) private var scenePhase
    
    @Query private var users: [User]
    
    var body: some View {
        Group {
            if authVM.currentUser != nil {
                MainNavigationView()
            } else {
                EntryView()
            }
        }
        .environment(authVM)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active, let currentUser = users.first {
                dataVM.checkAndResetStreak(for: currentUser)
                print("Streak checked for user: \(currentUser.name)")
            }
        }
    }
}
struct MainNavigationView: View {
    @Environment(AuthenticationViewModel.self) var authVM
    @State private var selectedSection: NavigationSection = .home
    #if os(macOS)
    @State private var isSidebarCollapsed: Bool = false
    #endif
    
    var body: some View {
        #if os(macOS)
        HStack(spacing: 0) {
            MacSidebarView(
                selection: $selectedSection,
                isCollapsed: $isSidebarCollapsed,
                userName: authVM.currentUser?.name ?? ""
            )

            detailView(for: selectedSection)
                .environment(authVM)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.ignoresSafeArea())
        .ignoresSafeArea(.container, edges: .top)
        .configureMacWindowChrome()
        #else
        TabView(selection: $selectedSection) {
            detailView(for: .home)
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(NavigationSection.home)
            detailView(for: .flashcards)
                .tabItem {
                    Label("Flashcards", systemImage: "rectangle.stack.fill")
                }
                .tag(NavigationSection.flashcards)
            detailView(for: .sentences)
                .tabItem {
                    Label("Sentences", systemImage: "text.bubble")
                }
                .tag(NavigationSection.sentences)
            detailView(for: .stats)
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(NavigationSection.stats)
            detailView(for: .camera)
                .tabItem {
                    Label("Vision", systemImage: "eyeglasses")
                }
                .tag(NavigationSection.camera)
            detailView(for: .review)
                .tabItem {
                    Label("Review", systemImage: "film.stack")
                }
                .tag(NavigationSection.review)
            detailView(for: .practice)
                .tabItem {
                    Label("Practice", systemImage: "pencil.and.scribble")
                }
                .tag(NavigationSection.practice)
        }
        .environment(authVM)
        #endif
    }
    
    @ViewBuilder
    private func detailView(for section: NavigationSection) -> some View {
        switch section {
        case .home:
            DashboardView()
            
        case .flashcards:
            NavigationStack {
                let dummyCard = FlashcardModel(
                    term: .hello,
                    id: UUID(),
                    category: .greetings
                )

                StartCardComponent(
                    modeTitle: "Exercise",
                    topic: "Greetings",
                    completed: 0,
                    total: 12,
                    imageName: "greetingsIllustration",
                    primaryAction: {},
                    secondaryAction: {},
                    closeAction: {
                        selectedSection = .home
                    },
                    learnFlashcard: dummyCard,
                    learnProgress: 0.25
                )
            }
        case .sentences:
            NavigationStack {
                SavedPracticeView()
            }
        case .stats:
            StatsView()
            
        case .camera:
            NavigationStack {
                CameraView()
                    .environment(authVM)
            }
        case .review:
            NavigationStack {
                ReviewView()
                    .environment(authVM)
            }
            
        case .practice:
            NavigationStack {
                SigningPracticeView()
                    .environment(authVM)
            }
        }
    }
    
    enum NavigationSection: Hashable {
        case home, flashcards, sentences, stats, camera, review, practice
    }
}
struct StatsView: View {
    var body: some View {
        #if os(iOS)
        ProfileWidgetsView(presentation: .embedded)
        #else
        Text("Profile widgets are available in the iOS app.")
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        #endif
    }
}
#Preview {
    ContentView()
}
