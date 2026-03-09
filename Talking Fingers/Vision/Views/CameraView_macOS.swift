//
//  CameraView.swift
//  Talking Fingers
//
//  Created by Nikola Cao on 2/6/26.
//


//
//  CameraView.swift
//  Talking Fingers
//
//  Created by Jihoon Kim on 1/29/26.
//
#if os(macOS)

import SwiftUI
import AVFoundation
import Vision

struct CameraView: View {

    @State private var cameraVM: CameraVM = CameraVM()

    @State private var hands: [VNHumanHandPoseObservation] = []
    @State private var bodies: [VNHumanBodyPoseObservation] = []
    
//    @State private var jointVisibility: [VNHumanHandPoseObservation.JointName: Bool] = {
//        var dict: [VNHumanHandPoseObservation.JointName: Bool] = [:]
//        for joint in JointsSheetView.handJointLabels {
//            dict[joint.name] = true
//        }
//        return dict
//    }()
//    
//    @State private var bodyJointVisibility: [VNHumanBodyPoseObservation.JointName: Bool] = {
//        var dict: [VNHumanBodyPoseObservation.JointName: Bool] = [:]
//        for joint in JointsSheetView.bodyJointLabels {
//            dict[joint.name] = true
//        }
//        return dict
//    }()
    
    @State private var dotsVisibility: Bool = true
    @State private var handOutlineVisibility: Bool = true
    @State private var handSkeletonVisibility: Bool = true
    @State private var bodySkeletonVisibility: Bool = true

    @State private var signName: String = ""
    @State private var signType: SignType = .static

    @State private var countdown: Int = 0
    @State private var countdownTask: Task<Void, Never>?

    @State private var handsLastSeenDate: Date?
    @State private var handsLastSeenPTS: CMTime?
    private let autoStopGracePeriod: TimeInterval = 1.5
    
    // Store all hand joint connections for drawing lines
    let handConnections: [(VNHumanHandPoseObservation.JointName, VNHumanHandPoseObservation.JointName)] = [
        // Thumb
        (.wrist, .thumbCMC), (.thumbCMC, .thumbMP), (.thumbMP, .thumbIP), (.thumbIP, .thumbTip),
        // Index
        (.wrist, .indexMCP), (.indexMCP, .indexPIP), (.indexPIP, .indexDIP), (.indexDIP, .indexTip),
        // Middle
        (.wrist, .middleMCP), (.middleMCP, .middlePIP), (.middlePIP, .middleDIP), (.middleDIP, .middleTip),
        // Ring
        (.wrist, .ringMCP), (.ringMCP, .ringPIP), (.ringPIP, .ringDIP), (.ringDIP, .ringTip),
        // Little
        (.wrist, .littleMCP), (.littleMCP, .littlePIP), (.littlePIP, .littleDIP), (.littleDIP, .littleTip)
    ]

    // Store body joint connections for upper body (shoulders to elbows only)
    let bodyConnections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
        (.leftShoulder, .leftElbow),
        (.rightShoulder, .rightElbow)
    ]

    // Store points to create polygon for hand (edges)
    let perimeterJoints: [VNHumanHandPoseObservation.JointName] = [
        .wrist,
        .thumbCMC, .thumbMP, .thumbIP, .thumbTip,
        .indexTip,
        .middleTip,
        .ringTip,
        .littleTip,
        .littleDIP, .littlePIP, .littleMCP,
        .wrist
    ]

    var body: some View {

        ZStack {

            if cameraVM.isAuthorized {

                CameraPreviewView(session: cameraVM.session)

                GeometryReader { geo in
                    handSkeletonOverlay(in: geo.size)
                    bodySkeletonOverlay(in: geo.size)
                }

            } else {

                ContentUnavailableView(
                    "Camera Access Required",
                    systemImage: "camera.fill",
                    description: Text("Allow camera access in System Settings.")
                )
            }
        }
        .onAppear {

            cameraVM.checkPermission()
            cameraVM.start()

            cameraVM.onPoseDetected = { handObservations, pts in
                hands = handObservations

                guard cameraVM.isRecording else { return }

                if !handObservations.isEmpty {
                    handsLastSeenDate = Date()
                    handsLastSeenPTS = pts
                } else if let lastSeen = handsLastSeenDate,
                          Date().timeIntervalSince(lastSeen) >= autoStopGracePeriod {
//                    toggleRecording()
                }
            }

            cameraVM.onBodyPoseDetected = { bodyObservations, _ in
                bodies = bodyObservations
            }
        }
        .onDisappear {
            cameraVM.stop()
        }
    }


    @ViewBuilder
    private func handSkeletonOverlay(in size: CGSize) -> some View {

        ForEach(hands, id: \.uuid) { hand in
            let handSkeletonColor = (cameraVM.isMirrored
                                     ? (hand.chirality == .left ? Color.purple : Color.blue)
                                     : (hand.chirality == .left ? Color.blue : Color.purple))

            Path { path in

                for connection in handConnections {

                    if let p1 = try? hand.recognizedPoint(connection.0),
                       let p2 = try? hand.recognizedPoint(connection.1),
                       p1.confidence > 0.5,p2.confidence > 0.5 {

                        let start = cameraVM.convertVisionPointToScreenPosition(
                            visionPoint: p1.location,
                            viewSize: size
                        )

                        let end = cameraVM.convertVisionPointToScreenPosition(
                            visionPoint: p2.location,
                            viewSize: size
                        )

                        path.move(to: start)
                        path.addLine(to: end)
                    }
                }
            }
            .stroke(handSkeletonColor.opacity(0.6), lineWidth: 3)
        }
    }

    @ViewBuilder
    private func bodySkeletonOverlay(in size: CGSize) -> some View {

        ForEach(bodies, id: \.uuid) { body in

            Path { path in

                for connection in bodyConnections {

                    if let p1 = try? body.recognizedPoint(connection.0),
                       let p2 = try? body.recognizedPoint(connection.1),
                       p1.confidence > 0.3,
                       p2.confidence > 0.3 {

                        let start = cameraVM.convertVisionPointToScreenPosition(
                            visionPoint: p1.location,
                            viewSize: size
                        )

                        let end = cameraVM.convertVisionPointToScreenPosition(
                            visionPoint: p2.location,
                            viewSize: size
                        )

                        path.move(to: start)
                        path.addLine(to: end)
                    }
                }
            }
            .stroke(Color.orange, lineWidth: 4)
        }
    }
}


struct CameraPreviewView: NSViewRepresentable {
    let session: AVCaptureSession
    
    class VideoPreviewView: NSView {
        override func makeBackingLayer() -> CALayer {
            AVCaptureVideoPreviewLayer()
        }

        var previewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }
    
    func makeNSView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.wantsLayer = true
        
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        
        
        return view
    }
    
    func updateNSView(_ nsView: VideoPreviewView, context: Context) {
        nsView.previewLayer.session = session
    }
}

#Preview {
    CameraView()
}

#endif
