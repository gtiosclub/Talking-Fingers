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
    @State private var selectedSection: NavigationSection? = .home
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(selection: $selectedSection) {
                Label("home", systemImage: "house")
                    .tag(NavigationSection.home)
                Label("Flashcards", systemImage: "rectangle.stack.fill")
                    .tag(NavigationSection.flashcards)
                Label("Sentences", systemImage: "text.bubble")
                    .tag(NavigationSection.sentences)
                Label("Stats", systemImage: "chart.bar.fill")
                    .tag(NavigationSection.stats)
                Label("Vision", systemImage: "eyeglasses")
                    .tag(NavigationSection.camera)
                Label("Review", systemImage: "film.stack")
                    .tag(NavigationSection.review)
                Label("Practice Test", systemImage: "pencil.and.scribble")
                    .tag(NavigationSection.practice)
            }
            .navigationTitle("Talking Fingers")
        } detail: {
            #if os(macOS)
            HStack(spacing: 0) {
    
                detailView(for: selectedSection ?? .home)
                    .environment(authVM)
                    .frame(maxWidth: .infinity)
                
                // RIGHT SIDE WIDGETS (macOS ONLY)
                VStack(spacing: 16) {
                    Text("Widgets")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding(.leading, 4)
                }
                .frame(width: 240)
                .padding(.top, 20)
                .padding(.horizontal, 16)
            }
            #else
            detailView(for: selectedSection ?? .home)
                .environment(authVM)
            #endif
        }
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
            NavigationStack {
                StatsView()
            }
            
        case .camera:
            NavigationStack {
                CameraView()
                    .environment(authVM)
            }
        case .review:
            NavigationStack {
                ReviewView(signName: "Review")
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
        case home, flashcards, sentences, stats, camera,review, practice
    }
}
struct StatsView: View {
    var body: some View {
        VStack {
            Text("Stats View")
            Text("Coming soon!")
        }
        .navigationTitle("Stats")
    }
}
#Preview {
    ContentView()
}
