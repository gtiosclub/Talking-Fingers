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
        if authVM.currentUser != nil {
            MainNavigationView()
                .environment(authVM)
        } else {
            EntryView()
                .environment(authVM)
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
                Label("Home", systemImage: "house.fill")
                    .tag(NavigationSection.home)
                Label("Flashcards", systemImage: "rectangle.stack.fill")
                    .tag(NavigationSection.flashcards)
                Label("Stats", systemImage: "chart.bar.fill")
                    .tag(NavigationSection.stats)
            }
            .navigationTitle("Talking Fingers")
        } detail: {
            // Detail view based on selection
            Group {
                switch selectedSection {
                case .home:
                    NavigationStack {
                        HomeView()
                    }
                case .flashcards:
                    NavigationStack {
                        FlashcardView()
                    }
                case .stats:
                    NavigationStack {
                        StatsView()
                    }
                case .none:
                    Text("Select a section")
                }
            }
            .environment(authVM)
        }
    }
    
    enum NavigationSection: Hashable {
        case home, flashcards, stats
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
