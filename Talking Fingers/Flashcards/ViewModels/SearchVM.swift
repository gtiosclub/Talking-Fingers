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
    
    var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    func performSearch() {
        let query = searchText.lowercased().trimmingCharacters(in: .whitespaces)
        
        guard !query.isEmpty else {
            results = []
            return
        }
        
        // category match
        if let category = TermCategory(rawValue: query) {
            results = Term.words(for: category)
            return
        }
        
        // specific word search
        results = Term.allCases.filter {
            $0.rawValue.lowercased().contains(query)
        }
    }
    
    func selectCategory(_ category: TermCategory) {
        searchText = category.rawValue
        results = Term.words(for: category)
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
}
