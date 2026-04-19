//
//  GradedSigningCameraView.swift
//  Talking Fingers
//
//  Created by Akshaj Nadimpalli on 4/13/26.
//


import SwiftUI

struct GradedSigningCameraView: View {
    let targetWord: String
    /// Called whenever the live confidence score changes. Use this to detect a passing threshold.
    var onConfidenceChange: ((Double) -> Void)? = nil

    @State private var cameraVM = CameraVM()

    var body: some View {
        ZStack {
            // Camera Feed
            CameraPreviewView(
                session: cameraVM.session
            )
            .scaleEffect(x: cameraVM.isMirrored ? -1 : 1, y: 1)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Confidence Overlay
            VStack {
                HStack {
                    Spacer()

                    Text("\(Int(cameraVM.confidenceScore))%")
                        .font(.system(size: 18, weight: .bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(10)
                }

                Spacer()
            }
        }
        .onAppear {
            cameraVM.isMirrored = true
            cameraVM.checkPermission()
            cameraVM.start()

            startComparing()
        }
        .onChange(of: targetWord) { _, _ in
            startComparing()
        }
        .onChange(of: cameraVM.confidenceScore) { _, newValue in
            onConfidenceChange?(newValue)
        }
        .onDisappear {
            cameraVM.stop()
        }
    }

    private func startComparing() {
        let normalized = targetWord.lowercased()
        cameraVM.startComparing(forSign: normalized)
    }
}
