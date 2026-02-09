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
    private let videoOutput = AVCaptureVideoDataOutput() // buffers video frames for the vision intelligence to use
    
    private let sessionQueue = DispatchQueue(label: "camera.session.queue") // run the camera on a background thread so it doesn't freeze UI
    
    // This closure will pass the vision observations back to your UI or Logic
    var onPoseDetected: (([VNHumanHandPoseObservation]) -> Void)?

    var isAuthorized = false

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
            connection.isVideoMirrored = true // Mirroring makes it feel natural for sign language practice
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
    // runs 30-60 times a second - every video frame processed here
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        autoreleasepool { // Free temporary Vision/CoreMedia objects each frame to prevent memory buildup
            let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:]) // creates a request handler
            
            let handPoseRequest = VNDetectHumanHandPoseRequest() // defines a hand pose request
            handPoseRequest.maximumHandCount = 2 // Focus on one hand for better performance initially

            do {
                try handler.perform([handPoseRequest]) // analyze the hand pose
                guard let observations = handPoseRequest.results else { return } // extract results
                
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
}
