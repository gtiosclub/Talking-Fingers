//
//  SearchView.swift
//  Talking Fingers
//
//  Created by Sanvi Adusumilli on 3/30/26.
//
import SwiftUI

struct SearchView: View {
    
    @StateObject private var vm = SearchViewModel()
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                HStack(spacing: 6) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                    Text("Leave")
                        .font(.system(size: 17))
                        .foregroundColor(.gray)
                }
                
                HStack(spacing: 10) {
                    HStack {
                        TextField("Search for a word or phrase...", text: $vm.searchText)
                            .focused($isFocused)
                            .font(.system(size: 17))
                            .onChange(of: vm.searchText) {
                                vm.performSearch()
                            }
                            .onSubmit {
                                vm.saveRecentSearch(vm.searchText)
                            }
                        
                        if !vm.searchText.isEmpty {
                            Button {
                                vm.clearSearch()
                                isFocused = false
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 44)
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                if vm.isSearching {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(vm.results.count) results found")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .padding(.bottom, 8)
                        
                        VStack(spacing: 0) {
                            ForEach(vm.results, id: \.self) { term in
                                VStack(spacing: 0) {
                                    HStack {
                                        Text(term.displayName.capitalized)
                                            .font(.system(size: 19))
                                        Spacer()
                                    }
                                    .padding(.vertical, 14)
                                    
                                    Divider()
                                }
                            }
                        }
                    }
                    
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        
                        if !vm.recentSearches.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Recent Searches")
                                    .font(.system(size: 15))
                                    .foregroundColor(.primary)
                                
                                ForEach(vm.recentSearches, id: \.self) { search in
                                    VStack(spacing: 0) {
                                        HStack {
                                            Text(search)
                                                .font(.system(size: 20, weight: .semibold))
                                                .foregroundColor(.black)
                                            Spacer()
                                            Image(systemName: "arrow.up.right")
                                                .font(.system(size: 13))
                                                .foregroundColor(.gray)
                                        }
                                        .padding(.vertical, 10)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            vm.selectRecentSearch(search)
                                            isFocused = true
                                        }
                                        
                                        Divider()
                                    }
                                }
                            }
                        }
                        
                        Text("Categories")
                            .font(.system(size: 28, weight: .bold))
                            .padding(.top, vm.recentSearches.isEmpty ? 0 : 4)
                        
                        VStack(spacing: 14) {
                            ForEach(vm.categories, id: \.self) { category in
                                categoryRow(for: category)
                                    .onTapGesture {
                                        vm.selectCategory(category)
                                        vm.saveRecentSearch(category.displayName)
                                        isFocused = true
                                    }
                            }
                        }
                    }
                }
                
                Spacer(minLength: 24)
            }
            .padding()
            .padding(.top, 16)
        }
        .ignoresSafeArea()
    }
    
    @ViewBuilder
    private func categoryRow(for category: TermCategory) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 248/255, green: 188/255, blue: 57/255))
                    .frame(width: 52, height: 52)
                
                Image(systemName: placeholderIcon(for: category))
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(category.displayName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(subtitle(for: category))
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color(red: 255/255, green: 248/255, blue: 229/255))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(red: 248/255, green: 188/255, blue: 57/255), lineWidth: 1.5)
        )
    }
    
    private func placeholderIcon(for category: TermCategory) -> String {
        switch category {
        case .alphabet:             return "a.square"
        case .numbers:              return "number"
        case .greetings:            return "hand.wave"
        case .personalInformation:  return "person.text.rectangle"
        case .family:               return "figure.2.and.child.holdinghands"
        case .verbs:                return "bolt"
        case .dateTime:             return "calendar"
        case .feelingsEmotions:     return "heart"
        case .locations:            return "mappin.and.ellipse"
        case .commonDescriptors:    return "text.magnifyingglass"
        case .commonObjects:        return "cube"
        }
    }

    private func subtitle(for category: TermCategory) -> String {
        switch category {
        case .alphabet:             return "Learn fingerspelling letters A–Z"
        case .numbers:              return "Learn counting and number signs"
        case .greetings:            return "Say hello and common phrases"
        case .personalInformation:  return "Share your name, age, and more"
        case .family:               return "Signs for relatives and loved ones"
        case .verbs:                return "Express actions and movement"
        case .dateTime:             return "Tell time, days, and dates"
        case .feelingsEmotions:     return "Express how you feel"
        case .locations:            return "Places, directions, and where to go"
        case .commonDescriptors:    return "Describe size, color, and more"
        case .commonObjects:        return "Everyday items around you"
        }
   }
}

#Preview {
   SearchView()
}
