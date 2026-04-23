//
//  LearnModeView.swift
//  Talking Fingers
//
//  Created by Sanvi Adusumilli on 3/8/26.
//

import SwiftUI

struct LearnModeView: View {
    @ObservedObject var vm: LearnModeVM
    var progress: Double
    var onClose: () -> Void = {}
    
    @State private var showHintPopup: Bool = false

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                VStack(spacing: 20) {
                    if !vm.showingCamera {
                        Text(vm.word)
                            .font(.jakarta(size: 45, weight: .bold))
                            .padding(.top, 10)

                        gifCard
                            .frame(maxHeight: .infinity)
                    } else {
                        SigningCameraCard(
                            word: vm.word,
                            showSaveButton: false,
                            showStuckButton: false,
                            showWordTitle: true,
                            isHintActive: showHintPopup,
                            onConfidenceChange: { vm.updateConfidence($0) },
                            onHintTap: {
                                vm.tapHint()
                                showHintPopup = true
                            }
                        )
                        .padding(.top, 16)
                        .frame(maxHeight: .infinity)
                    }

                    Spacer()

                    mainButton
                        .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
            }
        }
        .popupHost(isPresented: $showHintPopup) {
            HintPopUpComponent(
                hintText: "This sign resembles a B shape",
                gifFileName: vm.flashcard.gifFileName ?? vm.flashcard.term.defaultGifFileName
            ) {
                showHintPopup = false
                if vm.state == .showingHint {
                    vm.tapHint()
                }
            }
        }
    }
}

extension LearnModeView {
    private var topBar: some View {
        SessionTopBar(progress: progress, onLeave: onClose)
    }

    var gifCard: some View {
        Group {
            if let gifFileName = vm.flashcard.gifFileName ?? vm.flashcard.term.defaultGifFileName {
                GIFView(gifFileName: gifFileName)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text("No reference GIF available")
                    .foregroundStyle(.secondary)
            }
        }
        // On iOS the GIF is natural-sized and centred, so keep inner padding.
        // On Mac the GIF fills the card edge-to-edge, so no inner padding.
        .iosOnly(horizontalPadding: 20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }

    var mainButton: some View {
        Button {
            vm.tapMainButton()
        } label: {
            Text(vm.buttonText)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(vm.buttonColor)
                )
        }
        .disabled(!vm.canAdvanceToNextWord)
        .opacity(vm.canAdvanceToNextWord ? 1.0 : 0.6)
        .buttonStyle(.plain)
    }
}

#Preview {
    let dummyCard = FlashcardModel(
        term: .hello,
        id: UUID(),
        category: .greetings
    )
    LearnModeView(
        vm: LearnModeVM(flashcard: dummyCard),
        progress: 0.25
    )
}
