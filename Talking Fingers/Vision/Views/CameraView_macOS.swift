//
//  CameraView_macOS.swift
//  Talking Fingers
//
//  Created by Jihoon Kim on 1/29/26.
//

#if os(macOS)
import SwiftUI
import AVFoundation
import Vision
import AppKit
import Observation

struct CameraView: View {
    @State private var cameraVM = CameraVM()

    @State private var hands: [VNHumanHandPoseObservation] = []
    @State private var bodies: [VNHumanBodyPoseObservation] = []

    @State private var dotsVisibility: Bool = true
    @State private var jointNamesVisibility: Bool = false
    @State private var handOutlineVisibility: Bool = false
    @State private var handSkeletonVisibility: Bool = true
    @State private var bodySkeletonVisibility: Bool = true

    /// Live, user-editable name of the sign reference to compare against.
    /// When blank, no comparison runs and the Bad/Okay/Good label is hidden.
    @State private var signNameInput: String = ""

    /// When `true`, the comparison overlay shows the raw numeric score
    /// instead of the Bad/Okay/Good word.
    @State private var showRawConfidence: Bool = false

    /// Trimmed version of `signNameInput`. `nil` when blank.
    private var activeSignName: String? {
        let trimmed = signNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    @State private var jointVisibility: [VNHumanHandPoseObservation.JointName: Bool] = {
        var dict: [VNHumanHandPoseObservation.JointName: Bool] = [:]
        for joint in HandJointLabel.allCases {
            dict[joint.name] = true
        }
        return dict
    }()

    @State private var bodyJointVisibility: [VNHumanBodyPoseObservation.JointName: Bool] = {
        var dict: [VNHumanBodyPoseObservation.JointName: Bool] = [:]
        for joint in BodyJointLabel.allCases {
            dict[joint.name] = true
        }
        return dict
    }()

    private let handConnections: [(VNHumanHandPoseObservation.JointName, VNHumanHandPoseObservation.JointName)] = [
        (.wrist, .thumbCMC), (.thumbCMC, .thumbMP), (.thumbMP, .thumbIP), (.thumbIP, .thumbTip),
        (.wrist, .indexMCP), (.indexMCP, .indexPIP), (.indexPIP, .indexDIP), (.indexDIP, .indexTip),
        (.wrist, .middleMCP), (.middleMCP, .middlePIP), (.middlePIP, .middleDIP), (.middleDIP, .middleTip),
        (.wrist, .ringMCP), (.ringMCP, .ringPIP), (.ringPIP, .ringDIP), (.ringDIP, .ringTip),
        (.wrist, .littleMCP), (.littleMCP, .littlePIP), (.littlePIP, .littleDIP), (.littleDIP, .littleTip)
    ]

    private let bodyConnections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
        (.leftShoulder, .leftElbow),
        (.rightShoulder, .rightElbow)
    ]

    private let perimeterJoints: [VNHumanHandPoseObservation.JointName] = [
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
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Vision")
                            .font(.system(size: 28, weight: .semibold))
                        Text("Live camera feed with mirrored preview and pose overlays")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()

                    HStack(spacing: 6) {
                        Image(systemName: "hand.raised.fingers.spread")
                            .foregroundStyle(.secondary)
                        TextField("Sign reference (e.g. a)", text: $signNameInput)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 220)
                            .disableAutocorrection(true)
                        if !signNameInput.isEmpty {
                            Button {
                                signNameInput = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.secondary)
                            .help("Clear comparison reference")
                        }
                    }

                    Toggle(isOn: $showRawConfidence) {
                        HStack(spacing: 6) {
                            Image(systemName: showRawConfidence ? "number" : "textformat")
                            Text(showRawConfidence ? "Score" : "Label")
                        }
                    }
                    .toggleStyle(.switch)
                    .help("Toggle between word label and raw confidence score")
                }
                .padding(.horizontal, 28)
                .padding(.top, 20)

                Group {
                    if cameraVM.isAuthorized {
                        ZStack {
                            CameraPreviewView(
                                session: cameraVM.session,
                                isMirrored: cameraVM.isMirrored
                            )

                            GeometryReader { geo in
                                handOutlineOverlay(in: geo.size)
                                handJointLabelsOverlay(in: geo.size)
                                bodyJointLabelsOverlay(in: geo.size)
                                handSkeletonOverlay(in: geo.size)
                                bodySkeletonOverlay(in: geo.size)
                            }

                            if activeSignName != nil {
                                VStack {
                                    Spacer()
                                    Text(confidenceDisplay)
                                        .font(.system(size: 56, weight: .bold, design: .rounded))
                                        .foregroundStyle(confidenceColor)
                                        .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                                        .contentTransition(.interpolate)
                                        .animation(.easeInOut(duration: 0.15), value: confidenceDisplay)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                        .padding(.bottom, 20)
                                }
                            }
                        }
                        .aspectRatio(16.0 / 9.0, contentMode: .fit)
                        .frame(maxWidth: 1100)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 8)
                        .padding(.horizontal, 28)
                        .padding(.bottom, 24)
                    } else {
                        ContentUnavailableView(
                            "Camera Access Required",
                            systemImage: "camera.fill",
                            description: Text("Allow camera access in System Settings to view the live feed.")
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
        .onAppear {
            cameraVM.isMirrored = true

            cameraVM.onPoseDetected = { handObservations, _ in
                hands = handObservations
            }

            cameraVM.onBodyPoseDetected = { bodyObservations, _ in
                bodies = bodyObservations
            }

            cameraVM.checkPermission()

            if let activeSignName {
                cameraVM.startComparing(forSign: activeSignName)
            }
        }
        .task {
            try? await Task.sleep(for: .milliseconds(250))
            cameraVM.start()
        }
        .onDisappear {
            cameraVM.stop()
        }
        .onChange(of: signNameInput) { _, _ in
            if let activeSignName {
                cameraVM.startComparing(forSign: activeSignName)
            } else {
                cameraVM.stopComparing()
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

    private var confidenceDisplay: String {
        showRawConfidence ? "\(Int(cameraVM.confidenceScore.rounded()))%" : confidenceLabel
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
                    .fill(Color.green.opacity(0.25))
                    .stroke(Color.green, lineWidth: 2)
                }
            }
        }
    }

    @ViewBuilder
    private func handJointLabelsOverlay(in size: CGSize) -> some View {
        ForEach(hands, id: \.uuid) { hand in
            let visibleJoints = HandJointLabel.allCases.filter { jointVisibility[$0.name] == true }

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
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial, in: Capsule())
                                .position(pos)
                        }

                        if dotsVisibility {
                            Circle()
                                .fill(.white)
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
            let visibleJoints = BodyJointLabel.allCases.filter { bodyJointVisibility[$0.name] == true }

            ForEach(visibleJoints, id: \.name) { joint in
                if let point = try? body.recognizedPoint(joint.name), point.confidence > 0.3 {
                    let pos = cameraVM.convertVisionPointToScreenPosition(
                        visionPoint: point.location,
                        viewSize: size
                    )

                    ZStack {
                        if jointNamesVisibility {
                            Text(joint.label)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
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
                let color = (cameraVM.isMirrored
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
                .stroke(color.opacity(0.75), lineWidth: 3)
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
                .stroke(Color.orange.opacity(0.75), lineWidth: 4)
            }
        }
    }
}

// MARK: - Lightweight camera VM for feed + overlays only

@Observable
final class VisionCameraFeedVM: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()

    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "vision.feed.session.queue")
    private let outputQueue = DispatchQueue(label: "vision.feed.output.queue")

    var isAuthorized = false
    var isMirrored = true

    var onPoseDetected: (([VNHumanHandPoseObservation]) -> Void)?
    var onBodyPoseDetected: (([VNHumanBodyPoseObservation]) -> Void)?

    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.isAuthorized = granted
                    if granted {
                        self.start()
                    }
                }
            }
        default:
            isAuthorized = false
        }
    }

    func start() {
        sessionQueue.async {
            guard self.isAuthorized else { return }

            if self.session.inputs.isEmpty {
                self.setupSession()
            }

            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    func stop() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    private func setupSession() {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .hd1280x720

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else { return }

        do {
            try device.lockForConfiguration()
            device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 24)
            device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 24)
            device.unlockForConfiguration()
        } catch {
            print("Could not configure frame rate: \(error)")
        }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ]
        videoOutput.setSampleBufferDelegate(self, queue: outputQueue)

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        if let connection = videoOutput.connection(with: .video) {
            connection.videoRotationAngle = 0
            connection.isVideoMirrored = isMirrored
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        autoreleasepool {
            let handler = VNImageRequestHandler(
                cmSampleBuffer: sampleBuffer,
                orientation: .up,
                options: [:]
            )

            let handRequest = VNDetectHumanHandPoseRequest()
            handRequest.maximumHandCount = 2

            let bodyRequest = VNDetectHumanBodyPoseRequest()

            do {
                try handler.perform([handRequest, bodyRequest])

                let hands = handRequest.results ?? []
                let bodies = bodyRequest.results ?? []

                DispatchQueue.main.async {
                    self.onPoseDetected?(hands)
                    self.onBodyPoseDetected?(bodies)
                }
            } catch {
                print("Vision error: \(error)")
            }
        }
    }

    func convertVisionPointToScreenPosition(visionPoint: CGPoint, viewSize: CGSize) -> CGPoint {
        let sourceSize = CGSize(width: 1280, height: 720)

        let scale = max(viewSize.width / sourceSize.width,
                        viewSize.height / sourceSize.height)

        let scaledWidth = sourceSize.width * scale
        let scaledHeight = sourceSize.height * scale

        let xCrop = (scaledWidth - viewSize.width) / 2
        let yCrop = (scaledHeight - viewSize.height) / 2

        let x = visionPoint.x * scaledWidth - xCrop
        let y = (1 - visionPoint.y) * scaledHeight - yCrop

        return CGPoint(x: x, y: y)
    }
}

// MARK: - Preview

struct CameraPreviewView: NSViewRepresentable {
    let session: AVCaptureSession
    var isMirrored: Bool = true

    final class VideoPreviewView: NSView {
        let previewLayer = AVCaptureVideoPreviewLayer()

        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            wantsLayer = true
            layer = CALayer()
            layer?.masksToBounds = true
            previewLayer.videoGravity = .resizeAspectFill
            layer?.addSublayer(previewLayer)
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            wantsLayer = true
            layer = CALayer()
            layer?.masksToBounds = true
            previewLayer.videoGravity = .resizeAspectFill
            layer?.addSublayer(previewLayer)
        }

        override func layout() {
            super.layout()
            previewLayer.frame = bounds
        }
    }

    func makeNSView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        configure(view)
        return view
    }

    func updateNSView(_ nsView: VideoPreviewView, context: Context) {
        configure(nsView)
    }

    private func configure(_ view: VideoPreviewView) {
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.previewLayer.frame = view.bounds

        if isMirrored {
            view.previewLayer.setAffineTransform(CGAffineTransform(scaleX: -1, y: 1))
        } else {
            view.previewLayer.setAffineTransform(.identity)
        }
    }
}

// MARK: - Joint labels

private struct HandJointLabel: Hashable, CaseIterable {
    let name: VNHumanHandPoseObservation.JointName
    let label: String

    static let wrist = HandJointLabel(name: .wrist, label: "Wrist")
    static let thumbCMC = HandJointLabel(name: .thumbCMC, label: "Thumb CMC")
    static let thumbMP = HandJointLabel(name: .thumbMP, label: "Thumb MP")
    static let thumbIP = HandJointLabel(name: .thumbIP, label: "Thumb IP")
    static let thumbTip = HandJointLabel(name: .thumbTip, label: "Thumb Tip")
    static let indexMCP = HandJointLabel(name: .indexMCP, label: "Index MCP")
    static let indexPIP = HandJointLabel(name: .indexPIP, label: "Index PIP")
    static let indexDIP = HandJointLabel(name: .indexDIP, label: "Index DIP")
    static let indexTip = HandJointLabel(name: .indexTip, label: "Index Tip")
    static let middleMCP = HandJointLabel(name: .middleMCP, label: "Middle MCP")
    static let middlePIP = HandJointLabel(name: .middlePIP, label: "Middle PIP")
    static let middleDIP = HandJointLabel(name: .middleDIP, label: "Middle DIP")
    static let middleTip = HandJointLabel(name: .middleTip, label: "Middle Tip")
    static let ringMCP = HandJointLabel(name: .ringMCP, label: "Ring MCP")
    static let ringPIP = HandJointLabel(name: .ringPIP, label: "Ring PIP")
    static let ringDIP = HandJointLabel(name: .ringDIP, label: "Ring DIP")
    static let ringTip = HandJointLabel(name: .ringTip, label: "Ring Tip")
    static let littleMCP = HandJointLabel(name: .littleMCP, label: "Little MCP")
    static let littlePIP = HandJointLabel(name: .littlePIP, label: "Little PIP")
    static let littleDIP = HandJointLabel(name: .littleDIP, label: "Little DIP")
    static let littleTip = HandJointLabel(name: .littleTip, label: "Little Tip")

    static let allCases: [HandJointLabel] = [
        .wrist,
        .thumbCMC, .thumbMP, .thumbIP, .thumbTip,
        .indexMCP, .indexPIP, .indexDIP, .indexTip,
        .middleMCP, .middlePIP, .middleDIP, .middleTip,
        .ringMCP, .ringPIP, .ringDIP, .ringTip,
        .littleMCP, .littlePIP, .littleDIP, .littleTip
    ]
}

private struct BodyJointLabel: Hashable, CaseIterable {
    let name: VNHumanBodyPoseObservation.JointName
    let label: String

    static let leftShoulder = BodyJointLabel(name: .leftShoulder, label: "Left Shoulder")
    static let rightShoulder = BodyJointLabel(name: .rightShoulder, label: "Right Shoulder")
    static let leftElbow = BodyJointLabel(name: .leftElbow, label: "Left Elbow")
    static let rightElbow = BodyJointLabel(name: .rightElbow, label: "Right Elbow")

    static let allCases: [BodyJointLabel] = [
        .leftShoulder, .rightShoulder, .leftElbow, .rightElbow
    ]
}

#Preview {
    CameraView()
}
#endif
