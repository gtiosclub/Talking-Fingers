//
//  SentenceBuilderVM.swift
//  Talking Fingers
//
//  Created by Na Hua on 2/19/26.
//
import Foundation
import Combine

@MainActor
final class SentenceBuilderVM: ObservableObject {
    
    enum SubmitState: Equatable {
        case idle
        case correct
        case incorrect(solution: String)
    }
    
    let exercise: SentenceExerciseModel
    
    @Published private(set) var bank: [WordTokenModel]
    @Published private(set) var answer: [WordTokenModel]
    @Published private(set) var submitState: SubmitState = .idle
    @Published var draggingTokenID: UUID?

    init(exercise: SentenceExerciseModel) {
        self.exercise = exercise
        self.bank = exercise.wordBankTokenModels
        self.answer = []
    }

    func addWord(_ token: WordTokenModel) {
        guard let idx = bank.firstIndex(where: { $0.id == token.id }) else { return }
        bank.remove(at: idx)
        answer.append(token)
        submitState = .idle
    }

    func removeWord(_ token: WordTokenModel) {
        guard let idx = answer.firstIndex(where: { $0.id == token.id }) else { return }
        answer.remove(at: idx)
        bank.append(token)
        submitState = .idle
    }

    func moveAnswer(from source: IndexSet, to destination: Int) {
        let moving = source.map { answer[$0] }

        for i in source.sorted(by: >) {
            answer.remove(at: i)
        }

        let removedBefore = source.filter { $0 < destination }.count
        let adjustedDest = max(0, min(answer.count, destination - removedBefore))

        answer.insert(contentsOf: moving, at: adjustedDest)
        submitState = .idle
    }

    func reset() {
        bank = exercise.wordBankTokenModels
        answer = []
        submitState = .idle
    }

    var isComplete: Bool {
        answer.count == exercise.correctOrder.count
    }

    var isCorrect: Bool {
        answer.map(\.text) == exercise.correctOrder
    }
    
    func submit() {
        guard isComplete else { return }

        if isCorrect {
            submitState = .correct
        } else {
            let solution = exercise.correctOrder.joined(separator: " ")
            submitState = .incorrect(solution: solution)
        }
    }
    
    func tryAgain() {
        submitState = .idle
    }
    
    func insertOrMoveInAnswer(tokenID: UUID, to index: Int) {
        if let from = answer.firstIndex(where: { $0.id == tokenID }) {
            let safeTo = max(0, min(index, answer.count - 1))
            guard from != safeTo else { return }
            let item = answer.remove(at: from)
            answer.insert(item, at: safeTo)
            submitState = .idle
            return
        }

        guard answer.count < exercise.correctOrder.count else { return }
        if let token = bank.first(where: { $0.id == tokenID }) {
            bank.removeAll { $0.id == tokenID }
            let safeTo = max(0, min(index, answer.count))
            answer.insert(token, at: safeTo)
            submitState = .idle
        }
    }
}
