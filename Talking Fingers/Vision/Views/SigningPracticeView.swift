//
//  SigningPracticeView.swift
//  Talking Fingers
//
#if os(iOS)
import SwiftUI

struct SigningPracticeView: View {
    @Environment(\.dismiss) var dismiss
    @State var passed: Bool = false
    // Example sentence
    let words: [String] = ["A", "B", "C"]

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
    @State private var handOutlineVisibility: Bool = true
    @State private var handSkeletonVisibility: Bool = true
    @State private var bodySkeletonVisibility: Bool = true

    @State var signName: String = "a"
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

            // MARK: Back Button
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "door.left.hand.open")
                        Text("Leave")
                    }
                }
                .foregroundColor(.gray)

                Spacer()
            }
            // MARK: Progress Line
            ProgressBar(
                total: words.count,
                current: currentWordIndex
            )

            // MARK: Phrase Header
            Text(signName.capitalized)
                .font(.title2)
                .foregroundColor(.primary)

            // MARK: Camera Window (replaces cartoon)
                VStack(spacing: 16) {
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


                                VStack {
                                    Spacer()
                                    Text("\(Int(cameraVM.confidenceScore))%")
                                        .font(.system(size: 56, weight: .bold, design: .rounded))
                                        .foregroundStyle(confidenceColor)
                                        .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                                        .contentTransition(.numericText())
                                        .animation(.easeInOut(duration: 0.15), value: Int(cameraVM.confidenceScore))
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                        .padding(.bottom, 20)
                                }
                        }
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

                    VStack(alignment: .leading, spacing: 8) {
                        // future UI elements
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
                .padding(.top, 12)
            .onAppear {
                cameraVM.checkPermission()

                cameraVM.onPoseDetected = { handObservations, pts in
                    hands = handObservations

                    guard cameraVM.isRecording else { return }
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
                print("Current word is \(newValue)")
                if cameraMode == .compare {
                    cameraVM.startComparing(forSign: newValue)
                    pass = false
                }
            }
            .onChange(of: cameraVM.confidenceScore) { _, newValue in
                if Int(cameraVM.confidenceScore) > 70 {
                    pass = true
                }
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


            // MARK: Navigation Buttons
            if pass && (currentWordIndex < words.count - 1) {
                HStack(spacing: 40) {
                    Button (action: {
                        nextWord()
                        signName = words[currentWordIndex]
                        pass = false
                    }) {
                        Text("Next Word")
                            .foregroundStyle(Color.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(111)
                }
            } else if pass && (currentWordIndex == words.count - 1) {
                HStack(spacing: 40) {
                    Button (action: {
                        dismiss()
                    }) {
                        Text("Finish")
                            .foregroundStyle(Color.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(111)
                }
            }

            Spacer()
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }

    // MARK: Navigation Logic

    func nextWord() {
        if currentWordIndex < words.count - 1 {
            currentWordIndex += 1
        }
    }

    func previousWord() {
        if currentWordIndex > 0 {
            currentWordIndex -= 1
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
                    let pos = cameraVM.convertVisionPointToScreenPosition(
                        visionPoint: point.location,
                        viewSize: size
                    )
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

