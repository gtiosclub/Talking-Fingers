//
//  PromptGenerator.swift
//  Talking Fingers
//
//  Created by Aimee on 2/16/26.

import Foundation

struct PromptGenerator {

    /// Generates prompt for LLM to create ASL practice sentences
    /// - Parameters:
    ///   - flashcards: All user's flashcards with progress info
    ///   - focusTerms: Specific terms to prioritize in sentences (based on selected categories)
    /// - Returns: Formatted prompt string
    static func generatePromptForLLM(
        from flashcards: [FlashcardModel],
        focusTerms: [Term] = [],
        sentenceCount: Int = 5
    ) -> String {
        let learningAnalysis = analyzeLearningState(from: flashcards)
        // Full app vocabulary – gloss is allowed to use ANY of these terms,
        // but should prioritize the focusTerms (selected categories).
        let allowedTerms = Term.allCases
        let allowedCategories = Set(focusTerms.map { $0.category })
        let focusCategories = allowedCategories
        let isAlphabetOnly = !focusCategories.isEmpty && focusCategories == [.alphabet]
        let isNumbersOnly = !focusCategories.isEmpty && focusCategories == [.numbers]
        
        var prompt = """
        You are a sign language practice sentence generator for ASL learners.
        Generated sentences will be signed word-by-word by the user through a camera.
        Keep sentences natural for signing — avoid idioms, complex grammar, 
        or words that don't have common ASL signs.
        
        【USER STATE】
        \(learningAnalysis)
        
        【FLASHCARDS】
        """
        
        for (index, flashcard) in flashcards.enumerated() {
            prompt += "\(index+1). \(flashcard.term.rawValue) | Progress: \(flashcard.progress) | Starred: \(flashcard.starred)\n"
        }
        
        if !focusTerms.isEmpty {
            let focusTermStrings = focusTerms.map { $0.rawValue }.joined(separator: ", ")
            prompt += """
            
            【FOCUS TERMS】
            Prioritize including these terms in your sentences:
            \(focusTermStrings)
            
            """
            
            if focusCategories.count == 1, let singleCategory = focusCategories.first {
                prompt += """
                
                IMPORTANT: The learner selected exactly ONE category (\(singleCategory.rawValue)).
                At least one focus-term from this category MUST appear in EVERY SINGLE sentence you generate.
                Do not generate any sentence that omits this category entirely.
                """
            }
        }
        
        // Make category intent explicit to the model (based on selected focus terms).
        if !focusCategories.isEmpty {
            let cats = focusCategories.map { $0.rawValue }.sorted().joined(separator: ", ")
            prompt += """
            
            【SELECTED CATEGORIES (IMPORTANT)】
            The learner selected these categories: \(cats)
            You MUST generate scenarios that naturally fit these categories.
            """
            
            if isAlphabetOnly {
                prompt += """
                
                【ALPHABET-FOCUSED MODE】
                Strongly prioritize ALPHABET terms in both English scenarios and gloss.
                - English should usually be about finger-spelling a name or word (e.g. \"My name is John.\", \"Your name is Amy.\").
                - Gloss (\"sentence\") should contain sequences of letters separated by spaces (e.g. \"J O H N\"), and MAY also include other allowed vocabulary from the app if it helps the scenario.
                - Repeating letters is allowed in this mode (e.g. \"A L L Y\").
                """
            } else if isNumbersOnly {
                prompt += """
                
                【NUMBERS-FOCUSED MODE】
                Strongly prioritize NUMBER terms from the vocabulary.
                - English should describe simple number scenarios (age, quantity, time, etc.).
                - Gloss (\"sentence\") should prominently feature the relevant number tokens and MAY also use other allowed vocabulary from the app as needed.
                """
            }
        }
        
        prompt += """

        【ASL GLOSSING RULES】
         No "is/am/are/the/a/to".
         Use ME for the first-person pronoun in gloss, never I. Only use I when it is the literal alphabet letter inside a finger-spelled word/name (for example "I A N").
         Questions: Put the question word (WHAT, WHERE, WHO) at the END.
            Wrong: "WHAT YOUR NAME?"
            Right: "YOUR NAME WHAT?"
         Adjectives: Put them AFTER the noun.
            Right: "APPLE RED"

        【TARGET WORD GOALS】
         Create sentences that balance new/learning words with mastered words
         Prioritize focus terms when provided
         Vary sentence length: some short (3-4 words), some medium (5-6 words), some longer (7-9 words)
         Each sentence should have at least 1-2 words the user is still learning

        【TWO-PART OUTPUT】
        Each item must have:
        1. "english": A natural, coherent English sentence the learner reads first (plain English, normal grammar).
        2. "sentence": The ASL gloss for signing — ONLY words from the app's taught vocabulary list below (ALLOWED GLOSS VOCAB), in ASL word order (TIME + TOPIC + COMMENT). No articles, no "is/am/are". Use commas for pauses.

        The English sentence and the gloss must express the SAME meaning. Think of a clear, realistic scenario, write it in normal English, then convert to gloss using only allowed words.

        【FEW-SHOT EXAMPLES】
        Input: [APPLE, STORE, GO, ME, WANT, BUY, YESTERDAY, HAPPY]
        Output:
        [
          {"english": "I want an apple.", "sentence": "APPLE, ME WANT"},
          {"english": "I went to the store to buy an apple.", "sentence": "YESTERDAY, ME GO STORE, BUY APPLE"},
          {"english": "My friend is happy and I am happy too.", "sentence": "FRIEND HAPPY, ME HAPPY"}
        ]

        【ALLOWED GLOSS VOCAB】
        You may ONLY use these tokens in the gloss (\"sentence\"):
        \(allowedTerms.map { $0.rawValue }.sorted().joined(separator: ", "))
        The focus terms listed above MUST appear frequently across the \(sentenceCount) sentences, but you can also use other tokens from this list.

        【CRITICAL RULES】
        1. English MUST be a normal, grammatical sentence that makes sense. No random words.
        2. Gloss ("sentence") MUST use only words from the ALLOWED GLOSS VOCAB list above. ASL word order: TIME + TOPIC + COMMENT + DETAILS.
        3. For first person, use ME in gloss. Do NOT use I unless it is the alphabet letter in a finger-spelled word/name.
        4. No repetition: a word appears at most once per sentence (EXCEPT in Alphabet-only mode, where repeating letters is allowed).
        5. One clear idea per sentence (request, event, description, etc.).
        6. DIVERSITY (very important): All 5 sentences MUST be distinct from each other. No two items may share the same English sentence, and no two items may share the same gloss token sequence. Use different scenarios, different subjects, different verbs, and different sentence lengths across the 5 items — even when a focus-term is required in every sentence, vary everything else around it.

        【QUALITY】
        ✓ English: Would a native speaker say this? Clear scenario?
        ✓ Gloss: Same meaning as the English, using only list words in ASL order?
        ✗ Bad: "HELLO WATER BOOK FRIEND" (no meaning)
        ✗ Bad: English that doesn’t match the gloss

        【GENERATION STRATEGY】
        Step 1: Choose a realistic scenario (greeting, shopping, daily action, feeling).
        Step 2: Write one natural English sentence for that scenario.
        Step 3: Convert to ASL gloss using ONLY words from the flashcard list, in correct ASL order.
        Step 4: Verify every gloss word is in the list and the two parts match in meaning.

        Generate exactly \(sentenceCount) sentences. Vary length and scenarios.
        Output format (no markdown, raw JSON only):
        {"sentences": [{"english": "Natural English sentence here.", "sentence": "GLOSS WORD ORDER"}, ...]}
        """
    
        return prompt
    }
    
    private static func analyzeLearningState(from flashcards: [FlashcardModel]) -> String {
        let total = flashcards.count
        guard total > 0 else { return "No flashcards." }
        
        let counts: [String: Int] = [
            "new": flashcards.filter { $0.progress == .new }.count,
            "learning": flashcards.filter { $0.progress == .learning }.count,
            "polishing": flashcards.filter { $0.progress == .polishing }.count,
            "mastered": flashcards.filter { $0.progress == .mastered }.count
        ]
        
        let recentSuccesses = flashcards.filter {
            guard let d = $0.lastSucceeded else { return false }
            return Calendar.current.dateComponents([.day], from: d, to: Date()).day ?? Int.max <= 7
        }.count
        
        let order = ["new", "learning", "polishing", "mastered"]
        let dist = order.map { "\($0):\(counts[$0]!)" }.joined(separator: " ")
        
        let profile: String = {
            let newR = Double(counts["new"]!) / Double(total)
            let masteredR = Double(counts["mastered"]!) / Double(total)
            let advancedR = Double(counts["polishing"]! + counts["mastered"]!) / Double(total)
            
            if newR >= 0.5 { return "BEGINNER" }
            if masteredR >= 0.6 { return "ADVANCED" }
            if advancedR >= 0.6 { return "NEAR_MASTERY" }
            if newR + Double(counts["learning"]!) / Double(total) >= 0.6 { return "BUILDING" }
            return "MIXED"
        }()
        
        return "total:\(total) \(dist) recent_success:\(recentSuccesses) profile:\(profile)"
    }
}
