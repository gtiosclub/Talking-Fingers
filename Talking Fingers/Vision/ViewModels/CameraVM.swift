//
//  CameraViewModel.swift
//  Talking Fingers
//
//  Created by Jihoon Kim on 1/29/26.
//

import AVFoundation
import Vision
import Foundation
import CoreGraphics

@Observable
class CameraVM: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession() // connects camera hardware to the app
    private let videoOutput = AVCaptureVideoDataOutput() // buffers video frames for the vision intelligence to use
    
    private let sessionQueue = DispatchQueue(label: "camera.session.queue") // run the camera on a background thread so it doesn't freeze UI
    
    // This closure will pass the vision observations and the sample buffer back to your UI or Logic
    // The sample buffer is provided so callers can derive an accurate `CMTime` timestamp.
    var onPoseDetected: (([VNHumanHandPoseObservation], CMTime) -> Void)?

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
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
        
        // Cap frame rate to 24 fps to balance memory/CPU with the higher resolution
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
        
        // Ensure orientation is correct for the front camera
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

    // THIS IS THE BRAIN: Where Vision meets the Camera
    // runs 24 times a second - every video frame processed here
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
    
    // Filter frames
    func filterReferences(for references: [(TimeInterval, VNHumanHandPoseObservation)]) -> [(TimeInterval, VNHumanHandPoseObservation)] {
        return references.filter({ t -> Bool in
            guard let allPoints = try? t.1.recognizedPoints(.all) else {
                return false
            }
            
            let joints = allPoints.values.filter { $0.confidence > 0.3 }
            guard joints.count >= 12 else { return false }

            return joints.reduce(0) { $0 + $1.confidence } / Float(joints.count) >= 0.7
        })
    }

    // MARK: - JSON reference saving (append)

    struct ReferenceJoint: Codable {
        let x: Double
        let y: Double
        let confidence: Double
    }

    struct ReferenceFrame: Codable {
        let timestamp: Double
        let chirality: String?
        let joints: [String: ReferenceJoint]
    }

    /// Convert a Vision point key into a stable String id.
    /// Some SDKs don't expose `rawValue` publicly, so we extract the internal "_rawValue".
    private func pointKeyString(_ key: VNRecognizedPointKey) -> String {
        let mirror = Mirror(reflecting: key)
        if let raw = mirror.children.first(where: { $0.label == "_rawValue" })?.value as? String {
            return raw
        }
        return String(describing: key)
    }

    /// Takes filtered references, converts them to JSON-friendly data, and appends to:
    /// Application Support/Models/references.json
    ///
    /// - If the file doesn't exist or is empty: writes a new JSON array.
    /// - If the file exists and has data: appends to the existing JSON array.
    func appendReferencesToJSON(filtered: [(TimeInterval, VNHumanHandPoseObservation)]) {
        guard !filtered.isEmpty else {
            print("appendReferencesToJSON: nothing to write")
            return
        }

        do {
            let newFrames: [ReferenceFrame] = filtered.compactMap { (t, obs) in
                guard let points = try? obs.recognizedPoints(.all) else { return nil }

                var joints: [String: ReferenceJoint] = [:]
                joints.reserveCapacity(points.count)

                for (jointKey, rp) in points {
                    let keyString = pointKeyString(jointKey.rawValue)
                    joints[keyString] = ReferenceJoint(
                        x: Double(rp.location.x),
                        y: Double(rp.location.y),
                        confidence: Double(rp.confidence)
                    )
                }

                let chiralityString: String?
                if #available(iOS 14.0, *) {
                    chiralityString = (obs.chirality == .left) ? "left" : "right"
                } else {
                    chiralityString = nil
                }

                return ReferenceFrame(timestamp: t, chirality: chiralityString, joints: joints)
            }

            guard !newFrames.isEmpty else {
                print("appendReferencesToJSON: could not convert frames")
                return
            }

            let fileURL = try referencesFileURL()

            // Load existing array if present & non-empty
            var allFrames: [ReferenceFrame] = []
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let existingData = try Data(contentsOf: fileURL)
                if !existingData.isEmpty,
                   let decoded = try? JSONDecoder().decode([ReferenceFrame].self, from: existingData) {
                    allFrames = decoded
                }
            }

            allFrames.append(contentsOf: newFrames)

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let outData = try encoder.encode(allFrames)

            try outData.write(to: fileURL, options: [.atomic])

            print("Saved \(newFrames.count) frames (total \(allFrames.count)) to \(fileURL.path)")
        } catch {
            print("appendReferencesToJSON error: \(error)")
        }
    }

    private func referencesFileURL() throws -> URL {
        let fm = FileManager.default
        let appSupport = try fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let modelsDir = appSupport.appendingPathComponent("Models", isDirectory: true)
        if !fm.fileExists(atPath: modelsDir.path) {
            try fm.createDirectory(at: modelsDir, withIntermediateDirectories: true)
        }

        return modelsDir.appendingPathComponent("references.json")
    }
}
