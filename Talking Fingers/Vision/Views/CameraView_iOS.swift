
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
    // Recording state (use CMTime from CMSampleBuffer instead of Date/TimeInterval)
    @State private var isRecording: Bool = false
    @State private var recordingStartTime: CMTime? = nil
    @State private var recordedPoses: [(CMTime, VNHumanHandPoseObservation)] = []
    // Optional callback to return the recorded data to a caller
    var onRecordingFinished: (([(CMTime, VNHumanHandPoseObservation)]) -> Void)? = nil
    @State private var showJointsSheet: Bool = false
    @State private var cameraVM: CameraVM = CameraVM()
    @State private var hands: [VNHumanHandPoseObservation] = []
    @State private var bodies: [VNHumanBodyPoseObservation] = []
    @Environment(AuthenticationViewModel.self) var authVM
    /// Tracks which hand joints the user wants visible on the overlay.
    /// Every joint starts hidden; users toggle them on via the sheet.
    @State private var jointVisibility: [VNHumanHandPoseObservation.JointName: Bool] = {
        var dict: [VNHumanHandPoseObservation.JointName: Bool] = [:]
        for joint in JointsSheetView.handJointLabels {
            dict[joint.name] = false
        }
        return dict
    }()
    
    /// Tracks which body joints the user wants visible on the overlay.
    @State private var bodyJointVisibility: [VNHumanBodyPoseObservation.JointName: Bool] = {
        var dict: [VNHumanBodyPoseObservation.JointName: Bool] = [:]
        for joint in JointsSheetView.bodyJointLabels {
            dict[joint.name] = false
        }
        return dict
    }()
    @State private var dotsVisibility: Bool = true
    @State private var handOutlineVisibility: Bool = true
    @State private var handSkeletonVisibility: Bool = true
    @State private var bodySkeletonVisibility: Bool = true
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
    
    // Store body joint connections for upper body (shoulders to elbows only - no wrists)
    let bodyConnections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
        // Left arm (shoulder to elbow only)
        (.leftShoulder, .leftElbow),
        // Right arm (shoulder to elbow only)
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
        ScrollView {
            VStack(spacing: 16) {
                if cameraVM.isAuthorized {
                    // Camera "window" that holds the live feed + ALL overlays
                    ZStack {
                        CameraPreviewView(session: cameraVM.session)
                            .ignoresSafeArea()
                        // IMPORTANT: GeometryReader is inside the window,
                        // so size is the window size (keeps overlays aligned).
                        GeometryReader { geo in
                            handOutlineOverlay(in: geo.size)
                            handJointLabelsOverlay(in: geo.size)
                            bodyJointLabelsOverlay(in: geo.size)
                            handSkeletonOverlay(in: geo.size)
                            bodySkeletonOverlay(in: geo.size)
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
            cameraVM.onPoseDetected = { handObservations, bodyObservations, pts in
                hands = handObservations
                bodies = bodyObservations
                // While recording, capture each observation with the provided CMTime timestamp
                if isRecording {
                    if recordingStartTime == nil { recordingStartTime = pts }
                    for obs in handObservations {
                        recordedPoses.append((pts, obs))
                    }
                }
            }
        }
        .onDisappear {
            cameraVM.stop()
        }
        .sheet(isPresented: $showJointsSheet) {
            JointsSheetView(
                jointVisibility: $jointVisibility,
                bodyJointVisibility: $bodyJointVisibility,
                dotsVisibility: $dotsVisibility,
                handOutlineVisibility: $handOutlineVisibility,
                handSkeletonVisibility: $handSkeletonVisibility,
                bodySkeletonVisibility: $bodySkeletonVisibility
            )
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    toggleRecording()
                }) {
                    Image(systemName: isRecording ? "stop.circle.fill" : "record.circle")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(isRecording ? .red : .red, .primary)
                        .accessibilityLabel(isRecording ? "Stop Recording" : "Start Recording")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    showJointsSheet = true
                }) {
                    Image(systemName: "gearshape.fill")
                }
            }
        }
    }
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
    private func handJointLabelsOverlay(in size: CGSize) -> some View {
        ForEach(hands, id: \.uuid) { hand in
            let visibleJoints = JointsSheetView.handJointLabels.filter { jointVisibility[$0.name] == true }
            ForEach(visibleJoints, id: \.name) { joint in
                if let point = try? hand.recognizedPoint(joint.name), point.confidence > 0.5 {
                    let pos = cameraVM.convertVisionPointToScreenPosition(visionPoint: point.location, viewSize: size)
                    // Adjust label based on chirality and camera mirror
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
    private func bodyJointLabelsOverlay(in size: CGSize) -> some View {
        ForEach(bodies, id: \.uuid) { body in
            let visibleBodyJoints = JointsSheetView.bodyJointLabels.filter { bodyJointVisibility[$0.name] == true }
            ForEach(visibleBodyJoints, id: \.name) { joint in
                if let point = try? body.recognizedPoint(joint.name), point.confidence > 0.3 {
                    let pos = cameraVM.convertVisionPointToScreenPosition(visionPoint: point.location, viewSize: size)
                    ZStack {
                        Text(joint.label)
                            .font(.caption2)
                            .padding(4)
                            .background(.ultraThinMaterial, in: Capsule())
                            .position(pos)
                        if dotsVisibility {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 8, height: 8)
                                .position(pos)
                        }
                    }
                }
            }
        }
    }
    @ViewBuilder
    private func handSkeletonOverlay(in size: CGSize) -> some View {
        if handSkeletonVisibility {
            ForEach(hands, id: \.uuid) { hand in
                // Adjust color based on chirality and camera mirror
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
    
    @ViewBuilder
    private func bodySkeletonOverlay(in size: CGSize) -> some View {
        if bodySkeletonVisibility {
            ForEach(bodies, id: \.uuid) { body in
                Path { path in
                    for connection in bodyConnections {
                        if let p1 = try? body.recognizedPoint(connection.0),
                           let p2 = try? body.recognizedPoint(connection.1),
                           p1.confidence > 0.3, p2.confidence > 0.3,
                           bodyJointVisibility[connection.0] == true, bodyJointVisibility[connection.1] == true {
                            let start = cameraVM.convertVisionPointToScreenPosition(visionPoint: p1.location, viewSize: size)
                            let end = cameraVM.convertVisionPointToScreenPosition(visionPoint: p2.location, viewSize: size)
                            path.move(to: start)
                            path.addLine(to: end)
                        }
                    }
                }
                .stroke(Color.orange.opacity(0.7), lineWidth: 4)
            }
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            // Stop recording and return the data
            isRecording = false
            if let callback = onRecordingFinished {
                callback(recordedPoses)
            } else {
                // Fallback: log the result for visibility during development
                print("Recorded poses count: \(recordedPoses.count)")
            }
            // Clear recorded poses after delivering them so memory doesn't accumulate
            recordedPoses.removeAll(keepingCapacity: true)
            recordingStartTime = nil
        } else {
            // Start recording: reset buffer and timestamp
            recordedPoses.removeAll(keepingCapacity: true)
            recordingStartTime = nil
            isRecording = true
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
        // Example: print the first 3 entries
        print("Preview received \(tuples.count) recorded tuples")
        print(tuples.prefix(3))
    })
    .environment(AuthenticationViewModel())
}
#endif
