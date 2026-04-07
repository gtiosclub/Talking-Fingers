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
    @State private var modeSelection = PracticeModeSelection(signing: true, comprehension: false)
    @State private var trainingName: String = ""
    @State private var isGenerating: Bool = false
    @State private var errorMessage: String?
    
    /// Called with generated sentences and the categories used (so Extend can generate more).
    /// Parent should dismiss the sheet and start the session.
    var onSentencesGenerated: ([AISentenceModel], Set<TermCategory>) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("New Training")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 20)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Select categories or specific words you want to practice!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color(hex: 0xF2F2F7))
                    .cornerRadius(12)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Filter Categories")
                    .font(.headline)
                
                FlowLayout(verticalSpacing: 8, horizontalSpacing: 8) {
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
            
            // MARK: - Mode Selection (multi-select, at least one required)
            VStack(alignment: .leading, spacing: 12) {
                Text("Modes")
                    .font(.headline)

                HStack(spacing: 12) {
                    ModeToggleButton(
                        label: "Sign",
                        isSelected: modeSelection.signing,
                        action: {
                            // Don't allow deselecting if it's the only one on
                            if modeSelection.signing && !modeSelection.comprehension { return }
                            modeSelection.signing.toggle()
                        }
                    )

                    ModeToggleButton(
                        label: "Comprehend",
                        isSelected: modeSelection.comprehension,
                        action: {
                            if modeSelection.comprehension && !modeSelection.signing { return }
                            modeSelection.comprehension.toggle()
                        }
                    )
                }
            }

            // Training Name Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Training Name")
                    .font(.headline)
                
                TextField("Enter training name", text: $trainingName)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: 0xF2F2F7))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
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
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.white))
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
                .background(isGenerating ? Color.gray : Color.black)
                .cornerRadius(12)
                .disabled(isGenerating)
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 24)
    }
    
    private var selectedGlossTerms: [Term] {
        let effectiveCategories = selectedCategories.isEmpty ? Set(TermCategory.allCases) : selectedCategories
        let terms = effectiveCategories.flatMap { Term.words(for: $0) }
        let unique = Array(Set(terms))
        return unique.sorted { $0.rawValue < $1.rawValue }
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
                let effectiveCategories = selectedCategories.isEmpty ? Set(TermCategory.allCases) : selectedCategories
                let sentences = try await generateSentencesForCategories(effectiveCategories, modeSelection: modeSelection)
                
                await MainActor.run {
                    onSentencesGenerated(sentences, effectiveCategories)
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to generate sentences: \(error.localizedDescription)"
                    isGenerating = false
                }
            }
        }
    }

    /// Generate 5 sentences for the given categories (e.g. for Extend in a session).
    static func generateSentences(categories: Set<TermCategory>, modeSelection: PracticeModeSelection = PracticeModeSelection(signing: true, comprehension: false)) async throws -> [AISentenceModel] {
        let effectiveCategories = categories.isEmpty ? Set(TermCategory.allCases) : categories
        return try await generateSentencesForCategories(effectiveCategories, modeSelection: modeSelection)
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
                .foregroundColor(Color(hex: "#737373") ?? Color.gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isSelected ? (Color(hex: "#EBEBEB") ?? Color(white: 0.92)) : Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.black, lineWidth: 1)
                )
        }
    }
}

// MARK: - Mode Toggle Button

struct ModeToggleButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Circle()
                    .fill(isSelected ? Color(hex: "#D4A843") ?? .yellow : Color.gray.opacity(0.3))
                    .frame(width: 10, height: 10)
            }
            .foregroundColor(Color(hex: "#737373") ?? Color.gray)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? (Color(hex: "#EBEBEB") ?? Color(white: 0.92)) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.black, lineWidth: 1)
            )
        }
    }
}

private func generateSentencesForCategories(_ categories: Set<TermCategory>, modeSelection: PracticeModeSelection = PracticeModeSelection(signing: true, comprehension: false)) async throws -> [AISentenceModel] {
    // 1. Get all terms for the selected categories
    let focusTerms = categories.flatMap { category in
        Term.words(for: category)
    }
    
    guard !focusTerms.isEmpty else {
        throw AIError.invalidRequest
    }
    
    // 2. Determine which terms should drive sentence generation.
    // If there are any non-alphabet/number terms, prioritize those for sentences.
    // If the user ONLY picked alphabet and/or numbers, still allow those terms
    // so we can generate spelling/number-focused practice.
    let nonAlphaNumericTerms = focusTerms.filter { term in
        term.category != .alphabet && term.category != .numbers
    }
    let sentenceTerms = nonAlphaNumericTerms.isEmpty ? focusTerms : nonAlphaNumericTerms
    
    // Create flashcards only for sentence-appropriate terms
    let flashcards = sentenceTerms.map { term in
        FlashcardModel(
            term: term,
            id: UUID(),
            category: term.category,
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

    // 4. Assign practiceType based on mode selection
    let assignedSentences = assignPracticeTypes(to: sentences, modeSelection: modeSelection)
        
    print("📋 GENERATED SENTENCES:")
    for (index, sentence) in assignedSentences.enumerated() {
        print("\n--- Sentence \(index + 1) ---")
        print("Text: \(sentence.sentence)")
        print("Gloss: \(sentence.gloss.map { $0.rawValue })")
        print("Practice Type: \(sentence.practiceType.rawValue)")
        print("Completed: \(sentence.completed)")
    }
    print("\n✅ Total: \(assignedSentences.count) sentences\n")
        
    return assignedSentences
}

/// Assigns practiceType to sentences based on the user's mode selection.
/// - Both modes: first half signing, second half comprehension
/// - Signing only: all .words
/// - Comprehension only: all .comprehension
private func assignPracticeTypes(to sentences: [AISentenceModel], modeSelection: PracticeModeSelection) -> [AISentenceModel] {
    guard !sentences.isEmpty else { return sentences }

    if modeSelection.signing && modeSelection.comprehension {
        // Split roughly half-and-half
        let halfIndex = sentences.count / 2
        return sentences.enumerated().map { index, sentence in
            var s = sentence
            s.practiceType = index < halfIndex ? .words : .comprehension
            return s
        }
    } else if modeSelection.comprehension {
        return sentences.map { sentence in
            var s = sentence
            s.practiceType = .comprehension
            return s
        }
    } else {
        // signing only (default)
        return sentences.map { sentence in
            var s = sentence
            s.practiceType = .words
            return s
        }
    }
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
            GenerateSentencesView { sentences, _ in
                generatedSentences = sentences
                showSheet = false
            }
        }
    }
}

#Preview {
    TestGenerateSentencesView()
}
