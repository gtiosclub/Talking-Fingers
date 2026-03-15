//
//  GenerateSentencesView.swift
//  Talking Fingers
//
//  Created by Judy Hsu on 3/12/26.
//

import SwiftUI

struct GenerateSentencesView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedCategories: Set<TermCategory> = []
    @State private var trainingName: String = "Generating..."
    @State private var isGenerating: Bool = false
    @State private var errorMessage: String?
    
    // Callback to return generated sentences
    var onSentencesGenerated: ([AISentenceModel]) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("New Training")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 20)
            
            // Instructions
            VStack(alignment: .leading, spacing: 12) {
                Text("Select categories or specific words you want to practice!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
            
            // Categories Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Categories")
                    .font(.headline)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(TermCategory.allCases, id: \.self) { category in
                        CategoryButton(
                            category: category,
                            isSelected: selectedCategories.contains(category),
                            action: {
                                toggleCategory(category)
                            }
                        )
                    }
                }
            }
            
            // Training Name Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Training Name")
                    .font(.headline)
                
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.gray)
                    Text(trainingName)
                        .foregroundColor(.gray)
                    Spacer()
                    Image(systemName: "sparkles")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 16) {
                Button(action: {
                    dismiss()
                }) {
                    Text("Cancel")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray5))
                        .cornerRadius(12)
                }
                
                Button(action: {
                    startTraining()
                }) {
                    if isGenerating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    } else {
                        Text("Start")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                }
                .background(selectedCategories.isEmpty ? Color.gray : Color.black)
                .cornerRadius(12)
                .disabled(selectedCategories.isEmpty || isGenerating)
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 24)
    }
    
    private func toggleCategory(_ category: TermCategory) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }
    
    private func startTraining() {
        Task {
            isGenerating = true
            errorMessage = nil
            
            do {
                let sentences = try await generateSentencesForCategories(selectedCategories)
                
                await MainActor.run {
                    onSentencesGenerated(sentences)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to generate sentences: \(error.localizedDescription)"
                    isGenerating = false
                }
            }
        }
    }
}

// MARK: - Category Button Component

struct CategoryButton: View {
    let category: TermCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.rawValue.capitalized)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.black : Color(.systemGray6))
                .cornerRadius(20)
        }
    }
}
private func generateSentencesForCategories(_ categories: Set<TermCategory>) async throws -> [AISentenceModel] {
    // 1. Get all terms for the selected categories
    let focusTerms = categories.flatMap { category in
        Term.words(for: category)
    }
    
    guard !focusTerms.isEmpty else {
        throw AIError.invalidRequest
    }
    
    // 2. Filter focus terms - exclude alphabet and numbers for sentence building
    let sentenceTerms = focusTerms.filter { term in
        term.category != .alphabet && term.category != .numbers
    }
    
    // Create flashcards only for sentence-appropriate terms
    let flashcards = sentenceTerms.map { term in
        FlashcardModel(
            term: term.rawValue,
            id: UUID(),
            category: term.category.rawValue,
            gifFileName: nil
        )
    }
    
    // 3. Call AI generation with focus terms
    let aiViewModel = AIViewModel()
    
    // Wait for API key to load
    try await Task.sleep(nanoseconds: 500_000_000)
    
    let sentences = try await aiViewModel.generateAISentences(
        from: flashcards,
        focusTerms: sentenceTerms
    )
        
    print("📋 GENERATED SENTENCES:")
    for (index, sentence) in sentences.enumerated() {
        print("\n--- Sentence \(index + 1) ---")
        print("Text: \(sentence.sentence)")
        print("Gloss: \(sentence.gloss.map { $0.rawValue })")
        print("Practice Type: \(sentence.practiceType.rawValue)")
        print("Completed: \(sentence.completed)")
    }
    print("\n✅ Total: \(sentences.count) sentences\n")
        
    return sentences
}

// MARK: - Preview

struct TestGenerateSentencesView: View {
    @State private var showSheet = false
    @State private var generatedSentences: [AISentenceModel] = []
    
    var body: some View {
        VStack {
            Button("Open New Training") {
                showSheet = true
            }
            .buttonStyle(.borderedProminent)
            
            if !generatedSentences.isEmpty {
                Text("Generated \(generatedSentences.count) sentences!")
                    .padding()
            }
        }
        .sheet(isPresented: $showSheet) {
            GenerateSentencesView { sentences in
                generatedSentences = sentences
                showSheet = false  // Dismiss the sheet
            }
        }
    }
}

#Preview {
    TestGenerateSentencesView()
}
