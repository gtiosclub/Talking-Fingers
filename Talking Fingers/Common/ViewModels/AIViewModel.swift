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

    func generateAISentences(from flashcards: [StatsFlashcard]) async throws -> [AISentenceModel] {
        guard let apiKey = openAIKey else {
            throw AIError.missingAPIKey
        }
        
        let prompt = generatePrompt(from: flashcards)
        
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
        
        let wrapper = try JSONDecoder().decode(SentencesWrapper.self, from: contentData)
        let sentencesResponse = wrapper.sentences
        
        var aiSentences: [AISentenceModel] = []
        
        for sentenceData in sentencesResponse {
            let glossWords = sentenceData.sentence
                .split(separator: ",")
                .flatMap { $0.split(separator: " ") }
                .map { String($0).trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            
            let score = Array(repeating: 0, count: glossWords.count)
            
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
