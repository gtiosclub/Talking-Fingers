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
    @State private var modeSelection: PracticeModeSelection
    @State private var trainingName: String = ""
    @State private var isGenerating: Bool = false
    @State private var errorMessage: String?
    @FocusState private var isTrainingNameFocused: Bool
    
    /// Called with generated sentences and the categories used (so Extend can generate more).
    /// Parent should dismiss the sheet and start the session.
    var onSentencesGenerated: ([AISentenceModel], Set<TermCategory>, String) -> Void

    init(
        initialModeSelection: PracticeModeSelection = PracticeModeSelection(signing: true, comprehension: false),
        onSentencesGenerated: @escaping ([AISentenceModel], Set<TermCategory>, String) -> Void
    ) {
        _modeSelection = State(initialValue: initialModeSelection)
        self.onSentencesGenerated = onSentencesGenerated
    }

    private var canGenerate: Bool {
        !trainingName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isGenerating
    }

    private var availableCategories: [TermCategory] {
        TermCategory.allCases.filter { category in
            category != .commonDescriptors
            && category != .dateTime
            && category != .commonObjects
            && category != .feelingsEmotions
        }
    }

    private var effectiveCategories: Set<TermCategory> {
        selectedCategories.isEmpty ? Set(availableCategories) : selectedCategories
    }

    private var isComprehensionOnlyMode: Bool {
        modeSelection.comprehension && !modeSelection.signing
    }

    private var practiceTitle: String {
        isComprehensionOnlyMode ? "New Comprehension Practice" : "New Signing Practice"
    }

    private var practiceTitleColor: Color {
        Color(hex: isComprehensionOnlyMode ? "#58A0DA" : "#71A046")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(practiceTitle)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(practiceTitleColor)
                .padding(.top, 20)
            
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Categories")
                    .font(.system(size: 15, weight: .semibold))
                
                FlowLayout(verticalSpacing: 8, horizontalSpacing: 8) {
                    ForEach(availableCategories, id: \.self) { category in
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
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Training Name")
                    .font(.system(size: 15, weight: .semibold))
                
                TextField("Enter training name", text: $trainingName)
                    .focused($isTrainingNameFocused)
                    .submitLabel(.done)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "#F0F0F0"), lineWidth: 1.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            
            Button(action: {
                startTraining()
            }) {
                if isGenerating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                } else {
                    Text("Start")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            }
            .background(Color(hex: "#97C171").opacity(canGenerate ? 1.0 : 0.5))
            .cornerRadius(20)
            .disabled(!canGenerate)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 15)
        .padding(.top, 10)
        .onAppear {
            DispatchQueue.main.async {
                isTrainingNameFocused = true
            }
        }
    }
    
    private var selectedGlossTerms: [Term] {
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
                let sentences = try await generateSentencesForCategories(effectiveCategories, modeSelection: modeSelection)
                
                await MainActor.run {
                    onSentencesGenerated(sentences, effectiveCategories, trainingName.trimmingCharacters(in: .whitespacesAndNewlines))
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
        let allowedCategories = Set(
            TermCategory.allCases.filter { category in
                category != .commonDescriptors
                && category != .dateTime
                && category != .feelingsEmotions
            }
        )
        let effectiveCategories = categories.isEmpty ? allowedCategories : categories.intersection(allowedCategories)
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
                .font(.system(size: 17))
                .foregroundColor(isSelected ? Color(hex: "#ECA509") : .black)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(isSelected ? Color(hex: "#FDF2D8") : .white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(isSelected ? Color(hex: "#ECA509") : Color(hex: "#F0F0F0"), lineWidth: isSelected ? 0.5 : 1.5)
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
    
    // 3. Call AI generation with focus terms using the shared instance
    let aiViewModel = AIViewModel.shared
    
    // Wait for API key to be available (handles cold starts properly)
    try await aiViewModel.waitForAPIKey()
    
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
            GenerateSentencesView { sentences, _, _ in
                generatedSentences = sentences
                showSheet = false
            }
        }
    }
}

#Preview {
    TestGenerateSentencesView()
}
