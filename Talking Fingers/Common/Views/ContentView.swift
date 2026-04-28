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
            if authVM.isInitializingSession {
                Color.white
                    .ignoresSafeArea()
            } else if authVM.currentUser != nil {
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
        ZStack(alignment: .bottom) {
            detailView(for: selectedSection)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            MainFloatingTabBar(selectedSection: $selectedSection)
        }
        .environment(authVM)
        .background(Color.white.ignoresSafeArea())
        #endif
    }
    
    @ViewBuilder
    private func detailView(for section: NavigationSection) -> some View {
        switch section {
        case .home:
            DashboardView()
                .environment(authVM)
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
                SavedPracticeView()
            }
        }
    }
    
    enum NavigationSection: Hashable {
        case home, stats, camera, review, practice
    }
}

#if os(iOS)
private struct MainFloatingTabBar: View {
    @Binding var selectedSection: MainNavigationView.NavigationSection
    
    var body: some View {
        HStack {
            Spacer()
            tabButton(
                icon: "house.fill",
                title: "Home",
                section: .home
            )
            Spacer()
            tabButton(
                icon: "hand.raised.fill",
                title: "Practice",
                section: .practice
            )
            Spacer()
            tabButton(
                icon: "person.fill",
                title: "Profile",
                section: .stats
            )
            Spacer()
        }
        .padding(.vertical, 9)
        .background(Color.white)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.08), radius: 15, x: 0, y: 5)
        .padding(.horizontal, 30)
        .padding(.bottom, -20)
    }
    
    private func tabButton(
        icon: String,
        title: String,
        section: MainNavigationView.NavigationSection
    ) -> some View {
        let isSelected = selectedSection == section
        return Button {
            selectedSection = section
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.jakarta(size: 22))
                Text(title)
                    .font(.jakarta(size: 10))
                    .fontWeight(.semibold)
            }
            .foregroundColor(
                isSelected
                ? Color(red: 0.30, green: 0.55, blue: 0.85)
                : Color.gray.opacity(0.6)
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(
                        isSelected
                        ? Color(red: 0.30, green: 0.55, blue: 0.85).opacity(0.15)
                        : Color.clear
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
#endif
struct StatsView: View {
    var body: some View {
        #if os(iOS)
        ProfileWidgetsView(presentation: .embedded)
        #else
        MacProfileView()
        #endif
    }
}
#Preview {
    ContentView()
}
