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

    // MARK: - Generate AI Sentences
    
    /// Generates 3 ASL practice sentences (easy, medium, hard) using OpenAI
    /// - Parameter flashcards: Array of StatsFlashcard representing user's vocabulary
    /// - Returns: Array of 3 AISentenceModel objects with different difficulty levels
    /// - Throws: AIError if API key is missing, request fails, or response cannot be decoded
    func generateAISentences(from flashcards: [StatsFlashcard]) async throws -> [AISentenceModel] {
        guard let apiKey = openAIKey else {
            throw AIError.missingAPIKey
        }
        
        // 1. Generate prompt using PromptGenerator
        let prompt = generatePrompt(from: flashcards)
        
        // 2. Create OpenAI request
        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                [
                    "role": "system",
                    "content": "You are an ASL education assistant. Generate practice sentences with both English text and ASL gloss. Return ONLY valid JSON, no markdown formatting."
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
        
        // 3. Make API call
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
        
        // 4. Decode OpenAI response
        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        guard let content = openAIResponse.choices.first?.message.content else {
            throw AIError.emptyResponse
        }
        
        // 5. Parse JSON content to get sentences
        guard let contentData = content.data(using: .utf8) else {
            throw AIError.decodingError
        }
        
        let wrapper = try JSONDecoder().decode(SentencesWrapper.self, from: contentData)
        let sentencesResponse = wrapper.sentences
        
        // 6. Convert to AISentenceModel array
        var aiSentences: [AISentenceModel] = []
        
        for sentenceData in sentencesResponse {
            // Split sentence into individual gloss words
            let glossWords = sentenceData.sentence
                .split(separator: ",")
                .flatMap { $0.split(separator: " ") }
                .map { String($0).trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            
            // Create score array initialized with zeros (not practiced yet)
            let score = Array(repeating: 0, count: glossWords.count)
            
            // Map difficulty string to enum
            let difficulty: Difficulty
            switch sentenceData.difficulty.lowercased() {
            case "easy":
                difficulty = .easy
            case "medium":
                difficulty = .medium
            case "hard":
                difficulty = .hard
            default:
                difficulty = .medium
            }
            
            // Assign practice type based on difficulty
            let practiceType: PracticeType = (difficulty == .easy) ? .words : .signs
            
            let aiSentence = AISentenceModel(
                sentence: sentenceData.sentence,
                score: score,
                practiceType: practiceType,
                difficulty: difficulty,
                gloss: glossWords
            )
            
            aiSentences.append(aiSentence)
        }
        
        return aiSentences
    }

    // MARK: - Private Helper Methods
    
    /// Creates prompt for OpenAI using PromptGenerator
    /// - Parameter flashcards: User's vocabulary flashcards
    /// - Returns: Formatted prompt string
    private func generatePrompt(from flashcards: [StatsFlashcard]) -> String {
        return PromptGenerator.generatePromptForLLM(from: flashcards)
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
    let difficulty: String
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
