//
//  SigningPracticeView.swift
//  Talking Fingers
//

#if os(iOS)
import SwiftUI
import AVFoundation
import Vision

struct SigningPracticeView: View {
    @State private var cameraVM: CameraVM = CameraVM()
    @State private var hands: [VNHumanHandPoseObservation] = []
    @State private var bodies: [VNHumanBodyPoseObservation] = []

    // Only show skeleton overlays, nothing else
    private let handConnections: [(VNHumanHandPoseObservation.JointName, VNHumanHandPoseObservation.JointName)] = [
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

    private let bodyConnections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
        (.leftShoulder, .leftElbow),
        (.rightShoulder, .rightElbow)
    ]

    var body: some View {
        ZStack {
            CameraPreviewView(session: cameraVM.session)
                .ignoresSafeArea()
            GeometryReader { geo in
                handSkeletonOverlay(in: geo.size)
                bodySkeletonOverlay(in: geo.size)
            }
        }
        .onAppear {
            cameraVM.checkPermission()
            cameraVM.onPoseDetected = { handObservations, _ in
                hands = handObservations
            }
            cameraVM.onBodyPoseDetected = { bodyObservations, _ in
                bodies = bodyObservations
            }
            cameraVM.start()
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
                       p1.confidence > 0.5, p2.confidence > 0.5 {
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
                       p1.confidence > 0.3, p2.confidence > 0.3 {
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
            .stroke(Color.orange.opacity(0.7), lineWidth: 4)
        }
    }
}
#endif

#if os(macOS)
struct SigningPracticeView: View {
    var body: some View {
        Text("temp macOS view placeholder")
    }
}
#endif
