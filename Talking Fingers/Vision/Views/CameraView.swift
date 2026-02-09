//
//  CameraView.swift
//  Talking Fingers
//
//  Created by Jihoon Kim on 1/29/26.
//


import SwiftUI
import AVFoundation
import Vision

struct CameraView: View {
    
    @State private var cameraVM: CameraVM = CameraVM()
    @State private var hand: VNHumanHandPoseObservation?
    @State private var hand2: VNHumanHandPoseObservation?
    
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
                
                if let thumbTip = try? hand?.recognizedPoint(.thumbTip),
                   thumbTip.confidence > 0.9 {
                    
                    let pos = cameraVM.convertVisionPointToScreenPosition(visionPoint: thumbTip.location, viewSize: geo.size)
                    Text("Thumb Tip")
                        .position(pos)
                }
                if let thumbTip = try? hand2?.recognizedPoint(.thumbTip),
                   thumbTip.confidence > 0.9 {
                    
                    let pos = cameraVM.convertVisionPointToScreenPosition(visionPoint: thumbTip.location, viewSize: geo.size)
                    Text("Thumb Tip 2")
                        .position(pos)
                }
                if let indexTip = try? hand?.recognizedPoint(.indexTip),
                   indexTip.confidence > 0.9 {
                    
                    let pos = cameraVM.convertVisionPointToScreenPosition(visionPoint: indexTip.location, viewSize: geo.size)
                    Text("Index Tip 1")
                        .position(pos)
                }
                if let indexTip = try? hand2?.recognizedPoint(.indexTip),
                   indexTip.confidence > 0.9 {
                    
                    let pos = cameraVM.convertVisionPointToScreenPosition(visionPoint: indexTip.location, viewSize: geo.size)
                    Text("Index Tip 2")
                        .position(pos)
                }
                
            }
            
        }
        .onAppear {
            cameraVM.checkPermission()
            cameraVM.start()

            cameraVM.onPoseDetected = { observations in
                hand = observations.first
                hand2 = observations.last
            }
        }
        .onDisappear {
            cameraVM.stop()
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
}
