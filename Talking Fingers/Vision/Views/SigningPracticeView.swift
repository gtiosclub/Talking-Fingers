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
    @State private var cameraVM: CameraVM = CameraVM()

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

    @State var signName: String? = nil
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

        VStack(spacing: 20) {
            // MARK: Camera Window (replaces cartoon)
                VStack(spacing: 16) {
                    if cameraVM.isAuthorized {

                        ZStack {
                            CameraPreviewView(session: cameraVM.session)
                                .ignoresSafeArea()
                            GeometryReader { geo in
                                handOutlineOverlay(in: geo.size)
                                    .ignoresSafeArea()
                                handJointLabelsOverlay(in: geo.size)
                                    .ignoresSafeArea()
                                bodyJointLabelsOverlay(in: geo.size)
                                    .ignoresSafeArea()
                                handSkeletonOverlay(in: geo.size)
                                    .ignoresSafeArea()
                                bodySkeletonOverlay(in: geo.size)
                                    .ignoresSafeArea()
                            }
                            .ignoresSafeArea()
                            VStack {
                                Spacer()
                                if  hands.count > 0  && signName != nil {
                                    Text(confidenceLabel)
                                        .font(.system(size: 56, weight: .bold, design: .rounded))
                                        .foregroundStyle(confidenceColor)
                                        .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                                        .contentTransition(.interpolate)
                                        .animation(.easeInOut(duration: 0.15), value: confidenceLabel)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                        .padding(.bottom, 20)
                                }
                            }
                            .ignoresSafeArea()
                        }
                        .frame(maxWidth: .infinity)
                        .ignoresSafeArea()
                    } else {
                        ContentUnavailableView(
                            "Camera Access Required",
                            systemImage: "camera.fill",
                            description: Text("Please allow camera access in Settings to use sign language recognition.")
                        )
                        .padding(.horizontal)
                        .padding(.top, 24)
                    }
                }
                .ignoresSafeArea()
                .onAppear {
                    print(signName)
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
                    if Int(cameraVM.confidenceScore) > 70 {
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
                    
            }
            .navigationBarBackButtonHidden(true)
    }
    
    @ViewBuilder
    private func handOutlineOverlay(in size: CGSize) -> some View {
        if handOutlineVisibility {
            ForEach(hands, id: \.uuid) { hand in
                let points = perimeterJoints.compactMap { jointName -> CGPoint? in
                    guard let point = try? hand.recognizedPoint(jointName),
                          point.confidence > 0.7 else { return nil }
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
                    .ignoresSafeArea()
                }
            }
        }
    }

    @ViewBuilder
    private func handJointLabelsOverlay(in size: CGSize) -> some View {
        ForEach(hands, id: \.uuid) { hand in
            let visibleJoints = JointsSheetView.handJointLabels.filter { jointVisibility[$0.name] == true }
            ForEach(visibleJoints, id: \.name) { joint in
                if let point = try? hand.recognizedPoint(joint.name), point.confidence > 0.7 {
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
                                .ignoresSafeArea()
                        }

                        if dotsVisibility {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 7, height: 7)
                                .position(pos)
                                .ignoresSafeArea()
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
        switch cameraVM.confidenceScore {
        case 75...100: return .green
        case 40..<75: return .yellow
        default: return .red
        }
    }

    private var confidenceLabel: String {
        switch cameraVM.confidenceScore {
        case 75...100: return "Good"
        case 40..<75: return "Okay"
        default: return "Bad"
        }
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
#endif

#if os(macOS)
struct SigningPracticeView: View {
    @Environment(\.dismiss) private var dismiss

    let words: [String] = ["A", "B", "C"]

    @State private var currentWordIndex: Int = 0
    @State private var pass: Bool = false
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
    @State private var jointNamesVisibility: Bool = false
    @State private var handOutlineVisibility: Bool = false
    @State private var handSkeletonVisibility: Bool = true
    @State private var bodySkeletonVisibility: Bool = true

    @State private var signName: String = "a"
    @State private var cameraMode: CameraMode = .compare

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
        VStack(spacing: 20) {
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "door.left.hand.open")
                        Text("Leave")
                    }
                }
                .foregroundColor(.gray)

                Spacer()
            }
            .padding(.horizontal)

            MacPracticeProgressBar(
                total: words.count,
                current: currentWordIndex
            )
            .padding(.horizontal)

            Text(signName.capitalized)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.primary)

            VStack(spacing: 16) {
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

                        VStack {
                            Spacer()
                            Text(confidenceLabel)
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundStyle(confidenceColor)
                                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                                .contentTransition(.interpolate)
                                .animation(.easeInOut(duration: 0.15), value: confidenceLabel)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .padding(.bottom, 20)
                        }
                    }
                    .aspectRatio(16.0 / 9.0, contentMode: .fit)
                    .frame(maxWidth: 980)
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
            }
            .padding(.top, 8)

            Spacer(minLength: 0)

            Button(action: {
                if currentWordIndex < words.count - 1 {
                    nextWord()
                } else {
                    dismiss()
                }
            }) {
                Text(currentWordIndex < words.count - 1 ? "Next Word" : "Done")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(pass ? Color.green : Color.gray.opacity(0.45))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!pass)
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
        .padding(.top, 20)
        .onAppear {
            cameraVM.isMirrored = true
            signName = words[currentWordIndex].lowercased()

            cameraVM.checkPermission()

            cameraVM.onPoseDetected = { handObservations, _ in
                hands = handObservations
            }

            cameraVM.onBodyPoseDetected = { bodyObservations, _ in
                bodies = bodyObservations
            }

            cameraVM.startComparing(forSign: signName)
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
                cameraVM.startComparing(forSign: signName)
            } else {
                cameraVM.stopComparing()
            }
        }
        .onChange(of: signName) { _, newValue in
            if cameraMode == .compare {
                cameraVM.startComparing(forSign: newValue)
                pass = false
            }
        }
        .onChange(of: cameraVM.confidenceScore) { _, newValue in
            if Int(newValue) > 70 {
                pass = true
            }
        }
    }

    private func nextWord() {
        guard currentWordIndex < words.count - 1 else { return }
        currentWordIndex += 1
        signName = words[currentWordIndex].lowercased()
        pass = false
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
        switch cameraVM.confidenceScore {
        case 75...100: return .green
        case 40..<75: return .yellow
        default: return .red
        }
    }

    private var confidenceLabel: String {
        switch cameraVM.confidenceScore {
        case 75...100: return "Good"
        case 40..<75: return "Okay"
        default: return "Bad"
        }
    }
}

private struct MacPracticeProgressBar: View {
    let total: Int
    let current: Int

    var body: some View {
        let height: CGFloat = 12
        let progress = max(0, min(1, Double(current + 1) / Double(total)))

        GeometryReader { proxy in
            let availableWidth = proxy.size.width

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                    .fill(.quaternary)
                    .frame(height: height)

                RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                    .fill(Color.accentColor)
                    .frame(width: max(0, availableWidth * progress), height: height)
            }
        }
        .frame(height: height)
    }
}
#endif
