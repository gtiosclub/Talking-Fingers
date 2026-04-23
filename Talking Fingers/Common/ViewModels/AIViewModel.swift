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
    private let openAIURL = "https://api.openai.com/v1/chat/completions"
    
    /// Shared instance that persists across the app lifecycle.
    /// Using a shared instance avoids repeated Firestore fetches and cold-start delays.
    static let shared = AIViewModel()
    
    init()  {
        fetchAPIKey()
    }
    
    private func fetchAPIKey() {
        Task {
            do {
                let document = try await db.collection("API_KEYS").document("OpenAi").getDocument()
                if let data = document.data(), let key = data["key"] as? String {
                    await MainActor.run {
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
    
    /// Waits for the API key to be available, with a timeout.
    /// - Parameter timeout: Maximum time to wait in seconds (default 10 seconds)
    /// - Throws: `AIError.missingAPIKey` if the key isn't available within the timeout
    func waitForAPIKey(timeout: TimeInterval = 10) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        let pollInterval: UInt64 = 100_000_000 // 100ms in nanoseconds
        
        while openAIKey == nil && Date() < deadline {
            try await Task.sleep(nanoseconds: pollInterval)
        }
        
        guard openAIKey != nil else {
            throw AIError.missingAPIKey
        }
    }

    func generateAISentences(from flashcards: [FlashcardModel], focusTerms: [Term] = []) async throws -> [AISentenceModel] {
        guard let apiKey = openAIKey else {
            throw AIError.missingAPIKey
        }
        
        let prompt = generatePrompt(from: flashcards, focusTerms: focusTerms)
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                [
                    "role": "system",
                    "content": "You are an ASL education assistant. For each sentence return two parts: \"english\" (a natural, readable English sentence) and \"sentence\" (the ASL gloss using only allowed vocabulary). Return ONLY valid JSON, no markdown."
                ],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "response_format": ["type": "json_object"]
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw AIError.invalidRequest
        }
        
        var request = URLRequest(url: URL(string: openAIURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.apiError
        }
        
        guard httpResponse.statusCode == 200 else {
            print("OpenAI API Error - Status Code: \(httpResponse.statusCode)")
            if let errorString = String(data: data, encoding: .utf8) {
                print("Error response: \(errorString)")
            }
            throw AIError.apiError
        }
        
        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        guard let content = openAIResponse.choices.first?.message.content else {
            throw AIError.emptyResponse
        }
        
        guard let contentData = content.data(using: .utf8) else {
            throw AIError.decodingError
        }
        
        let sentencesResponse: [SentenceData]
        do {
            let wrapper = try JSONDecoder().decode(SentencesWrapper.self, from: contentData)
            sentencesResponse = wrapper.sentences
        } catch {
            print("❌ DECODING ERROR:")
            print("Raw content from OpenAI:")
            print(content)
            print("Decoding error: \(error)")
            throw AIError.decodingError
        }

        var aiSentences: [AISentenceModel] = []
        
        for sentenceData in sentencesResponse {
            let glossWordStrings = sentenceData.sentence
                .split(separator: ",")
                .flatMap { $0.split(separator: " ") }
                .map { word in
                    // Remove punctuation and convert to uppercase
                    String(word)
                        .trimmingCharacters(in: .whitespaces)
                        .trimmingCharacters(in: .punctuationCharacters)
                        .uppercased()
                }
                .filter { !$0.isEmpty }
            
            let glossTerms = Term.fromStrings(glossWordStrings)
            
            guard glossTerms.count == glossWordStrings.count else {
                print("⚠️ Warning: Could not convert all words to Terms for sentence: \(sentenceData.sentence)")
                print("Converted \(glossTerms.count)/\(glossWordStrings.count) words")
                print("Unrecognized words: \(Set(glossWordStrings).subtracting(glossTerms.map { $0.rawValue }))")
                continue
            }
            
            let practiceType: PracticeType = .words
            
            let displaySentence = sentenceData.english ?? sentenceData.sentence
            let aiSentence = AISentenceModel(
                sentence: displaySentence,
                score: nil,
                practiceType: practiceType,
                gloss: glossTerms,
                completed: false
            )
            
            aiSentences.append(aiSentence)
        }
        
        return aiSentences
    }

    private func generatePrompt(from flashcards: [FlashcardModel], focusTerms: [Term]) -> String {
        return PromptGenerator.generatePromptForLLM(from: flashcards, focusTerms: focusTerms)
    }
}

// MARK: - Response Models

private struct OpenAIResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
    }
    
    struct Message: Codable {
        let content: String
    }
}

private struct SentencesWrapper: Codable {
    let sentences: [SentenceData]
}

private struct SentenceData: Codable {
    /// Plain English sentence (for display). If missing, fall back to gloss string.
    let english: String?
    /// ASL gloss word order (for signing); only words from vocabulary list.
    let sentence: String
}

// MARK: - Errors

enum AIError: Error {
    case missingAPIKey
    case invalidRequest
    case apiError
    case emptyResponse
    case decodingError
}
