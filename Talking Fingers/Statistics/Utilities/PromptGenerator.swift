//
//  PromptGenerator.swift
//  Talking Fingers
//
//  Created by Aimee on 2/16/26.

import Foundation

struct PromptGenerator {

    /// Generates prompt for LLM to create 5 ASL practice sentences
    /// - Parameters:
    ///   - flashcards: All user's flashcards with progress info
    ///   - focusTerms: Specific terms to prioritize in sentences (based on selected categories)
    /// - Returns: Formatted prompt string
    static func generatePromptForLLM(from flashcards: [StatsFlashcard], focusTerms: [String] = []) -> String {
        let learningAnalysis = analyzeLearningState(from: flashcards)
        
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
            prompt += "\(index+1). \(flashcard.term): \(flashcard.definition) | Progress: \(flashcard.progress) | Starred: \(flashcard.starred)\n"
        }
        
        if !focusTerms.isEmpty {
            prompt += """
            
            【FOCUS TERMS】
            Prioritize including these terms in your sentences:
            \(focusTerms.joined(separator: ", "))
            
            """
        }
        
        prompt += """

        【ASL GLOSSING RULES】
         No "is/am/are/the/a/to".
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

        【FEW-SHOT EXAMPLES (Follow this style)】
        Input: [APPLE:new, STORE:learning, GO:mastered, ME:mastered]
        Output:
        [
          {"sentence": "APPLE, ME WANT"},
          {"sentence": "STORE, ME GO, BUY APPLE"},
          {"sentence": "YESTERDAY, ME GO STORE, BUY APPLE, ME HAPPY"}
        ]
        
        【CRITICAL RULES】
        1. No repetition: A word can only appear once per sentence.
        2. Use natural ASL word order: TIME + TOPIC + COMMENT + DETAILS
        3. Only use commas for natural pauses (not grammatical clauses)
        4. Create realistic scenarios users would actually sign
        5. Avoid: articles (a/an/the), "is/am/are", "do/does/did", "-ing" endings
        

        【SENTENCE QUALITY CHECKLIST】
        Before generating, ask yourself:
        ✓ Would a real ASL user sign this sentence in daily life?
        ✓ Does the sentence tell a complete story or express a clear idea?
        ✓ Can you visualize the scenario happening?
        ✗ Is it just random words strung together?

        Bad examples to AVOID:
        ✗ "HELLO WATER BOOK FRIEND" (no meaning)
        ✗ "YESTERDAY HOUSE FOOD HAPPY" (no clear action)
        ✗ "THANK-YOU STUDY WORK LOVE" (incoherent)

        Good examples to FOLLOW:
        ✓ "I WANT WATER" (clear request)
        ✓ "YESTERDAY I GO WORK" (complete event)
        ✓ "FRIEND HAPPY, I HAPPY" (cause and effect)

        【GENERATION STRATEGY】
        Step 1: Pick a realistic scenario (greeting, eating, working, etc.)
        Step 2: If focus terms provided, build sentences around them
        Step 3: Choose vocabulary that fits the scenario naturally
        Step 4: Arrange in ASL word order (TIME + TOPIC + COMMENT)
        Step 5: Verify every word has a purpose in the sentence

        Generate exactly 5 sentences with varied complexity.
        Output format (no markdown, raw JSON only):
        [{"sentence": "..."}, {"sentence": "..."}, {"sentence": "..."}, {"sentence": "..."}, {"sentence": "..."}]
        """
    
        return prompt
    }
    
    private static func analyzeLearningState(from flashcards: [StatsFlashcard]) -> String {
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
