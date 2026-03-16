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
                Label("home", systemImage: "home")
                    .tag(NavigationSection.home)
                Label("Flashcards", systemImage: "rectangle.stack.fill")
                    .tag(NavigationSection.flashcards)
                Label("Sentences", systemImage: "text.bubble")
                    .tag(NavigationSection.sentences)
                Label("Stats", systemImage: "chart.bar.fill")
                    .tag(NavigationSection.stats)
                Label("Vision", systemImage: "eyeglasses")
                    .tag(NavigationSection.camera)
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
                FlashcardView(flashcard: FlashcardModel(
                    term: .hello,
                    id: UUID(uuidString: "GifDiagramTest") ?? UUID(),
                    category: .commonObjects,
                    gifFileName: "GifDiagramTest.gif"
                ))
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
        }
        
    }
    
    enum NavigationSection: Hashable {
        case home, flashcards, sentences, stats, camera
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
