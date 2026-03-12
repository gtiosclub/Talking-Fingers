//
//  SavedPracticeView.swift
//  Talking Fingers
//
//  Created by Aimee on 3/9/26.
//

import SwiftData
import SwiftUI

struct SavedPracticeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm = SwiftDataVM()
    @State private var showTestButton = true
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            headerSection
            contentSection
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
        .onAppear {
            vm.modelContext = modelContext
            loadSavedPractices()
        }
    }
    
    
    
    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Saved Practices")
                    .font(.largeTitle)
                    .bold()
                Spacer()
                if showTestButton {
                    Button(action: addTestData) {
                        Text("test data")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .cornerRadius(6)
                    }
                }
            }
            
            Text("Your practice history")
                .font(.title2)
                .foregroundColor(.secondary)
                .fontWeight(.semibold)
        }
    }
    
    private func addTestData() {
        let practices: [(sentences: [AISentenceModel], categories: [String])] = [
            (
                sentences: [
                    AISentenceModel(sentence: "Hello, how are you?", score: 85, practiceType: .signs, gloss: ["HELLO", "HOW", "YOU"], completed: true),
                    AISentenceModel(sentence: "Thank you very much", score: 90, practiceType: .words, gloss: ["THANK", "YOU"], completed: true),
                    AISentenceModel(sentence: "Good morning", score: 75, practiceType: .signs, gloss: ["GOOD", "MORNING"], completed: true)
                ],
                categories: ["Greetings", "Daily"]
            ),
            (
                sentences: [
                    AISentenceModel(sentence: "I love learning sign language", score: 95, practiceType: .signs, gloss: ["I", "LOVE", "LEARNING"], completed: true),
                    AISentenceModel(sentence: "Nice to meet you", score: 80, practiceType: .words, gloss: ["NICE", "MEET", "YOU"], completed: true)
                ],
                categories: ["Introduction"]
            ),
            (
                sentences: [
                    AISentenceModel(sentence: "What time is it?", score: 70, practiceType: .signs, gloss: ["WHAT", "TIME", "IT"], completed: true),
                    AISentenceModel(sentence: "I need help please", score: 88, practiceType: .words, gloss: ["I", "NEED", "HELP"], completed: true),
                    AISentenceModel(sentence: "Where is the bathroom?", score: 65, practiceType: .signs, gloss: ["WHERE", "BATHROOM"], completed: true),
                    AISentenceModel(sentence: "My name is John", score: 92, practiceType: .words, gloss: ["MY", "NAME", "JOHN"], completed: true)
                ],
                categories: ["Questions", "Basic"]
            ),
            (
                sentences: [
                    AISentenceModel(sentence: "I am happy today", score: 78, practiceType: .signs, gloss: ["I", "HAPPY", "TODAY"], completed: true),
                    AISentenceModel(sentence: "See you tomorrow", score: 85, practiceType: .words, gloss: ["SEE", "YOU", "TOMORROW"], completed: true)
                ],
                categories: ["Daily", "Farewell"]
            ),
            (
                sentences: [
                    AISentenceModel(sentence: "The weather is nice", score: 91, practiceType: .signs, gloss: ["WEATHER", "NICE"], completed: true),
                    AISentenceModel(sentence: "I like coffee", score: 87, practiceType: .words, gloss: ["I", "LIKE", "COFFEE"], completed: true),
                    AISentenceModel(sentence: "Have a great day", score: 93, practiceType: .signs, gloss: ["HAVE", "GREAT", "DAY"], completed: true)
                ],
                categories: ["Casual", "Greetings"]
            )
        ]
        
        for practice in practices {
            vm.savePracticeSession(sentences: practice.sentences, categories: practice.categories)
        }
        
        showTestButton = false
        loadSavedPractices()
    }
    

    @ViewBuilder
    private var contentSection: some View {
        if isLoading {
            loadingView
        } else if vm.savedPractices.isEmpty {
            emptyView
        } else {
            populatedView
        }
    }
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading practices...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    
    @ViewBuilder
    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "bookmark.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No Saved Practices")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Complete a practice session to see it here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    @ViewBuilder
    private var populatedView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(vm.savedPractices, id: \.id) { practice in
                    SavedPracticeCard(practice: practice)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func loadSavedPractices() {
        vm.savedPractices = vm.fetchSavedPracticeSessions()
        isLoading = false
    }
}

struct SavedPracticeCard: View {
    let practice: SavedPracticeModel
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(practice.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if !practice.categories.isEmpty {
                        Text(practice.categories.joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text("\(practice.sentences.count) sentences")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if !practice.sentences.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(practice.sentences.prefix(3)) { sentence in
                        HStack {
                            Text(sentence.sentence)
                                .font(.subheadline)
                                .lineLimit(1)
                            Spacer()
                            if let score = sentence.score {
                                ScoreBadge(score: score)
                            }
                        }
                    }
                    
                    if practice.sentences.count > 3 {
                        Text("+ \(practice.sentences.count - 3) more")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.clear)
                .background(
                    .ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(.quaternary, lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(isHovering ? 0.08 : 0.06), radius: isHovering ? 6 : 4, x: 0, y: isHovering ? 3 : 2)
        .scaleEffect(isHovering ? 1.01 : 1)
        .animation(.easeInOut(duration: 0.15), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

struct ScoreBadge: View {
    let score: Int
    
    var body: some View {
        Text("\(score)%")
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(6)
    }
    
    private var backgroundColor: Color {
        switch score {
        case 80...100:
            return Color.green.opacity(0.2)
        case 50..<80:
            return Color.orange.opacity(0.2)
        default:
            return Color.red.opacity(0.2)
        }
    }
    
    private var foregroundColor: Color {
        switch score {
        case 80...100:
            return .green
        case 50..<80:
            return .orange
        default:
            return .red
        }
    }
}

#Preview {
    SavedPracticeView()
        .modelContainer(for: SavedPracticeModel.self, inMemory: true)
}
