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

    /// Resolves bundled GIFs the same way as flashcards / comprehension: `Term` raw values are
    /// uppercase gloss tokens (e.g. `HELLO`, `0`). Callers often pass `Term.rawValue` directly.
    private var gifFileName: String? {
        Term.from(word)?.defaultGifFileName
    }

    var body: some View {
        #if os(macOS)
        macOSBody
        #else
        iOSBody
        #endif
    }

    // MARK: macOS layout — title + side-by-side equal panels + Got it button
    #if os(macOS)
    private var macOSBody: some View {
        VStack(spacing: 0) {
            // Title row
            ZStack {
                Text(word.uppercased())
                    .font(.jakarta(size: 28, weight: .bold))
                    .foregroundColor(.black)

                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.jakarta(size: 22))
                            .foregroundColor(Color.gray.opacity(0.5))
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)

            // Side-by-side panels — both fill available height equally
            HStack(spacing: 16) {
                macOSGifSection
                macOSCameraSection
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Button(action: onDismiss) {
                Text("Got it")
                    .font(.jakarta(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(greenButton)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .onAppear {
            hintCameraVM.isMirrored = true
            hintCameraVM.checkPermission()
            hintCameraVM.start()
        }
        .onDisappear {
            hintCameraVM.stop()
        }
    }

    /// GIF reference panel — fills available height (no fixed 200pt constraint).
    private var macOSGifSection: some View {
        Group {
            if let gifFileName {
                GIFView(gifFileName: gifFileName)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(hex: "#FAFAFA"))
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "hand.raised.fingers.spread")
                        .font(.jakarta(size: 48))
                        .foregroundColor(Color(hex: "#B3B3B3"))
                    Text("Sign demonstration\nnot available")
                        .font(.jakarta(size: 15, weight: .medium))
                        .foregroundColor(Color(hex: "#767676"))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(hex: "#F5F5F5"))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: "#E8E8E8"), lineWidth: 1)
        )
    }

    /// Live camera mirror panel — fills available height.
    private var macOSCameraSection: some View {
        Group {
            if hintCameraVM.isAuthorized {
                CameraPreviewView(session: hintCameraVM.session, isMirrored: hintCameraVM.isMirrored)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                        .font(.jakarta(size: 36))
                        .foregroundColor(Color(hex: "#B3B3B3"))
                    Text("Camera not available")
                        .font(.jakarta(size: 15, weight: .medium))
                        .foregroundColor(Color(hex: "#767676"))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(hex: "#F5F5F5"))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: "#E8E8E8"), lineWidth: 1)
        )
    }
    #endif

    // MARK: iOS layout — stacked GIF then camera
    private var iOSBody: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 16)

            Text(word.uppercased())
                .font(.jakarta(size: 28, weight: .bold))
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
                    .font(.jakarta(size: 17, weight: .semibold))
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
                .font(.jakarta(size: 48))
                .foregroundColor(Color(hex: "#B3B3B3"))
            Text("Sign demonstration\nnot available")
                .font(.jakarta(size: 15, weight: .medium))
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
                        .font(.jakarta(size: 36))
                        .foregroundColor(Color(hex: "#B3B3B3"))
                    Text("Camera not available")
                        .font(.jakarta(size: 15, weight: .medium))
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
