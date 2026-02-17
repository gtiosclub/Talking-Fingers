//
//  CameraViewModel.swift
//  Talking Fingers
//
//  Created by Jihoon Kim on 1/29/26.
//
import AVFoundation
import Vision

@Observable
class CameraVM: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    let session = AVCaptureSession() // connects camera hardware to the app
    private let videoOutput = AVCaptureVideoDataOutput() // buffers video frames for vision

    private let sessionQueue = DispatchQueue(label: "camera.session.queue") // run camera on background thread

    // --- Recording Logic (from main) ---
    var isRecording = false
    private(set) var recordedFrames: [SignFrame] = []
    var recordingStartTime: CMTime? = nil

    // --- Callbacks ---
    // Keep main signature so merge works with main as-is
    var onPoseDetected: (([VNHumanHandPoseObservation], CMTime) -> Void)?

    // Additive callback for body pose (doesn't break main)
    var onBodyPoseDetected: (([VNHumanBodyPoseObservation], CMTime) -> Void)?

    var isAuthorized = false

    // Track mirroring so overlays can align with preview when needed
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

        session.sessionPreset = .hd1280x720 // 720p

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                       for: .video,
                                                       position: .front),
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
            kCVPixelBufferPixelFormatTypeKey as String:
                kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
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
   

    // --- Recording controls (from main) ---
    func toggleRecording() {
        if isRecording {
            isRecording = false
            let filtered = filterFrames(recordedFrames)
            recordedFrames = filtered
            print("Filtered and saved \(recordedFrames.count) frames")
        } else {
            recordedFrames.removeAll(keepingCapacity: true)
            recordingStartTime = nil
            isRecording = true
        }
    }

    func clearBuffer() {
        recordedFrames.removeAll(keepingCapacity: true)
        recordingStartTime = nil
    }

    // THIS IS THE BRAIN: Vision + Camera
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {

        autoreleasepool {
            let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

            let handler = VNImageRequestHandler(
                cmSampleBuffer: sampleBuffer,
                orientation: .up,
                options: [:]
            )

            let handPoseRequest = VNDetectHumanHandPoseRequest()
            handPoseRequest.maximumHandCount = 2

            let bodyPoseRequest = VNDetectHumanBodyPoseRequest()

            do {
                try handler.perform([handPoseRequest, bodyPoseRequest])

                let handObservations = handPoseRequest.results ?? []
                let bodyObservations = bodyPoseRequest.results ?? []

                DispatchQueue.main.async {
                    // Keep main behavior
                    self.onPoseDetected?(handObservations, pts)

                    // New body callback (for overlays/labels)
                    self.onBodyPoseDetected?(bodyObservations, pts)

                    // Recording still uses hand observations (matches main)
                    if self.isRecording {
                        if self.recordingStartTime == nil { self.recordingStartTime = pts }
                        for observation in handObservations {
                            let frame = SignFrame(from: observation, at: pts)
                            self.recordedFrames.append(frame)
                        }
                    }
                }
            } catch {
                print("Vision error: \(error)")
            }
        }
    }

    // NOTE: Kept identical to main for merge safety.
    // If your overlays look horizontally flipped when mirrored,
    // update this later in a separate PR (since it changes behavior).
    func convertVisionPointToScreenPosition(visionPoint: CGPoint, viewSize: CGSize) -> CGPoint {
        let x = visionPoint.x * viewSize.width
        let y = (1 - visionPoint.y) * viewSize.height
        return CGPoint(x: x, y: y)
    }
    
    func filterFrames(_ frames: [SignFrame]) -> [SignFrame] {
        return frames.filter { frame in
            guard frame.joints.count >= 12 else { return false }
            
            let avgConfidence = frame.joints.reduce(0) { $0 + $1.confidence } / Float(frame.joints.count)
            return avgConfidence >= 0.7
        }
    }
}
