//
//  SearchVM.swift
//  Talking Fingers
//
//  Created by Sanvi Adusumilli on 4/6/26.
//
import Foundation
import Combine

class SearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var results: [Term] = []
    
    private let recentSearchesKey = "recentSearches"
    private let maxRecentSearches = 5
    
    @Published var recentSearches: [String] = []
    
    init() {
        recentSearches = UserDefaults.standard.stringArray(forKey: recentSearchesKey) ?? []
    }
    
    var categories: [TermCategory] {
        TermCategory.allCases
    }
    
    var alphabetTerms: [Term] {
        Term.words(for: .alphabet)
    }
    
    var numberTerms: [Term] {
        Term.words(for: .numbers)
    }
    
    var vocabTerms: [Term] {
        Term.allCases
            .filter { $0.category != .alphabet && $0.category != .numbers }
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }
    
    var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    func performSearch() {
        let query = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !query.isEmpty else {
            results = []
            return
        }
        
        let normalizedQuery = normalize(query)
        let queryTokens = Set(tokenize(normalizedQuery))
        
        // Category match (exact)
        if let category = exactCategoryMatch(for: normalizedQuery) {
            results = Term.words(for: category)
            return
        }
        
        // Idea/intent-based ranked search
        let ranked = Term.allCases
            .compactMap { term -> (term: Term, score: Int)? in
                let score = score(for: term, normalizedQuery: normalizedQuery, queryTokens: queryTokens)
                return score > 0 ? (term, score) : nil
            }
            .sorted {
                if $0.score != $1.score { return $0.score > $1.score }
                return $0.term.displayName.localizedCaseInsensitiveCompare($1.term.displayName) == .orderedAscending
            }
        
        results = ranked.map(\.term)
    }
    
    func selectCategory(_ category: TermCategory) {
        searchText = category.rawValue
        results = Term.words(for: category)
    }
    
    func selectTerm(_ term: Term) {
        searchText = term.displayName
        results = [term]
        saveRecentSearch(term.displayName)
    }
    
    func saveRecentSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        var updated = recentSearches.filter { $0.lowercased() != trimmed.lowercased() }
        updated.insert(trimmed, at: 0)
        if updated.count > maxRecentSearches {
            updated = Array(updated.prefix(maxRecentSearches))
        }
        
        recentSearches = updated
        UserDefaults.standard.set(updated, forKey: recentSearchesKey)
    }
    
    func selectRecentSearch(_ search: String) {
        searchText = search
        saveRecentSearch(search)
        performSearch()
    }
    
    func clearSearch() {
        searchText = ""
        results = []
    }
    
    // MARK: - Idea Search Helpers
    
    private func normalize(_ text: String) -> String {
        let lowercase = text.lowercased()
        let allowed = CharacterSet.alphanumerics.union(.whitespaces)
        let sanitizedScalars = lowercase.unicodeScalars.map { allowed.contains($0) ? Character($0) : " " }
        return String(sanitizedScalars).replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func tokenize(_ normalizedText: String) -> [String] {
        normalizedText
            .split(separator: " ")
            .map(String.init)
            .filter { !$0.isEmpty }
    }
    
    private func exactCategoryMatch(for normalizedQuery: String) -> TermCategory? {
        TermCategory.allCases.first { category in
            normalize(category.rawValue) == normalizedQuery
        }
    }
    
    private func expandedQueryTerms(from queryTokens: Set<String>, normalizedQuery: String) -> Set<String> {
        var expanded = queryTokens
        
        for token in queryTokens {
            if let related = conceptMap[token] {
                expanded.formUnion(related)
            }
        }
        
        for (phrase, related) in phraseConceptMap where normalizedQuery.contains(phrase) {
            expanded.formUnion(related)
        }
        
        return expanded
    }
    
    private func score(for term: Term, normalizedQuery: String, queryTokens: Set<String>) -> Int {
        let termValue = normalize(term.rawValue)
        let termTokens = Set(tokenize(termValue))
        let isIntentQuery = queryTokens.count > 1
        var score = 0
        
        // Strong exact/substring match
        if termValue == normalizedQuery {
            score += 250
        } else if termValue.count >= 2 && (termValue.contains(normalizedQuery) || normalizedQuery.contains(termValue)) {
            score += 120
        }
        
        let expanded = expandedQueryTerms(from: queryTokens, normalizedQuery: normalizedQuery)
        
        // Token overlap (supports phrase and idea matching)
        for token in expanded {
            if termTokens.contains(token) {
                score += 70
            } else if termValue.contains(token) || token.contains(termValue) {
                score += 35
            }
        }
        
        // Category intent boost
        if let categoryKeywords = categoryIntentKeywords[term.category], !expanded.isDisjoint(with: categoryKeywords) {
            score += 40
        }
        
        // Prevent alphabet letters from dominating phrase/intention searches.
        if isIntentQuery && term.category == .alphabet {
            score -= 200
        }
        
        return score
    }
    
    private let phraseConceptMap: [String: Set<String>] = [
        "grocery store": ["store", "food", "eat", "go", "water"],
        "go shopping": ["store", "go", "food", "buy"],
        "eat dinner": ["eat", "food", "restaurant", "night"],
        "go to school": ["go", "school", "study", "learn", "class"],
        "how are you": ["how", "you", "feel", "happy", "sad"],
        "what is your name": ["what", "your", "name"],
        "where do you live": ["where", "you", "live", "home"],
        "see you later": ["see", "you", "later", "bye"]
    ]
    
    private let conceptMap: [String: Set<String>] = [
        "grocery": ["store", "food", "eat", "water"],
        "groceries": ["store", "food", "eat", "water"],
        "shopping": ["store", "go", "buy"],
        "shop": ["store", "go", "buy"],
        "buy": ["store", "food"],
        "travel": ["go", "visit", "car", "where"],
        "school": ["school", "study", "learn", "class"],
        "work": ["work", "office", "job"],
        "family": ["mother", "father", "sister", "brother", "family"],
        "sad": ["sad", "feel", "frustrated", "tired"],
        "happy": ["happy", "excited", "feel", "love"],
        "restaurant": ["restaurant", "food", "eat", "drink"],
        "time": ["today", "tomorrow", "week", "month", "year", "now"],
        "where": ["where", "home", "school", "store", "park"]
    ]
    
    private let categoryIntentKeywords: [TermCategory: Set<String>] = [
        .greetings: ["hello", "hi", "bye", "meet", "later", "how", "sorry"],
        .personalInformation: ["name", "age", "live", "from", "student", "work", "favorite", "who", "what", "when", "where", "why", "you", "my"],
        .family: ["family", "mother", "father", "mom", "dad", "sister", "brother", "son", "daughter"],
        .verbs: ["go", "come", "want", "eat", "drink", "study", "help", "play", "watch", "learn", "visit", "talk"],
        .dateTime: ["today", "tomorrow", "yesterday", "now", "week", "month", "year", "morning", "night"],
        .feelingsEmotions: ["happy", "sad", "angry", "excited", "tired", "nervous", "confused", "love", "feel"],
        .locations: ["home", "school", "job", "office", "store", "hospital", "restaurant", "library", "park", "where"],
        .commonDescriptors: ["good", "bad", "big", "small", "more", "less", "same", "different"],
        .commonObjects: ["food", "water", "book", "phone", "computer", "car", "house", "dog", "cat", "movie", "music"],
        .alphabet: [],
        .numbers: []
    ]
}
