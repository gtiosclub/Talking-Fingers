//
//  AIViewModel.swift
//  Talking Fingers
//
//  Created by Krish Prasad on 2/15/26.
//
import Foundation
import Observation
import FirebaseFirestore


@Observable class AIViewModel {
    var openAIKey: String?
    let db = Firestore.firestore()
    init()  {
        fetchAPIKey()
    }
    
    private func fetchAPIKey() {
        Task {
            do {
                let document = try await db.collection("API_KEYS").document("OpenAi").getDocument()
                if let data = document.data(), let key = data["key"] as? String {
                    DispatchQueue.main.async {
                        self.openAIKey = key
                        print("key found")
                    }
                } else {
                    print("No key found in document")
                }
            } catch {
                print("Error fetching API key from Firestore: \(error)")
            }
        }
    }
}
