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

    let exercise: SentenceExerciseModel
    
    @Published private(set) var bank: [String]
    @Published private(set) var answer: [String]

    init(exercise: SentenceExerciseModel) {
        self.exercise = exercise
        self.bank = exercise.wordBank
        self.answer = []
    }

    func addWord(_ word: String) {
        guard let idx = bank.firstIndex(of: word) else { return }
        bank.remove(at: idx)
        answer.append(word)
    }

    func removeWord(_ word: String) {
        guard let idx = answer.firstIndex(of: word) else { return }
        answer.remove(at: idx)
        bank.append(word)
    }

    func moveAnswer(from source: IndexSet, to destination: Int) {
        let moving = source.map { answer[$0] }

        for i in source.sorted(by: >) {
            answer.remove(at: i)
        }

        let removedBefore = source.filter { $0 < destination }.count
        let adjustedDest = max(0, min(answer.count, destination - removedBefore))

        answer.insert(contentsOf: moving, at: adjustedDest)
    }

    func reset() {
        bank = exercise.wordBank
        answer = []
    }

    var isComplete: Bool {
        answer.count == exercise.correctOrder.count
    }

    var isCorrect: Bool {
        answer == exercise.correctOrder
    }
}
