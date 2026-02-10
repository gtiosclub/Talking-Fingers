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
    @State private var hands: [VNHumanHandPoseObservation] = []
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

    @State private var dotsVisibility: Bool = true
    @State private var handOutlineVisibility: Bool = true
    @State private var handSkeletonVisibility: Bool = true

    // NEW: normalized landmarks (scale invariant) for use in recognition/features
    @State private var normalizedHands: [CameraVM.NormalizedHand] = []

    // Debug: show the normalized unit-box overlay
    @State private var showNormalizedDebugBox: Bool = true

    // Store all joint connections for drawing lines
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

    // Joints used for normalization (union of everything we draw / care about)
    private var jointsForNormalization: [VNHumanHandPoseObservation.JointName] {
        var set = Set<VNHumanHandPoseObservation.JointName>()

        // all label joints
        for j in JointsSheetView.jointLabels.map(\.name) { set.insert(j) }

        // all perimeter joints
        for j in perimeterJoints { set.insert(j) }

        // all skeleton connection endpoints
        for (a, b) in handConnections { set.insert(a); set.insert(b) }

        return Array(set)
    }

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
                handOutlineOverlay(in: geo.size)
                jointLabelsOverlay(in: geo.size)
                skeletonOverlay(in: geo.size)
            }

            // OPTION 2 DEBUG VIEW: Draw the normalized hand inside a fixed unit box.
            if showNormalizedDebugBox {
                normalizedDebugBoxView
            }
        }
        .onAppear {
            cameraVM.checkPermission()
            cameraVM.start()

            cameraVM.onPoseDetected = { observations in
                hands = observations

                // Compute scale-invariant unit-box coordinates every frame.
                normalizedHands = observations.compactMap { hand in
                    cameraVM.normalizeHandToUnitBox(
                        hand: hand,
                        joints: jointsForNormalization,
                        minConfidence: 0.5,
                        centerInBox: true
                    )
                }
            }
        }
        .onDisappear {
            cameraVM.stop()
        }
        .sheet(isPresented: $showJointsSheet) {
            JointsSheetView(
                jointVisibility: $jointVisibility,
                dotsVisibility: $dotsVisibility,
                handOutlineVisibility: $handOutlineVisibility,
                handSkeletonVisibility: $handSkeletonVisibility
            )
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    showJointsSheet = true
                }) {
                    Image(systemName: "gearshape.fill")
                }
            }

            // Optional: quick toggle for debug box (doesn't break anything if you remove it later)
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    showNormalizedDebugBox.toggle()
                }) {
                    Image(systemName: showNormalizedDebugBox ? "square.grid.2x2.fill" : "square.grid.2x2")
                }
            }
        }
    }

    // MARK: - Debug normalized unit box rendering

    /// Maps a unit-box point (0..1, 0..1) into a rectangle in SwiftUI coordinates.
    /// Note: SwiftUI y increases downward, so we flip y.
    private func mapUnit(_ p: CGPoint, into rect: CGRect) -> CGPoint {
        CGPoint(
            x: rect.minX + p.x * rect.width,
            y: rect.minY + (1 - p.y) * rect.height
        )
    }

    private var normalizedDebugBoxView: some View {
        // Show first normalized hand for debugging (you can extend to both later)
        Group {
            if let nh = normalizedHands.first {
                let boxSize: CGFloat = 170
                let rect = CGRect(x: 16, y: 90, width: boxSize, height: boxSize)

                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.black.opacity(0.25))

                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.white.opacity(0.9), lineWidth: 2)

                    // Title + raw bbox info (helps you confirm scale invariance)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Normalized (unit box)")
                            .font(.caption)
                            .foregroundStyle(.white)

                        Text(String(format: "raw w=%.3f h=%.3f", nh.rawBounds.width, nh.rawBounds.height))
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                    // Draw a few key points (wrist + fingertips)
                    ForEach(
                        [
                            VNHumanHandPoseObservation.JointName.wrist,
                            .thumbTip, .indexTip, .middleTip, .ringTip, .littleTip
                        ],
                        id: \.self
                    ) { j in
                        if let p = nh.unitPoints[j] {
                            Circle()
                                .fill(.white)
                                .frame(width: 7, height: 7)
                                .position(mapUnit(p, into: rect))
                        }
                    }

                    // Optional: draw a simple skeleton in the unit box (using same connections)
                    Path { path in
                        for (a, b) in handConnections {
                            if let p1 = nh.unitPoints[a], let p2 = nh.unitPoints[b] {
                                let s = mapUnit(p1, into: rect)
                                let e = mapUnit(p2, into: rect)
                                path.move(to: s)
                                path.addLine(to: e)
                            }
                        }
                    }
                    .stroke(.white.opacity(0.55), lineWidth: 2)
                }
                .frame(width: boxSize, height: boxSize)
                .position(x: rect.midX, y: rect.midY)
                .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Existing overlays

    @ViewBuilder
    private func handOutlineOverlay(in size: CGSize) -> some View {
        if handOutlineVisibility {
            ForEach(hands, id: \.uuid) { hand in
                let points = perimeterJoints.compactMap { jointName -> CGPoint? in
                    guard let point = try? hand.recognizedPoint(jointName),
                          point.confidence > 0.5 else { return nil }
                    return cameraVM.convertVisionPointToScreenPosition(visionPoint: point.location, viewSize: size)
                }

                if points.count > 3 {
                    Path { path in
                        path.addLines(points)
                        path.closeSubpath()
                    }
                    .fill(Color.green.opacity(0.3))
                    .stroke(Color.green, lineWidth: 2)
                }
            }
        }
    }

    @ViewBuilder
    private func jointLabelsOverlay(in size: CGSize) -> some View {
        ForEach(hands, id: \.uuid) { hand in
            let visibleJoints = JointsSheetView.jointLabels.filter { jointVisibility[$0.name] == true }

            ForEach(visibleJoints, id: \.name) { joint in
                if let point = try? hand.recognizedPoint(joint.name), point.confidence > 0.5 {
                    let pos = cameraVM.convertVisionPointToScreenPosition(visionPoint: point.location, viewSize: size)
                    // Adjust label based on chirality and camera mirror
                    let handSide = (cameraVM.isMirrored ? (hand.chirality == .left ? "R" : "L") : (hand.chirality == .left ? "L" : "R"))

                    ZStack {
                        Text("\(handSide) \(joint.label)")
                            .font(.caption2)
                            .padding(4)
                            .background(.ultraThinMaterial, in: Capsule())
                            .position(pos)

                        if dotsVisibility {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 7, height: 7)
                                .position(pos)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func skeletonOverlay(in size: CGSize) -> some View {
        if handSkeletonVisibility {
            ForEach(hands, id: \.uuid) { hand in
                // Adjust color based on chirality and camera mirror
                let handSkeletonColor = (cameraVM.isMirrored ? (hand.chirality == .left ? Color.purple : Color.blue) : (hand.chirality == .left ? Color.blue : Color.purple))
                Path { path in
                    for connection in handConnections {
                        // Draw if both points are visible
                        if let p1 = try? hand.recognizedPoint(connection.0),
                           let p2 = try? hand.recognizedPoint(connection.1),
                           p1.confidence > 0.5, p2.confidence > 0.5,
                           jointVisibility[connection.0] == true, jointVisibility[connection.1] == true {

                            let start = cameraVM.convertVisionPointToScreenPosition(visionPoint: p1.location, viewSize: size)
                            let end = cameraVM.convertVisionPointToScreenPosition(visionPoint: p2.location, viewSize: size)

                            path.move(to: start)
                            path.addLine(to: end)
                        }
                    }
                }
                .stroke(handSkeletonColor.opacity(0.6), lineWidth: 3)
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
