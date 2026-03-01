//
//  AnswerDropDelegateComponent.swift
//  Talking Fingers
//
//  Created by Na Hua on 2/27/26.
//
import SwiftUI
import UniformTypeIdentifiers

struct AnswerDropDelegateComponent: DropDelegate {
    @ObservedObject var vm: SentenceBuilderVM
    let targetIndex: Int

    func validateDrop(info: DropInfo) -> Bool {
        info.hasItemsConforming(to: [UTType.text])
    }

    func dropEntered(info: DropInfo) {
        guard let draggingID = vm.draggingTokenID else { return }
        vm.insertOrMoveInAnswer(tokenID: draggingID, to: targetIndex)
    }

    func performDrop(info: DropInfo) -> Bool {
        vm.draggingTokenID = nil
        return true
    }
}
