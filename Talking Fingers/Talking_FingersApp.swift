//
//  Talking_FingersApp.swift
//  Talking Fingers
//
//  Created by Nikola Cao on 1/24/26.
//

import SwiftUI
import SwiftData
import FirebaseCore
// 1. Conditional Imports
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// 2. Cross-Platform Delegate
class AppDelegate: NSObject {
    // This will work for iOS
    #if os(iOS)
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        setupFirebase()
        return true
    }
    #endif

    // This will work for macOS
    #if os(macOS)
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupFirebase()
    }
    #endif

    private func setupFirebase() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("Firebase configured successfully.")
        }
    }
}

@main
struct Talking_FingersApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @State private var authVM: AuthenticationViewModel
    
    init() {
        FirebaseApp.configure()
        _authVM = State(initialValue: AuthenticationViewModel())
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authVM)
        }
        .modelContainer(sharedModelContainer)
    }
}
