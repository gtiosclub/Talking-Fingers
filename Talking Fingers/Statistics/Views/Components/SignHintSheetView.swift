//
//  SignHintSheetView.swift
//  Talking Fingers
//
//  Sheet that shows a hint for how to sign a word, with a GIF demonstration
//  at the top and a live camera mirror at the bottom for the user to practice.
//

import SwiftUI

struct SignHintSheetView: View {
    let word: String
    var onDismiss: () -> Void

    @State private var hintCameraVM = CameraVM()

    private let greenButton = Color(hex: "#97C171")

    private var gifFileName: String? {
        if let term = Term(rawValue: word.lowercased()) {
            return term.defaultGifFileName
        }
        let capitalizedWord = word.prefix(1).uppercased() + word.dropFirst().lowercased()
        if let term = Term(rawValue: capitalizedWord) {
            return term.defaultGifFileName
        }
        return nil
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 16)

            Text(word.uppercased())
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.black)
                .padding(.bottom, 16)

            gifSection
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

            mirrorCameraSection
                .padding(.horizontal, 24)

            Spacer(minLength: 16)

            Button(action: onDismiss) {
                Text("Got it")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(greenButton)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 34)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .onAppear {
            #if os(macOS)
            hintCameraVM.isMirrored = true
            #endif
            hintCameraVM.checkPermission()
            hintCameraVM.start()
        }
        .onDisappear {
            hintCameraVM.stop()
        }
    }

    @ViewBuilder
    private var gifSection: some View {
        if let gifFileName {
            GIFView(gifFileName: gifFileName)
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(Color(hex: "#FAFAFA"))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(hex: "#E8E8E8"), lineWidth: 1)
                )
        } else {
            placeholderGifView
        }
    }

    private var placeholderGifView: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.raised.fingers.spread")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "#B3B3B3"))
            Text("Sign demonstration\nnot available")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(hex: "#767676"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(Color(hex: "#F5F5F5"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private var mirrorCameraSection: some View {
        Group {
            if hintCameraVM.isAuthorized {
                #if os(iOS)
                CameraPreviewView(session: hintCameraVM.session)
                #elseif os(macOS)
                CameraPreviewView(session: hintCameraVM.session, isMirrored: hintCameraVM.isMirrored)
                #endif
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 36))
                        .foregroundColor(Color(hex: "#B3B3B3"))
                    Text("Camera not available")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(hex: "#767676"))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(hex: "#F5F5F5"))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: "#E8E8E8"), lineWidth: 1)
        )
    }
}

#Preview {
    SignHintSheetView(word: "hello") {}
}
