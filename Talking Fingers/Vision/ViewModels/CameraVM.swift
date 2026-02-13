//
//  CameraViewModel.swift
//  Talking Fingers
//
//  Created by Jihoon Kim on 1/29/26.
//

import AVFoundation
import Vision
import CoreGraphics

@Observable
class CameraVM: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession() // connects camera hardware to the app
    private let videoOutput = AVCaptureVideoDataOutput() // buffers video frames for Vision

    private let sessionQueue = DispatchQueue(label: "camera.session.queue") // background camera thread

    // This closure will pass the vision observations and an accurate frame timestamp back to UI/Logic
    var onPoseDetected: (([VNHumanHandPoseObservation], CMTime) -> Void)?

    var isAuthorized = false

    // Track mirroring for correct left/right interpretation
    var isMirrored = true

    override init() {
        super.init()
    }

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

    private func setupSession() {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .hd1280x720

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }

        // Cap frame rate to 24 fps
        do {
            try videoDevice.lockForConfiguration()
            videoDevice.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 24)
            videoDevice.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 24)
            videoDevice.unlockForConfiguration()
        } catch {
            print("Could not configure frame rate: \(error)")
        }

        if session.canAddInput(videoInput) { session.addInput(videoInput) }

        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ]
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "video.output.queue"))
        if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }

        if let connection = videoOutput.connection(with: .video) {
            connection.videoOrientation = .portrait
            connection.isVideoMirrored = self.isMirrored
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

    // Vision + camera frame processing
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        autoreleasepool {
            let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

            let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])

            let handPoseRequest = VNDetectHumanHandPoseRequest()
            handPoseRequest.maximumHandCount = 2

            do {
                try handler.perform([handPoseRequest])
                let observations = handPoseRequest.results ?? []

                DispatchQueue.main.async {
                    self.onPoseDetected?(observations, pts)
                }
            } catch {
                print("Vision error: \(error)")
            }
        }
    }

    func convertVisionPointToScreenPosition(visionPoint: CGPoint, viewSize: CGSize) -> CGPoint {
        let x = visionPoint.x * viewSize.width
        let y = (1 - visionPoint.y) * viewSize.height
        return CGPoint(x: x, y: y)
    }

    // Filter frames (kept from main)
    func filterReferences(for references: [(TimeInterval, VNHumanHandPoseObservation)]) -> [(TimeInterval, VNHumanHandPoseObservation)] {
        return references.filter({ t -> Bool in
            guard let allPoints = try? t.1.recognizedPoints(.all) else {
                return false
            }

            let joints = allPoints.values.filter { $0.confidence > 0.3 }

            guard joints.count >= 12 else {
                return false
            }

            return joints.reduce(0) { $0 + $1.confidence } / Float(joints.count) >= 0.7
        })
    }

    // MARK: - Scale invariance / normalization (added)

    struct NormalizedHand {
        /// Points normalized into a standard unit bounding box [0,1]x[0,1]
        let unitPoints: [VNHumanHandPoseObservation.JointName: CGPoint]

        /// Bounding box in Vision normalized image coords (0..1)
        let rawBounds: CGRect

        /// Uniform scale applied (1 / max(width,height))
        let scale: CGFloat

        /// Translation applied before scale (subtracting minX/minY)
        let translation: CGPoint

        /// Optional padding to center the scaled hand within the unit box
        let padding: CGPoint
    }

    /// Normalize landmarks so the hand fits into a standard unit bounding box.
    /// This does NOT affect the on-screen overlay; use for recognition/features/debugging.
    func normalizeHandToUnitBox(
        hand: VNHumanHandPoseObservation,
        joints: [VNHumanHandPoseObservation.JointName],
        minConfidence: Float = 0.5,
        centerInBox: Bool = true
    ) -> NormalizedHand? {

        // 1) Gather reliable landmarks in Vision normalized coordinates (0..1)
        var raw: [VNHumanHandPoseObservation.JointName: CGPoint] = [:]
        raw.reserveCapacity(joints.count)

        for j in joints {
            guard let p = try? hand.recognizedPoint(j),
                  p.confidence >= minConfidence else { continue }
            raw[j] = p.location
        }

        guard raw.count >= 3 else { return nil }

        // 2) Compute bounding box
        let xs = raw.values.map { $0.x }
        let ys = raw.values.map { $0.y }
        guard let minX = xs.min(), let maxX = xs.max(),
              let minY = ys.min(), let maxY = ys.max() else { return nil }

        let width = max(maxX - minX, 1e-6)
        let height = max(maxY - minY, 1e-6)
        let bounds = CGRect(x: minX, y: minY, width: width, height: height)

        // 3) Translate to origin, 4) uniform scale to fit inside 1x1
        let s = 1.0 / max(width, height)
        let translation = CGPoint(x: -minX, y: -minY)

        // 5) optional centering padding
        let scaledW = width * s
        let scaledH = height * s
        let padding = centerInBox
        ? CGPoint(x: (1 - scaledW) * 0.5, y: (1 - scaledH) * 0.5)
        : .zero

        var unit: [VNHumanHandPoseObservation.JointName: CGPoint] = [:]
        unit.reserveCapacity(raw.count)

        for (j, p) in raw {
            let ux = (p.x + translation.x) * s + padding.x
            let uy = (p.y + translation.y) * s + padding.y
            unit[j] = CGPoint(x: ux, y: uy)
        }

        return NormalizedHand(unitPoints: unit, rawBounds: bounds, scale: s, translation: translation, padding: padding)
    }
}
