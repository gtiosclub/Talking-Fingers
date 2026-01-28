//
//  Talking_FingersApp.swift
//  Talking Fingers
//
//  Created by Nikola Cao on 1/24/26.
//

import SwiftUI
import SwiftData
import FirebaseCore


class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
      //FirebaseApp.configure()
      if let app = FirebaseApp.app() {
          print("Firebase configured with name: \(app.name)")
      } else {
          print("Firebase configuration failed")
      }
    return true
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
            EntryView()
                .environment(authVM)
        }
        .modelContainer(sharedModelContainer)
    }
}
