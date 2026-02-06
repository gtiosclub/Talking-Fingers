//
//  CameraView.swift
//  Talking Fingers
//
//  Created by Jihoon Kim on 1/29/26.
//
#if os(iOS)

import SwiftUI
import AVFoundation
import Vision

struct CameraView: View {

    @State private var showJointsSheet: Bool = false

    @State private var cameraVM: CameraVM = CameraVM()
    @State private var hand: VNHumanHandPoseObservation?
    @Environment(AuthenticationViewModel.self) var authVM

    /// Tracks which joints the user wants visible on the overlay.
    /// Every joint starts hidden; users toggle them on via the sheet.
    @State private var jointVisibility: [VNHumanHandPoseObservation.JointName: Bool] = {
        var dict: [VNHumanHandPoseObservation.JointName: Bool] = [:]
        for joint in JointsSheetView.jointLabels {
            dict[joint.name] = false
        }
        return dict
    }()

    var body: some View {
        ZStack {
            if cameraVM.isAuthorized {
                CameraPreviewView(session: cameraVM.session)
                    .ignoresSafeArea()
            } else {
                ContentUnavailableView(
                    "Camera Access Required",
                    systemImage: "camera.fill",
                    description: Text("Please allow camera access in Settings to use sign language recognition.")
                )
            }

            GeometryReader { geo in
                ForEach(JointsSheetView.jointLabels.filter { jointVisibility[$0.name] == true },
                        id: \.name) { joint in
                    if let point = try? hand?.recognizedPoint(joint.name),
                       point.confidence > 0.5 {
                        let pos = cameraVM.convertVisionPointToScreenPosition(
                            visionPoint: point.location, viewSize: geo.size)
                        Text(joint.label)
                            .font(.caption2)
                            .padding(4)
                            .background(.ultraThinMaterial, in: Capsule())
                            .position(pos)
                    }
                }
            }
        }
        .onAppear {
            cameraVM.checkPermission()
            cameraVM.start()

            cameraVM.onPoseDetected = { observations in
                hand = observations.first
            }
        }
        .onDisappear {
            cameraVM.stop()
        }
        .sheet(isPresented: $showJointsSheet) {
            JointsSheetView(jointVisibility: $jointVisibility)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    showJointsSheet = true
                }) {
                    Image(systemName: "gearshape.fill")
                }
            }
        }
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    class VideoPreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }

    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: VideoPreviewView, context: Context) {}
}

#Preview {
    CameraView()
        .environment(AuthenticationViewModel())
}

#endif
