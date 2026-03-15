//
//  LearnModeView.swift
//  Talking Fingers
//
//  Created by Sanvi Adusumilli on 3/8/26.
//

import SwiftUI

struct LearnModeView: View {
    @StateObject var vm: LearnModeVM
    var progress: Double

    var body: some View {
        VStack(spacing: 20) {

            header

            Text(vm.word)
                .font(.system(size: 45, weight: .bold))

            imageArea
                .frame(maxHeight: .infinity)

            Spacer()

            mainButton
        }
        .padding(.top)
        .padding(.horizontal)
    }
}

extension LearnModeView {
    var header: some View {
        HStack {
            Button {
                // exit view
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.gray)
            }

            ProgressView(value: progress)
                .progressViewStyle(.linear)

            Spacer()
        }
        .padding(.horizontal)
    }

    var imageArea: some View {
        ZStack(alignment: .topTrailing) {

            displayedImage
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if vm.showHintButton {
                hintButton
            }
        }
        .frame(maxHeight: .infinity)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    var displayedImage: some View {
        Group {
            if vm.showingCamera {
                Image(vm.cameraImageName)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(vm.signImageName)
                    .resizable()
                    .scaledToFit()
            }
        }
        .padding(.horizontal, 20)
    }

    var hintButton: some View {
        Button {
            vm.tapHint()
        } label: {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 30))
                .foregroundColor(vm.bulbColor)
                .padding(10)
                .background(.white)
                .clipShape(Circle())
                .shadow(radius: 2)
        }
        .padding(10)
    }

    var mainButton: some View {
        Button {
            vm.tapMainButton()
        } label: {
            Text(vm.buttonText)
                .font(.system(size: 20, weight: .semibold))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(vm.buttonColor)
        .padding(.horizontal)
    }
}

#Preview {
    let dummyCard = FlashcardModel(
        term: "Hello",
        id: UUID(),
        category: "Greeting"
    )
    LearnModeView(
        vm: LearnModeVM(flashcard: dummyCard),
        progress: 0.25
    )
}
