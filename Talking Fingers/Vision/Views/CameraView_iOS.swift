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

    //
    var onRecordingFinished: (([SignFrame]) -> Void)?

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

    // Scale invariance (does NOT change on-screen overlay; used for debug/features)
    @State private var normalizedHands: [CameraVM.NormalizedHand] = []
    @State private var showScaleDebugBox: Bool = false

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

    // Joints used for normalization (union of everything we draw/care about)
    private var jointsForNormalization: [VNHumanHandPoseObservation.JointName] {
        var set = Set<VNHumanHandPoseObservation.JointName>()

        // all label joints
        for j in JointsSheetView.jointLabels.map(\.name) { set.insert(j) }

        // perimeter joints
        for j in perimeterJoints { set.insert(j) }

        // skeleton endpoints
        for (a, b) in handConnections { set.insert(a); set.insert(b) }

        return Array(set)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                if cameraVM.isAuthorized {
                    // Camera "window" that holds the live feed + ALL overlays
                    ZStack(alignment: .topLeading) {
                        CameraPreviewView(session: cameraVM.session)
                            .ignoresSafeArea()

                        // IMPORTANT: GeometryReader is inside the window,
                        // so size is the window size (keeps overlays aligned).
                        GeometryReader { geo in
                            handOutlineOverlay(in: geo.size)
                            jointLabelsOverlay(in: geo.size)
                            skeletonOverlay(in: geo.size)
                        }

                        // Optional scale debug box (drawn inside the camera window)
                        if showScaleDebugBox {
                            scaleDebugBoxView
                                .padding(12)
                                .allowsHitTesting(false)
                        }
                    }
                    // Stable portrait camera window that still takes most of the screen.
                    .aspectRatio(9.0 / 16.0, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(radius: 12)
                    .padding(.horizontal)

                } else {
                    ContentUnavailableView(
                        "Camera Access Required",
                        systemImage: "camera.fill",
                        description: Text("Please allow camera access in Settings to use sign language recognition.")
                    )
                    .padding(.horizontal)
                    .padding(.top, 24)
                }

                // Space for future info/buttons below the camera window
                VStack(alignment: .leading, spacing: 8) {
                    // Add future UI elements here
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .padding(.top, 12)
        }
        .onAppear {
            cameraVM.checkPermission()
            cameraVM.start()

            cameraVM.onPoseDetected = { observations, pts in
                hands = observations

                // While recording, capture each observation with the provided CMTime timestamp
                if isRecording {
                    if recordingStartTime == nil { recordingStartTime = pts }
                    for obs in observations {
                        recordedPoses.append((pts, obs))
                    }
                }

                // Compute scale-invariant unit-box coordinates (does not affect overlay)
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
            // ✅ No NavigationStack/Form here.
            // This preserves the exact JointsSheetView UI (and its single Done).
            VStack(spacing: 0) {
                // Debug toggle row styled like a normal settings row
                HStack {
                    Text("Show scale debug box")
                    Spacer()
                    Toggle("", isOn: $showScaleDebugBox)
                        .labelsHidden()
                }
                .padding(.horizontal)
                .padding(.vertical, 12)

                Divider()

                // Original sheet UI unchanged
                JointsSheetView(
                    jointVisibility: $jointVisibility,
                    dotsVisibility: $dotsVisibility,
                    handOutlineVisibility: $handOutlineVisibility,
                    handSkeletonVisibility: $handSkeletonVisibility
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    toggleRecording()
                }) {
                    Image(systemName: cameraVM.isRecording ? "stop.circle.fill" : "record.circle")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.red, .primary)
                        .accessibilityLabel(cameraVM.isRecording ? "Stop Recording" : "Start Recording")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showJointsSheet = true }) {
                    Image(systemName: "gearshape.fill")
                }
            }
        }
    }

    // MARK: - Scale debug box UI

    private var scaleDebugBoxView: some View {
        Group {
            if let nh = normalizedHands.first {
                let boxSize: CGFloat = 170

                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.black.opacity(0.25))
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.white.opacity(0.9), lineWidth: 2)

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
                                .position(mapUnit(p, boxSize: boxSize))
                        }
                    }

                    Path { path in
                        for (a, b) in handConnections {
                            if let p1 = nh.unitPoints[a], let p2 = nh.unitPoints[b] {
                                let s = mapUnit(p1, boxSize: boxSize)
                                let e = mapUnit(p2, boxSize: boxSize)
                                path.move(to: s)
                                path.addLine(to: e)
                            }
                        }
                    }
                    .stroke(.white.opacity(0.55), lineWidth: 2)
                }
                .frame(width: boxSize, height: boxSize)
            }
        }
    }

    private func mapUnit(_ p: CGPoint, boxSize: CGFloat) -> CGPoint {
        CGPoint(
            x: p.x * boxSize,
            y: (1 - p.y) * boxSize
        )
    }

    // MARK: - Overlays (unchanged)

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

                    let handSide = (cameraVM.isMirrored
                                    ? (hand.chirality == .left ? "R" : "L")
                                    : (hand.chirality == .left ? "L" : "R"))

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
                let handSkeletonColor = (cameraVM.isMirrored
                                         ? (hand.chirality == .left ? Color.purple : Color.blue)
                                         : (hand.chirality == .left ? Color.blue : Color.purple))

                Path { path in
                    for connection in handConnections {
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

    // MARK: - Recording (unchanged)

    private func toggleRecording() {
        if cameraVM.isRecording {
            cameraVM.toggleRecording()
            
            let finalData = cameraVM.recordedFrames
            onRecordingFinished?(finalData)
            
            cameraVM.clearBuffer()
        } else {
            cameraVM.toggleRecording()
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
    CameraView(onRecordingFinished: { tuples in
        print("Preview received \(tuples.count) recorded tuples")
        print(tuples.prefix(3))
    })
    .environment(AuthenticationViewModel())
}

#endif

