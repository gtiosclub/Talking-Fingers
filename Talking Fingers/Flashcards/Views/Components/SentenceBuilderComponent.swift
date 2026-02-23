//
//  SentenceBuilderComponent.swift
//  Talking Fingers
//
//  Created by Na Hua on 2/19/26.
//
import SwiftUI

struct SentenceBuilderView: View {

    @StateObject var vm: SentenceBuilderVM
    @State private var isEditingAnswer = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            Text(vm.exercise.prompt)
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Your answer")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button(isEditingAnswer ? "Done" : "Reorder") {
                        withAnimation { isEditingAnswer.toggle() }
                    }
                    .font(.subheadline.weight(.semibold))
                }

                List {
                    ForEach(vm.answer, id: \.self) { word in
                        WordChipView(text: word)
                            .contentShape(Rectangle())
                            .onTapGesture { vm.removeWord(word) }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                    }
                    .onMove(perform: vm.moveAnswer)
                }
                .listStyle(.plain)
                .frame(height: max(60, CGFloat(vm.answer.count) * 44)) // keeps it compact-ish
                .environment(\.editMode, .constant(isEditingAnswer ? .active : .inactive))
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Word bank")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                let cols = [GridItem(.adaptive(minimum: 70), spacing: 8)]
                LazyVGrid(columns: cols, alignment: .leading, spacing: 8) {
                    ForEach(vm.bank, id: \.self) { word in
                        WordChipView(text: word)
                            .onTapGesture { vm.addWord(word) }
                    }
                }
            }

            HStack {
                Button("Reset") { vm.reset() }
                    .buttonStyle(.bordered)

                Spacer()

                Button("Check") { /* hook to whatever you do */ }
                    .buttonStyle(.borderedProminent)
                    .disabled(!vm.isComplete)
            }

            if vm.isComplete {
                Text(vm.isCorrect ? "Correct ✅" : "Try again ❌")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(vm.isCorrect ? .green : .red)
            }
        }
        .padding()
    }
}

#Preview {
    let ex = SentenceExerciseModel(
        prompt: "Arrange the sentence",
        correctOrder: ["today", "was", "amazing"],
        wordBank: ["today", "was", "amazing", "thank", "you"]
    )
    return SentenceBuilderView(vm: SentenceBuilderVM(exercise: ex))
}
