//
//  CameraViewModel.swift
//  Talking Fingers
//
//  Created by Jihoon Kim on 1/29/26.
//

import AVFoundation
import Vision
import CoreMotion

@Observable
class CameraVM: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession() // connects camera hardware to the app
    private let videoOutput = AVCaptureVideoDataOutput() // buffers video frames for the vision intelligence to use
    private let sessionQueue = DispatchQueue(label: "camera.session.queue") // run the camera on a background thread so it doesn't freeze UI
    
    // Keep track of normalized hand observations
    var normalizedHands: [NormalizedHand] = []
    // This closure will pass the vision observations and the sample buffer back to your UI or Logic
    // The sample buffer is provided so callers can derive an accurate `CMTime` timestamp.
    var onPoseDetected: (([VNHumanHandPoseObservation], CMTime) -> Void)?

    var isAuthorized = false
    
    // Add to keep track of observations relative to camera
    var isMirrored = true

    private let motionManager = CMMotionManager()
    var currentPitch: Double = 0.0
    
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
        self.startMotionUpdates()
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
        self.stopMotionUpdates()
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
    
    func startMotionUpdates() {
            guard motionManager.isDeviceMotionAvailable else { return }
            
            motionManager.deviceMotionUpdateInterval = 1.0 / 24.0 // Match your camera FPS
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
                guard let motion = motion else { return }
                
                // In Portrait orientation:
                // Pitch is the rotation around the X-axis (tilting the top of the phone toward/away from you)
                self?.currentPitch = motion.attitude.pitch
            }
        }

    func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }

    // THIS IS THE BRAIN: Where Vision meets the Camera
    // runs 24 times a second - every video frame processed here
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        autoreleasepool { // Free temporary Vision/CoreMedia objects each frame to prevent memory buildup
            let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            
            let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:]) // creates a request handler
            
            let handPoseRequest = VNDetectHumanHandPoseRequest() // defines a hand pose request
            handPoseRequest.maximumHandCount = 2 // Two hands

            do {
                try handler.perform([handPoseRequest]) // analyze the hand pose
                let observations = handPoseRequest.results ?? [] // extract results
                
                // Send the hand landmarks and sample buffer back to the main thread for UI/Logic
                DispatchQueue.main.async {
                    self.onPoseDetected?(observations, pts)
                    self.normalizedHands = observations.compactMap { NormalizedHand(from: $0, pitch: self.currentPitch - (.pi / 2)) }
                    
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
    
    // Filter frames
    func filterReferences(for references: [(TimeInterval, VNHumanHandPoseObservation)]) -> [(TimeInterval, VNHumanHandPoseObservation)] {
        return references.filter({t -> Bool in
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
}
