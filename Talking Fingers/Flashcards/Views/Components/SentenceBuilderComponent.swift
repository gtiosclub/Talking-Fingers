//
//  SentenceBuilderComponent.swift
//  Talking Fingers
//
//  Created by Na Hua on 2/19/26.
//
import SwiftUI
import UniformTypeIdentifiers

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
                }
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.systemGray6))
                        .frame(minHeight: 90)
                    
                    if vm.answer.isEmpty {
                        Text("Tap or drag words below to build your sentence (\(vm.exercise.correctOrder.count) words)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                    } else {
                        FlowLayoutComponent(spacing: 8, rowSpacing: 8) {
                            ForEach(Array(vm.answer.enumerated()), id: \.element.id) { idx, token in
                                WordChipView(text: token.text)
                                    .onTapGesture { vm.removeWord(token) }
                                    .onDrag {
                                        vm.draggingTokenID = token.id
                                        return NSItemProvider(object: token.id.uuidString as NSString)
                                    }
                                    .onDrop(of: [UTType.text], delegate: AnswerDropDelegateComponent(vm: vm, targetIndex: idx))
                            }
                        }
                        .padding(12)
                    }
                }
                .onDrop(of: [UTType.text], isTargeted: nil) { providers in
                    handleDrop(providers, insertIndex: vm.answer.count)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Word bank")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                let cols = [GridItem(.adaptive(minimum: 70), spacing: 8)]
                LazyVGrid(columns: cols, alignment: .leading, spacing: 8) {
                    ForEach(vm.bank) { token in
                        WordChipView(text: token.text)
                            .onTapGesture { vm.addWord(token) }
                            .onDrag {
                                vm.draggingTokenID = token.id
                                return NSItemProvider(object: token.id.uuidString as NSString)
                            }
                    }
                }
                .padding(12)
            }
            .contentShape(Rectangle())
            .onDrop(of: [UTType.text], isTargeted: nil) { providers in
                handleBankDrop(providers)
            }
            
            Spacer(minLength: 8)
            Button("Submit") { vm.submit() }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(!vm.isComplete)
            
            switch vm.submitState {
            case .idle:
                EmptyView()
                
            case .correct:
                VStack(alignment: .leading, spacing: 10) {
                    Text("CORRECT")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.green)
                    
                    HStack {
                        Button("take a break") {
                            // hook later (navigate away)
                            vm.reset()
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                        
                        Button("continue") {
                            // hook later (advance exercise)
                            vm.reset()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            case .incorrect(let solution):
                VStack(alignment: .leading, spacing: 10) {
                    Text("INCORRECT")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.red)
                    
                    Text("SOLUTION: \(solution)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Button("end attempt") {
                            vm.reset()
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                        
                        Button("try again") {
                            vm.tryAgain()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .padding()
    }
    private func handleDrop(_ providers: [NSItemProvider], insertIndex: Int) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, _ in
            let str: String?
            if let data = item as? Data {
                str = String(data: data, encoding: .utf8)
            } else {
                str = item as? String
            }
            
            guard let uuidStr = str, let id = UUID(uuidString: uuidStr) else { return }
            
            DispatchQueue.main.async {
                vm.insertOrMoveInAnswer(tokenID: id, to: insertIndex)
            }
        }
        
        return true
    }
    
    private func handleBankDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, _ in
            let str: String?
            if let data = item as? Data {
                str = String(data: data, encoding: .utf8)
            } else {
                str = item as? String
            }

            guard let uuidStr = str, let id = UUID(uuidString: uuidStr) else { return }

            DispatchQueue.main.async {
                vm.moveToBank(tokenID: id)
                vm.draggingTokenID = nil
            }
        }

        return true
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
