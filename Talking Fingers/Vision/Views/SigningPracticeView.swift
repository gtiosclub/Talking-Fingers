//
//  SigningPracticeView.swift
//  Talking Fingers
//

import SwiftUI
import AVFoundation
import Vision

enum CameraMode: String, CaseIterable {
    case `static`
    case dynamic
    case compare
}

#if os(iOS)
struct SigningPracticeView: View {
    @Environment(\.dismiss) var dismiss
    @State var passed: Bool = false
    // Example sentence
    
    @State private var currentWordIndex: Int = 0
    @State var pass: Bool = false
    @State private var showJointsSheet: Bool = false
    @State private var cameraVM: CameraVM
    /// When `true` the view manages the camera's `start`/`stop` lifecycle in
    /// `.onAppear`/`.onDisappear`. When an external VM is passed in, the parent
    /// is responsible for lifecycle, so we skip those calls.
    private let ownsCameraLifecycle: Bool

    @State private var hands: [VNHumanHandPoseObservation] = []
    @State private var bodies: [VNHumanBodyPoseObservation] = []

    @Environment(AuthenticationViewModel.self) var authVM

    /// Tracks which hand joints the user wants visible on the overlay.
    @State private var jointVisibility: [VNHumanHandPoseObservation.JointName: Bool] = {
        var dict: [VNHumanHandPoseObservation.JointName: Bool] = [:]
        for joint in JointsSheetView.handJointLabels {
            dict[joint.name] = true
        }
        return dict
    }()

    /// Tracks which body joints the user wants visible on the overlay.
    @State private var bodyJointVisibility: [VNHumanBodyPoseObservation.JointName: Bool] = {
        var dict: [VNHumanBodyPoseObservation.JointName: Bool] = [:]
        for joint in JointsSheetView.bodyJointLabels {
            dict[joint.name] = true
        }
        return dict
    }()

    @State private var dotsVisibility: Bool = true
    @State private var jointNamesVisibility: Bool = false
    @State private var handOutlineVisibility: Bool = false
    @State private var handSkeletonVisibility: Bool = true
    @State private var bodySkeletonVisibility: Bool = true

    let signName: String?
    var onConfidenceChange: ((Double) -> Void)?
    /// Present for API parity with the macOS variant; the iOS view has no
    /// built-in leave button so this value is currently unused.
    var showsLeaveButton: Bool
    /// When `true` (default) the view applies its own horizontal padding and a
    /// 9:16 aspect ratio constraint to the camera. Set to `false` when
    /// embedding in a parent that wants to control sizing directly.
    var usesInternalPadding: Bool
    init(signName: String? = nil,
         onConfidenceChange: ((Double) -> Void)? = nil,
         showsLeaveButton: Bool = true,
         usesInternalPadding: Bool = true,
         externalCameraVM: CameraVM? = nil) {
        self.signName = signName
        self.onConfidenceChange = onConfidenceChange
        self.showsLeaveButton = showsLeaveButton
        self.usesInternalPadding = usesInternalPadding
        _cameraVM = State(initialValue: externalCameraVM ?? CameraVM())
        self.ownsCameraLifecycle = externalCameraVM == nil
    }
    @State private var cameraMode: CameraMode = .compare

    @State private var countdown: Int = 0
    @State private var countdownTask: Task<Void, Never>?

    /// Tracks when both hands were last visible during a recording.
    /// `nil` means hands haven't appeared yet this recording session.
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
        Group {
            if cameraVM.isAuthorized {
                ZStack {
                    CameraPreviewView(session: cameraVM.session)
                        .ignoresSafeArea()
                    GeometryReader { geo in
                        handOutlineOverlay(in: geo.size)
                        handJointLabelsOverlay(in: geo.size)
                        bodyJointLabelsOverlay(in: geo.size)
                        handSkeletonOverlay(in: geo.size)
                        bodySkeletonOverlay(in: geo.size)
                    }
                    if signName != nil && hands.count > 0 {
                        VStack {
                            HStack {
                                Spacer()
                                Text(confidenceLabel)
                                    .foregroundStyle(confidenceColor)
                                    .contentTransition(.interpolate)
                                    .animation(.easeInOut(duration: 0.15), value: confidenceLabel)
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
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView(
                    "Camera Access Required",
                    systemImage: "camera.fill",
                    description: Text("Please allow camera access in Settings to use sign language recognition.")
                )
            }
        }
        .onAppear {
            cameraVM.checkPermission()

            cameraVM.onPoseDetected = { handObservations, pts in
                hands = handObservations

                guard cameraVM.isRecording else { return }
            }

            cameraVM.onBodyPoseDetected = { bodyObservations, _ in
                bodies = bodyObservations
            }
            cameraVM.startComparing(forSign: signName ?? "")
        }
        .task {
            try? await Task.sleep(for: .milliseconds(300))
            cameraVM.start()
        }
        .onDisappear {
            cameraVM.stop()
        }
        .onChange(of: cameraMode) { _, newValue in
            if newValue == .compare {
                cameraVM.startComparing(forSign: signName ?? "")
            } else {
                cameraVM.stopComparing()
            }
        }
        .onChange(of: cameraVM.confidenceScore) { _, newValue in
                let goodThreshold: Double = cameraVM.activeComparisonType == .static ? 62 : 50
            if cameraVM.confidenceScore >= goodThreshold {
                onConfidenceChange?(newValue)
                pass = true
            }
        }
        .onChange(of: signName ?? "") { _, newValue in
            print("Current word is \(newValue)")
            if cameraMode == .compare {
                cameraVM.startComparing(forSign: newValue)
                pass = false
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    @ViewBuilder
    private func handOutlineOverlay(in size: CGSize) -> some View {
        if handOutlineVisibility {
            ForEach(hands, id: \.uuid) { hand in
                let points = perimeterJoints.compactMap { jointName -> CGPoint? in
                    guard let point = try? hand.recognizedPoint(jointName),
                          point.confidence > 0.5 else { return nil }
                    return cameraVM.convertVisionPointToScreenPosition(
                        visionPoint: point.location,
                        viewSize: size
                    )
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
                    let pos = cameraVM.convertVisionPointToScreenPosition(
                        visionPoint: point.location,
                        viewSize: size
                    )

                    let handSide = (cameraVM.isMirrored
                                    ? (hand.chirality == .left ? "R" : "L")
                                    : (hand.chirality == .left ? "L" : "R"))

                    ZStack {
                        if jointNamesVisibility {
                            Text("\(handSide) \(joint.label)")
                                .font(.caption2)
                                .padding(4)
                                .background(.ultraThinMaterial, in: Capsule())
                                .position(pos)
                        }

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
                    let pos = cameraVM.convertVisionPointToScreenPosition(
                        visionPoint: point.location,
                        viewSize: size
                    )
                    ZStack {
                        if jointNamesVisibility {
                            Text(joint.label)
                                .font(.caption2)
                                .padding(4)
                                .background(.ultraThinMaterial, in: Capsule())
                                .position(pos)
                        }

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
                           p1.confidence > 0.5, p2.confidence > 0.5,
                           jointVisibility[connection.0] == true,
                           jointVisibility[connection.1] == true {

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
                           bodyJointVisibility[connection.0] == true,
                           bodyJointVisibility[connection.1] == true {

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

    private var confidenceColor: Color {
        let score = cameraVM.confidenceScore
        let goodThreshold: Double = cameraVM.activeComparisonType == .static ? 62 : 50
        let okayThreshold: Double = cameraVM.activeComparisonType == .static ? 46 : 27
        if score >= goodThreshold { return .green }
        if score >= okayThreshold { return .yellow }
        return .red
    }

    private var confidenceLabel: String {
        let score = cameraVM.confidenceScore
        let goodThreshold: Double = cameraVM.activeComparisonType == .static ? 62 : 50
        let okayThreshold: Double = cameraVM.activeComparisonType == .static ? 46 : 27
        if score >= goodThreshold { return "Good" }
        if score >= okayThreshold { return "Okay" }
        return "Bad"
    }
}

#Preview {
    //SigningPracticeView()
}


struct ProgressBar: View {
    let total: Int
    let current: Int
    var body: some View {
        // let width: CGFloat = 364
        let height: CGFloat = 12
        let progress = max(0, min(1, Double(current + 1) / Double(total)))
        HStack(alignment: .center, spacing: 12) {
            GeometryReader { proxy in
                let availableWidth = proxy.size.width
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: height/2, style: .continuous)
                        .fill(.quaternary)
                        .frame(height: height)
                    RoundedRectangle(cornerRadius: height/2, style: .continuous)
                        .fill(Color.accentColor)
                        .frame(width: max(0, availableWidth * progress), height: height)
                }
            }
            .frame(height: height)

            Button(action: {
                print("something")
            }) {
                Image(systemName: "line.3.horizontal")
                    .foregroundStyle(Color.black)
            }
        }
    }
}

//
//  CameraView.swift
//  Talking Fingers
//
//  Created by Jihoon Kim on 1/29/26.
//
import SwiftUI
import AVFoundation
import Vision

private struct CameraAspectModifier: ViewModifier {
    let usesAspectRatio: Bool
    func body(content: Content) -> some View {
        if usesAspectRatio {
            content.aspectRatio(9.0 / 16.0, contentMode: .fit)
        } else {
            content
        }
    }
}
#endif

#if os(macOS)
struct SigningPracticeView: View {
    @Environment(\.dismiss) private var dismiss

    /// Optional sign reference name to compare the user's pose against.
    /// When `nil`, the comparison overlay (Bad/Okay/Good label) is hidden
    /// and no reference is loaded.
    let signName: String?
    var onConfidenceChange: ((Double) -> Void)?
    /// When `false`, hides the top "Leave" button so the view can be embedded
    /// inside another view that already provides navigation.
    var showsLeaveButton: Bool
    /// When `true` (default) the view applies its own horizontal padding and a
    /// 16:9 aspect ratio constraint to the camera. Set to `false` when
    /// embedding in a parent that wants to control sizing directly.
    var usesInternalPadding: Bool
    init(signName: String? = nil,
         onConfidenceChange: ((Double) -> Void)? = nil,
         showsLeaveButton: Bool = true,
         usesInternalPadding: Bool = true,
         externalCameraVM: CameraVM? = nil) {
        self.signName = signName
        self.onConfidenceChange = onConfidenceChange
        self.showsLeaveButton = showsLeaveButton
        self.usesInternalPadding = usesInternalPadding
        _cameraVM = State(initialValue: externalCameraVM ?? CameraVM())
        self.ownsCameraLifecycle = externalCameraVM == nil
    }
    @State private var cameraVM: CameraVM
    /// When `true` the view manages the camera's `start`/`stop` lifecycle in
    /// `.onAppear`/`.onDisappear`. When an external VM is passed in, the parent
    /// is responsible for lifecycle, so we skip those calls.
    private let ownsCameraLifecycle: Bool

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
    @State private var jointNamesVisibility: Bool = false
    @State private var handOutlineVisibility: Bool = false
    @State private var handSkeletonVisibility: Bool = true
    @State private var bodySkeletonVisibility: Bool = true

    let handConnections: [(VNHumanHandPoseObservation.JointName, VNHumanHandPoseObservation.JointName)] = [
        (.wrist, .thumbCMC), (.thumbCMC, .thumbMP), (.thumbMP, .thumbIP), (.thumbIP, .thumbTip),
        (.wrist, .indexMCP), (.indexMCP, .indexPIP), (.indexPIP, .indexDIP), (.indexDIP, .indexTip),
        (.wrist, .middleMCP), (.middleMCP, .middlePIP), (.middlePIP, .middleDIP), (.middleDIP, .middleTip),
        (.wrist, .ringMCP), (.ringMCP, .ringPIP), (.ringPIP, .ringDIP), (.ringDIP, .ringTip),
        (.wrist, .littleMCP), (.littleMCP, .littlePIP), (.littlePIP, .littleDIP), (.littleDIP, .littleTip)
    ]

    let bodyConnections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
        (.leftShoulder, .leftElbow),
        (.rightShoulder, .rightElbow)
    ]

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
        Group {
            if cameraVM.isAuthorized {
                ZStack {
                    CameraPreviewView(
                        session: cameraVM.session,
                        isMirrored: cameraVM.isMirrored
                    )
                    .ignoresSafeArea()

                    GeometryReader { geo in
                        handOutlineOverlay(in: geo.size)
                        handJointLabelsOverlay(in: geo.size)
                        bodyJointLabelsOverlay(in: geo.size)
                        handSkeletonOverlay(in: geo.size)
                        bodySkeletonOverlay(in: geo.size)
                    }
                    if signName != nil && hands.count > 0 {
                        VStack {
                            HStack {
                                Spacer()
                                Text(confidenceLabel)
                                    .foregroundStyle(confidenceColor)
                                    .contentTransition(.interpolate)
                                    .animation(.easeInOut(duration: 0.15), value: confidenceLabel)
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
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView(
                    "Camera Access Required",
                    systemImage: "camera.fill",
                    description: Text("Please allow camera access in Settings to use sign language recognition.")
                )
            }
        }
        .onAppear {
            if ownsCameraLifecycle {
                cameraVM.isMirrored = true
                cameraVM.checkPermission()
            }

            cameraVM.onPoseDetected = { handObservations, _ in
                hands = handObservations
            }

            cameraVM.onBodyPoseDetected = { bodyObservations, _ in
                bodies = bodyObservations
            }

            if let signName {
                cameraVM.startComparing(forSign: signName)
            }
        }
        .task {
            guard ownsCameraLifecycle else { return }
            try? await Task.sleep(for: .milliseconds(300))
            cameraVM.start()
        }
        .onDisappear {
            if ownsCameraLifecycle {
                cameraVM.stop()
            }
        }
        .onChange(of: signName) { _, newValue in
            if let newValue {
                cameraVM.startComparing(forSign: newValue)
            } else {
                cameraVM.stopComparing()
            }
        }
        .onChange(of: cameraVM.confidenceScore) { _, newValue in
            let goodThreshold: Double = cameraVM.activeComparisonType == .static ? 62 : 50
            if cameraVM.confidenceScore >= goodThreshold {
                onConfidenceChange?(newValue)
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
                    return cameraVM.convertVisionPointToScreenPosition(
                        visionPoint: point.location,
                        viewSize: size
                    )
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
                    let pos = cameraVM.convertVisionPointToScreenPosition(
                        visionPoint: point.location,
                        viewSize: size
                    )

                    let handSide = (cameraVM.isMirrored
                                    ? (hand.chirality == .left ? "R" : "L")
                                    : (hand.chirality == .left ? "L" : "R"))

                    ZStack {
                        if jointNamesVisibility {
                            Text("\(handSide) \(joint.label)")
                                .font(.caption2)
                                .padding(4)
                                .background(.ultraThinMaterial, in: Capsule())
                                .position(pos)
                        }

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
                    let pos = cameraVM.convertVisionPointToScreenPosition(
                        visionPoint: point.location,
                        viewSize: size
                    )
                    ZStack {
                        if jointNamesVisibility {
                            Text(joint.label)
                                .font(.caption2)
                                .padding(4)
                                .background(.ultraThinMaterial, in: Capsule())
                                .position(pos)
                        }

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
                           p1.confidence > 0.5, p2.confidence > 0.5,
                           jointVisibility[connection.0] == true,
                           jointVisibility[connection.1] == true {

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
                           bodyJointVisibility[connection.0] == true,
                           bodyJointVisibility[connection.1] == true {

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
    private var confidenceColor: Color {
        let score = cameraVM.confidenceScore
        let goodThreshold: Double = cameraVM.activeComparisonType == .static ? 62 : 50
        let okayThreshold: Double = cameraVM.activeComparisonType == .static ? 46 : 27
        if score >= goodThreshold { return .green }
        if score >= okayThreshold { return .yellow }
        return .red
    }

    private var confidenceLabel: String {
        let score = cameraVM.confidenceScore
        let goodThreshold: Double = cameraVM.activeComparisonType == .static ? 62 : 50
        let okayThreshold: Double = cameraVM.activeComparisonType == .static ? 46 : 27
        if score >= goodThreshold { return "Good" }
        if score >= okayThreshold { return "Okay" }
        return "Bad"
    }
}

private struct CameraAspectModifierMacOS: ViewModifier {
    let usesAspectRatio: Bool
    func body(content: Content) -> some View {
        if usesAspectRatio {
            content.aspectRatio(16.0 / 9.0, contentMode: .fit)
        } else {
            content
        }
    }
}
#endif
