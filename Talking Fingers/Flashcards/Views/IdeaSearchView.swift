//
//  IdeaSearchView.swift
//  Talking Fingers
//

import SwiftUI

struct IdeaSearchView: View {
    @State private var query = ""
    @State private var results: [Term] = []

    private let categoryColors: [TermCategory: Color] = [
        .greetings:          Color(red: 0.78, green: 0.85, blue: 0.93),
        .family:             Color(red: 0.96, green: 0.92, blue: 0.80),
        .verbs:              Color(red: 0.85, green: 0.93, blue: 0.85),
        .feelingsEmotions:   Color(red: 0.96, green: 0.85, blue: 0.93),
        .locations:          Color(red: 0.93, green: 0.90, blue: 0.80),
        .commonDescriptors:  Color(red: 0.80, green: 0.90, blue: 0.93),
        .commonObjects:      Color(red: 0.93, green: 0.80, blue: 0.80),
        .numbers:            Color(red: 0.90, green: 0.93, blue: 0.80),
        .personalInformation:Color(red: 0.88, green: 0.85, blue: 0.95),
        .dateTime:           Color(red: 0.95, green: 0.90, blue: 0.80),
        .alphabet:           Color(red: 0.85, green: 0.85, blue: 0.85),
    ]

    private var displayedTerms: [Term] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? Term.allCases : results
    }

    private var subtitle: String {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return "All signs"
        }
        return "\(displayedTerms.count) sign\(displayedTerms.count == 1 ? "" : "s") found"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("e.g. going to the grocery store", text: $query)
                    .autocorrectionDisabled()
                    .onChange(of: query) { _, newValue in
                        let trimmed = newValue.trimmingCharacters(in: .whitespaces)
                        results = trimmed.isEmpty ? [] : FlashcardVM.ideaSearch(query: trimmed)
                    }
                if !query.isEmpty {
                    Button {
                        query = ""
                        results = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.vertical, 12)

            if !query.trimmingCharacters(in: .whitespaces).isEmpty && results.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No matching signs found")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)

                        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(displayedTerms, id: \.self) { term in
                                TermResultCard(
                                    term: term,
                                    backgroundColor: categoryColors[term.category] ?? Color(.systemGray5)
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.categoryComponentColor)
    }
}

private struct TermResultCard: View {
    let term: Term
    let backgroundColor: Color

    private var categoryIcon: String {
        switch term.category {
        case .greetings:           return "hand.wave"
        case .family:              return "figure.2.and.child.holdinghands"
        case .verbs:               return "bolt"
        case .feelingsEmotions:    return "heart"
        case .locations:           return "mappin"
        case .commonDescriptors:   return "tag"
        case .commonObjects:       return "cube.box"
        case .numbers:             return "number"
        case .personalInformation: return "person"
        case .dateTime:            return "calendar"
        case .alphabet:            return "textformat"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                Image("dummySign")
                    .resizable()
                    .scaledToFit()
                    .padding(12)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)

            VStack(alignment: .leading, spacing: 6) {
                Text(term.displayName)
                    .font(.system(size: 17, weight: .bold))
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Image(systemName: categoryIcon)
                        .font(.system(size: 10))
                    Text(term.category.rawValue.capitalized)
                        .font(.system(size: 11))
                }
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            .padding(.top, 4)
        }
        .background(backgroundColor)
        .cornerRadius(18)
    }
}

#Preview {
    NavigationStack {
        IdeaSearchView()
    }
}
