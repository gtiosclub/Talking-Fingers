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
                    Text(vm.word)
                        .font(.system(size: 45, weight: .bold))
                        .padding(.top, 10)

                    imageArea
                        .frame(maxHeight: .infinity)

                    Spacer()

                    mainButton
                        .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
            }
        }
        .popupHost(isPresented: $showHintPopup) {
            HintPopUpComponent(
                hintText: "This sign resembles a B shape"
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
        VStack(spacing: 12) {
            HStack {
                Button {
                    onClose()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 16, weight: .medium))
                        Text("Leave")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.gray)
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            
            HStack(spacing: 12) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(red: 0.88, green: 0.92, blue: 0.96))

                        Capsule()
                            .fill(Color(red: 0.30, green: 0.55, blue: 0.85))
                            .frame(width: geo.size.width * CGFloat(progress))
                    }
                }
                .frame(height: 10)

                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 10)
    }

    var imageArea: some View {
        ZStack(alignment: .topTrailing) {
            displayedImage
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if vm.showingCamera {
                hintButton
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
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
            showHintPopup = true
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
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(vm.buttonColor)
                )
        }
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
