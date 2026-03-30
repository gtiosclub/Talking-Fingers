//
//  ContentView.swift
//  Talking Fingers
//
//  Created by Nikola Cao on 1/24/26.
//
import SwiftUI
struct ContentView: View {
    @Environment(AuthenticationViewModel.self) var authVM
    
    var body: some View {
        Group {
            if authVM.currentUser != nil {
                MainNavigationView()
            } else {
                EntryView()
            }
        }
        .environment(authVM)
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
                Label("Practice Test", systemImage: "pencil.and.scribble")
                    .tag(NavigationSection.practice)
            }
            .navigationTitle("Talking Fingers")
        } detail: {
            // Detail view based on selection
            detailView(for: selectedSection ?? .home)
                .environment(authVM)
        }
    }
    
    @ViewBuilder
    private func detailView(for section: NavigationSection) -> some View {
        switch section {
        case .home:
            NavigationStack {
                Text("home")
            }
            
        case .flashcards:
            NavigationStack {
#if os(iOS)
                let dummyCard = FlashcardModel(
                    term: .hello,
                    id: UUID(),
                    category: .greetings
                )

                return StartCardComponent(
                    modeTitle: "Exercise",
                    topic: "Greetings",
                    completed: 0,
                    total: 12,
                    imageName: "greetingsIllustration",
                    primaryAction: {},
                    secondaryAction: {},
                    closeAction: {},
                    learnFlashcard: dummyCard,
                    learnProgress: 0.25
                )
#endif
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
            
        case .practice:
            NavigationStack {
#if os(iOS)
                SigningPracticeView()
                    .environment(authVM)
                #endif
            }
            
        }
       
        
    }
    
    enum NavigationSection: Hashable {
        case home, flashcards, sentences, stats, camera, practice
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
