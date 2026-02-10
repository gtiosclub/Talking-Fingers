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
    private let videoOutput = AVCaptureVideoDataOutput() // buffers video frames for the vision intelligence to use

    private let sessionQueue = DispatchQueue(label: "camera.session.queue") // run the camera on a background thread so it doesn't freeze UI

    // This closure will pass the vision observations back to your UI or Logic
    var onPoseDetected: (([VNHumanHandPoseObservation]) -> Void)?

    var isAuthorized = false

    // Add to keep track of observations relative to camera
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
        defer { session.commitConfiguration() } // Always commit, even on early return

        session.sessionPreset = .hd1280x720 // 720p — clear preview without the memory cost of full 1080p

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front), // choose front facing camera
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }

        // Cap frame rate to 24 fps to balance memory/CPU with the higher resolution
        do {
            try videoDevice.lockForConfiguration()
            videoDevice.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 24) // min = 24 fps
            videoDevice.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 24) // max = 24 fps
            videoDevice.unlockForConfiguration()
        } catch {
            print("Could not configure frame rate: \(error)")
        }

        if session.canAddInput(videoInput) { session.addInput(videoInput) } // connect the camera input to the session

        videoOutput.alwaysDiscardsLateVideoFrames = true // Drop frames if processing can't keep up, prevents memory buildup
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] // Efficient pixel format
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "video.output.queue")) // process frames from the camera
        if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) } // output video output

        // Ensure orientation is correct for the front camera
        if let connection = videoOutput.connection(with: .video) {
            connection.videoOrientation = .portrait
            connection.isVideoMirrored = self.isMirrored // Mirroring makes it feel natural for sign language practice
        }
    }

    func start() {
        sessionQueue.async {
            // Wait for authorization
            guard self.isAuthorized else { return }

            // 1. Configure if needed
            if self.session.inputs.isEmpty {
                self.setupSession()
            }

            // 2. Start only if not already running
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

    // THIS IS THE BRAIN: Where Vision meets the Camera
    // runs 24 times a second - every video frame processed here
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        autoreleasepool { // Free temporary Vision/CoreMedia objects each frame to prevent memory buildup
            let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:]) // creates a request handler

            let handPoseRequest = VNDetectHumanHandPoseRequest() // defines a hand pose request
            handPoseRequest.maximumHandCount = 2 // Two hands

            do {
                try handler.perform([handPoseRequest]) // analyze the hand pose
                let observations = handPoseRequest.results ?? [] // extract results

                // Send the hand landmarks back to the main thread for UI/Logic
                DispatchQueue.main.async {
                    self.onPoseDetected?(observations)
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

    // MARK: - Scale invariance / normalization

    struct NormalizedHand {
        /// Points normalized into a standard unit bounding box [0,1]x[0,1]
        /// (independent of how large the hand appears in the camera frame)
        let unitPoints: [VNHumanHandPoseObservation.JointName: CGPoint]

        /// Bounding box in *Vision normalized image coords* (0..1)
        let rawBounds: CGRect

        /// Uniform scale applied (1 / max(width,height))
        let scale: CGFloat

        /// Translation applied before scale (i.e., subtracting minX/minY)
        let translation: CGPoint

        /// Optional padding to center the scaled hand within the unit box
        let padding: CGPoint
    }

    /// Scale/translation normalize all landmarks so the hand fits into a standard unit bounding box.
    /// - Important: This does NOT change your overlay rendering. Use this for recognition/features/training.
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

        // Need enough points to form a meaningful box
        guard raw.count >= 3 else { return nil }

        // 2) Compute bounding box in Vision normalized space
        let xs = raw.values.map { $0.x }
        let ys = raw.values.map { $0.y }
        guard let minX = xs.min(), let maxX = xs.max(),
              let minY = ys.min(), let maxY = ys.max() else { return nil }

        let width = max(maxX - minX, 1e-6)
        let height = max(maxY - minY, 1e-6)
        let bounds = CGRect(x: minX, y: minY, width: width, height: height)

        // 3) Translate box origin to (0,0), 4) uniformly scale to fit inside 1x1
        let s = 1.0 / max(width, height)
        let translation = CGPoint(x: -minX, y: -minY)

        // 5) Optional centering padding so it sits in the middle of the unit box
        let scaledW = width * s
        let scaledH = height * s
        let padding = centerInBox ? CGPoint(x: (1 - scaledW) * 0.5, y: (1 - scaledH) * 0.5) : .zero

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
