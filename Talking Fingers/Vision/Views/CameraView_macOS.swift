//
//  CameraView_macOS.swift
//  Talking Fingers
//
//  Created by Jihoon Kim on 1/29/26.
//

<<<<<<< 126-mac-lofi-ui-view

=======
>>>>>>> main
#if os(macOS)
import SwiftUI

struct CameraView: View {
<<<<<<< 126-mac-lofi-ui-view
    @Environment(AuthenticationViewModel.self) var authVM

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            HStack(alignment: .top, spacing: 24) {
                // Main column (center)
                VStack(alignment: .leading, spacing: 18) {
                    topStrip
                    headerArea
                    practiceSurface
                    bottomControlsRow
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)

                // Right widgets column
                rightWidgetsColumn
            }
            .padding(28)
        }
        .toolbar {
            // Intentionally empty for now.
            // Teammates can add real toolbar items later without undoing layout work.
        }
    }
}

// MARK: - Sections

private extension CameraView {
    var topStrip: some View {
        HStack {
            // Leave area (empty)
            EmptyView()

            Spacer(minLength: 12)

            // Progress area (empty)
            EmptyView()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
    }

    var headerArea: some View {
        VStack(alignment: .leading, spacing: 10) {
            // "Try sign it out!" area (empty)
            EmptyView()

            // Big sentence area (empty)
            EmptyView()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var practiceSurface: some View {
        PracticeSurfaceCardView {
            VStack(spacing: 18) {
                // Tip chip area (empty)
                EmptyView()

                // Camera feed container (empty now; teammate can drop in their real view later)
                CameraFeedContainerView {
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(22)
        }
        .frame(maxWidth: 820, minHeight: 560)
    }

    var bottomControlsRow: some View {
        // Bottom icon row area (empty)
        HStack {
            Spacer()
            EmptyView()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    var rightWidgetsColumn: some View {
        VStack(spacing: 18) {
            WidgetCardView { EmptyView() }
                .frame(width: 260, height: 150)

            WidgetCardView { EmptyView() }
                .frame(width: 260, height: 150)

            WidgetCardView { EmptyView() }
                .frame(width: 260, height: 150)

            Spacer(minLength: 0)
        }
        .padding(.top, 44)
    }
}

// MARK: - Styled Containers (no placeholder text)

private struct PracticeSurfaceCardView<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .overlay { content() }
            .shadow(color: Color.black.opacity(0.25), radius: 18, x: 0, y: 8)
    }
}

private struct CameraFeedContainerView<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.white.opacity(0.03))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
            )
            .overlay { content() }
            .frame(maxWidth: 430, maxHeight: 330)
    }
}

private struct WidgetCardView<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .overlay { content() }
            .shadow(color: Color.black.opacity(0.20), radius: 14, x: 0, y: 6)
=======

    @State private var cameraVM: CameraVM = CameraVM()

    @State private var hands: [VNHumanHandPoseObservation] = []
    @State private var bodies: [VNHumanBodyPoseObservation] = []

    @State private var jointVisibility: [VNHumanHandPoseObservation.JointName: Bool] = {
        var dict: [VNHumanHandPoseObservation.JointName: Bool] = [:]
        for joint in JointsSheetView.handJointLabels {
            dict[joint.name] = true
        }
        return dict
    }()

    @State private var bodyJointVisibility: [VNHumanBodyPoseObservation.JointName: Bool] = {
        var dict: [VNHumanBodyPoseObservation.JointName: Bool] = [:]
        for joint in JointsSheetView.bodyJointLabels {
            dict[joint.name] = true
        }
        return dict
    }()

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
                    handOutlineOverlay(in: geo.size)
                    handJointLabelsOverlay(in: geo.size)
                    bodyJointLabelsOverlay(in: geo.size)
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
                    // toggleRecording()
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

    // MARK: - Coordinate conversion

    /// Mirrors the overlay horizontally when the preview is mirrored,
    /// so skeletons/labels line up with the camera image on macOS.
    private func screenPosition(from visionPoint: CGPoint, in viewSize: CGSize) -> CGPoint {
        let mirroredX = cameraVM.isMirrored ? (1 - visionPoint.x) : visionPoint.x
        let x = mirroredX * viewSize.width
        let y = (1 - visionPoint.y) * viewSize.height
        return CGPoint(x: x, y: y)
    }

    // MARK: - Overlays

    @ViewBuilder
    private func handOutlineOverlay(in size: CGSize) -> some View {
        if handOutlineVisibility {
            ForEach(hands, id: \.uuid) { hand in
                let points = perimeterJoints.compactMap { jointName -> CGPoint? in
                    guard let point = try? hand.recognizedPoint(jointName),
                          point.confidence > 0.5 else { return nil }
                    return screenPosition(from: point.location, in: size)
                }

                if points.count > 3 {
                    Path { path in
                        path.addLines(points)
                        path.closeSubpath()
                    }
                    .fill(Color.green.opacity(0.20))
                    .overlay(
                        Path { path in
                            path.addLines(points)
                            path.closeSubpath()
                        }
                        .stroke(Color.green.opacity(0.8), lineWidth: 2)
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func handJointLabelsOverlay(in size: CGSize) -> some View {
        ForEach(hands, id: \.uuid) { hand in
            let visibleJoints = JointsSheetView.handJointLabels.filter { jointVisibility[$0.name] == true }

            ForEach(visibleJoints, id: \.name) { joint in
                if let point = try? hand.recognizedPoint(joint.name),
                   point.confidence > 0.5 {

                    let pos = screenPosition(from: point.location, in: size)

                    let handSide = (cameraVM.isMirrored
                                    ? (hand.chirality == .left ? "R" : "L")
                                    : (hand.chirality == .left ? "L" : "R"))

                    ZStack {
                        Text("\(handSide) \(joint.label)")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
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
                if let point = try? body.recognizedPoint(joint.name),
                   point.confidence > 0.3 {

                    let pos = screenPosition(from: point.location, in: size)

                    ZStack {
                        Text(joint.label)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
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
                let handSkeletonColor = (cameraVM.isMirrored
                                         ? (hand.chirality == .left ? Color.purple : Color.blue)
                                         : (hand.chirality == .left ? Color.blue : Color.purple))

                Path { path in
                    for connection in handConnections {
                        if let p1 = try? hand.recognizedPoint(connection.0),
                           let p2 = try? hand.recognizedPoint(connection.1),
                           p1.confidence > 0.5,
                           p2.confidence > 0.5 {

                            let start = screenPosition(from: p1.location, in: size)
                            let end = screenPosition(from: p2.location, in: size)

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
                           p1.confidence > 0.3,
                           p2.confidence > 0.3 {

                            let start = screenPosition(from: p1.location, in: size)
                            let end = screenPosition(from: p2.location, in: size)

                            path.move(to: start)
                            path.addLine(to: end)
                        }
                    }
                }
                .stroke(Color.orange, lineWidth: 4)
            }
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
>>>>>>> main
    }
}

#Preview {
    CameraView()
        .environment(AuthenticationViewModel())
}
#endif
