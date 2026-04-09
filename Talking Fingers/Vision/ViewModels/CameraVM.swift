//
//  CameraViewModel.swift
//  Talking Fingers
//
//  Created by Jihoon Kim on 1/29/26.
//

import AVFoundation
import Vision
import Foundation
#if os(iOS)
import CoreMotion
#endif
import CoreGraphics

@Observable
class CameraVM: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    let session = AVCaptureSession() // connects camera hardware to the app
    private let videoOutput = AVCaptureVideoDataOutput() // buffers video frames for the vision intelligence to use
    private let sessionQueue = DispatchQueue(label: "camera.session.queue") // run the camera on a background thread so it doesn't freeze UI
    
    // Keep track of normalized hand observations
    var normalizedHands: [NormalizedHandModel] = []
    
    // --- Recording Logic ---
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
    
    // MARK: - Sign recognition
    var frameBuffer: SignReference = SignReference()
    private let dtwEngine = DTWService()
    var lastScore = 30.0
    private var frameCounter = 0
    private let stride = 12 // Run DTW every 4th frame
    private let maxBufferSize = 75 // ~3 seconds of
    private var currentSignReference: SignReference?
    private var currentSignFrame: SignFrame?

    // MARK: - Comparison mode
    var isComparing = false
    var confidenceScore: Double = 0.0
    private var comparisonReference: SignReference?
    private var smoothedConfidence: Double = 0.0
    private let smoothingFactor: Double = 0.3

    #if os(iOS)
    private let motionManager = CMMotionManager()
    private let staticScoreDecay: Double = 3.0
    private let displayMultiplier: Double = 1.3
    private let smoothingAlpha: Double = 0.3
    #else
    private let staticScoreDecay: Double = 2.1
    private let displayMultiplier: Double = 1.45
    private let smoothingAlpha: Double = 0.45
    #endif

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
        
        // Ensure orientation is correct for the front camera
        if let connection = videoOutput.connection(with: .video) {
            #if os(iOS)
            connection.videoOrientation = .portrait
            #else
            connection.videoRotationAngle = 0
            #endif
            connection.isVideoMirrored = self.isMirrored
        }
    }

    func start() {
        self.startMotionUpdates()
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
        self.stopMotionUpdates()
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
    
    func startMotionUpdates() {
        #if os(iOS)
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 24.0 // Match your camera FPS
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let motion = motion else { return }
            self?.currentPitch = motion.attitude.pitch
        }
        #else
        // macOS: No motion tracking available
        currentPitch = 0.0
        #endif
    }

    func stopMotionUpdates() {
        #if os(iOS)
        motionManager.stopDeviceMotionUpdates()
        #endif
    }

    func toggleRecording() {
        if isRecording {
            isRecording = false
            recordedFrames = filterFrames(recordedFrames)
            print("Filtered recording: \(recordedFrames.count) frames")
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

    // MARK: - Static sign comparison

    func startComparing(forSign signName: String) {
        let normalizedName = signName.lowercased().trimmingCharacters(in: .whitespaces)
        guard !normalizedName.isEmpty else { return }
        do {
            let refs = try loadSignReferences(forSign: normalizedName)
            comparisonReference = refs.first
            isComparing = comparisonReference != nil
            if !isComparing { confidenceScore = 0 }
            smoothedConfidence = 0
            frameBuffer.frames.removeAll()
            frameCounter = 0
        } catch {
            print("Failed to load reference for '\(normalizedName)': \(error)")
            stopComparing()
        }
    }

    func stopComparing() {
        isComparing = false
        comparisonReference = nil
        confidenceScore = 0
        smoothedConfidence = 0
        frameBuffer.frames.removeAll()
        frameCounter = 0
    }

    private func swappedHandKey(_ key: String) -> String? {
        if key.hasPrefix("leftVNHLK") {
            return "right" + String(key.dropFirst(4))
        }
        if key.hasPrefix("rightVNHLK") {
            return "left" + String(key.dropFirst(5))
        }
        return nil
    }

    private func jointWeight(for key: String) -> Double {
        #if os(macOS)
        // More tolerant on macOS where occlusion/jitter is worse
        if key.hasSuffix("WRI") { return 1.8 }
        if key.hasSuffix("CMC") { return 1.4 }
        if key.hasSuffix("MCP") { return 1.35 }
        if key.hasSuffix("PIP") { return 1.1 }
        if key.hasSuffix("IP")  { return 1.0 }
        if key.hasSuffix("DIP") { return 0.7 }
        if key.hasSuffix("TIP") { return 0.45 }
        #else
        // Closer to original stricter weighting on iOS
        if key.hasSuffix("WRI") { return 1.5 }
        if key.hasSuffix("MCP") { return 1.3 }
        if key.hasSuffix("PIP") { return 1.1 }
        if key.hasSuffix("DIP") { return 1.0 }
        if key.hasSuffix("TIP") { return 0.9 }
        #endif

        return 1.0
    }

    private func scoreMatchedPairs(
        live: SignFrame,
        reference: SignFrame,
        swapLiveHandPrefixes: Bool
    ) -> Double {
        let liveJoints = live.joints
        let refJoints = reference.joints

        var matchedLive: [(x: Double, y: Double, w: Double)] = []
        var matchedRef: [(x: Double, y: Double, w: Double)] = []

        for (key, refJoint) in refJoints {
            guard key.contains("VNHLK") else { continue }

            #if os(macOS)
            guard refJoint.confidence > 0.2 else { continue }
            #else
            guard refJoint.confidence > 0.3 else { continue }
            #endif

            let liveKey: String
            if swapLiveHandPrefixes, let swapped = swappedHandKey(key) {
                liveKey = swapped
            } else {
                liveKey = key
            }

            guard let liveJoint = liveJoints[liveKey] else { continue }

            #if os(macOS)
            guard liveJoint.confidence > 0.2 else { continue }
            #else
            guard liveJoint.confidence > 0.3 else { continue }
            #endif

            let w = jointWeight(for: key)

            matchedLive.append((x: liveJoint.x, y: liveJoint.y, w: w))
            matchedRef.append((x: refJoint.x, y: refJoint.y, w: w))
        }

        guard matchedLive.count >= 5 else { return 0 }

        let totalWeight = matchedLive.reduce(0.0) { $0 + $1.w }
        guard totalWeight > 0 else { return 0 }

        let liveCx = matchedLive.reduce(0.0) { $0 + $1.x * $1.w } / totalWeight
        let liveCy = matchedLive.reduce(0.0) { $0 + $1.y * $1.w } / totalWeight
        let refCx = matchedRef.reduce(0.0) { $0 + $1.x * $1.w } / totalWeight
        let refCy = matchedRef.reduce(0.0) { $0 + $1.y * $1.w } / totalWeight

        let liveScale = max(
            matchedLive.reduce(0.0) { acc, p in
                max(acc, hypot(p.x - liveCx, p.y - liveCy))
            },
            1e-6
        )

        let refScale = max(
            matchedRef.reduce(0.0) { acc, p in
                max(acc, hypot(p.x - refCx, p.y - refCy))
            },
            1e-6
        )

        var weightedDist = 0.0
        var usedWeight = 0.0

        for i in 0..<matchedLive.count {
            let lx = (matchedLive[i].x - liveCx) / liveScale
            let ly = (matchedLive[i].y - liveCy) / liveScale
            let rx = (matchedRef[i].x - refCx) / refScale
            let ry = (matchedRef[i].y - refCy) / refScale

            let w = matchedLive[i].w
            weightedDist += hypot(lx - rx, ly - ry) * w
            usedWeight += w
        }

        guard usedWeight > 0 else { return 0 }

        let avgDist = weightedDist / usedWeight
        return max(0, min(100, 100.0 * exp(-staticScoreDecay * avgDist)))
    }

    /// Compares hand joints between a live frame and a reference frame using
    /// centroid + scale normalization for translation/scale invariance.
    /// Returns a confidence percentage 0–100.
    ///
    /// Important:
    /// We score both the direct handedness match and a left/right-swapped match,
    /// then take the better one. This makes static comparison robust to
    /// front-camera mirrored chirality differences between recorded references
    /// and live frames, especially on macOS.
    func compareStaticFrames(live: SignFrame, reference: SignFrame) -> Double {
        let directScore = scoreMatchedPairs(
            live: live,
            reference: reference,
            swapLiveHandPrefixes: false
        )

        let swappedScore = scoreMatchedPairs(
            live: live,
            reference: reference,
            swapLiveHandPrefixes: true
        )

        return max(directScore, swappedScore)
    }

    // THIS IS THE BRAIN: Where Vision meets the Camera
    // runs 24 times a second - every video frame processed here
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
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
                
                let primaryBody = bodyObservations.first

                DispatchQueue.main.async {
                    self.onPoseDetected?(handObservations, pts)
                    self.onBodyPoseDetected?(bodyObservations, pts)
                    
                    // Do something with score
                    self.processFrame(body: primaryBody, hands: handObservations, pitch: self.currentPitch, timestamp: pts)
                    

                    // Existing pitch-correction normalization (this is not the scale-invariance unit-box normalization)
                    self.normalizedHands = handObservations.compactMap {
                        NormalizedHandModel(from: $0, pitch: self.currentPitch - (.pi / 2))
                    }

                    // New body callback (for overlays/labels)
                    self.onBodyPoseDetected?(bodyObservations, pts)

                    if self.isRecording {
                        if self.recordingStartTime == nil { self.recordingStartTime = pts }

                        let frame = SignFrame(
                            body: primaryBody,
                            hands: handObservations,
                            at: pts
                        )

                        self.recordedFrames.append(frame)
                    }
                }
            } catch {
                print("Vision error: \(error)")
            }
        }
    }
    
    func createSignFrame(body: VNHumanBodyPoseObservation?, hands: [VNHumanHandPoseObservation], at timestamp: CMTime) -> SignFrame {
        let current = SignFrame(
            body: body,
            hands: hands,
            at: timestamp
        )
        
        currentSignFrame = current
        return current
    }
    
    // MARK: - Processing Frames
    func processFrame(body: VNHumanBodyPoseObservation?, hands: [VNHumanHandPoseObservation], pitch: Double, timestamp: CMTime) {

        let currentFrame = createSignFrame(body: body, hands: hands, at: timestamp)

        if isComparing, let ref = comparisonReference {
            if ref.signType == .static, let refFrame = ref.frames.first {
                let rawScore = compareStaticFrames(live: currentFrame, reference: refFrame)
                let displayed = min(100, rawScore * displayMultiplier)
                smoothedConfidence = smoothedConfidence * (1 - smoothingAlpha) + displayed * smoothingAlpha
                confidenceScore = smoothedConfidence
                return
            }

            if ref.signType == .dynamic {
                frameBuffer.frames.append(currentFrame)
                if frameBuffer.frames.count > maxBufferSize {
                    frameBuffer.frames.removeFirst()
                }

                frameCounter += 1
                guard frameCounter % stride == 0 else { return }

                let dtwScore = dtwEngine.computeDTW(buffer: frameBuffer, template: ref)
                let rawScore = dtwScore.isFinite ? max(0, min(100, 100.0 * exp(-3.0 * dtwScore))) : 0
                let displayed = min(100, rawScore * 1.5)
                smoothedConfidence = smoothedConfidence * (1 - smoothingFactor) + displayed * smoothingFactor
                confidenceScore = smoothedConfidence
                return
            }
        }

        self.frameBuffer.frames.append(currentFrame)
        if self.frameBuffer.frames.count > maxBufferSize {
            self.frameBuffer.frames.removeFirst()
        }

        self.frameCounter += 1
        guard self.frameCounter % stride == 0 else { return }

        let score = dtwEngine.computeDTW(
            buffer: frameBuffer,
            template: currentSignReference ?? SignReference()
        )

        lastScore = score
    }

    func convertVisionPointToScreenPosition(visionPoint: CGPoint, viewSize: CGSize) -> CGPoint {
        #if os(macOS)
        // Match AVCaptureVideoPreviewLayer(videoGravity: .resizeAspectFill)
        // on macOS, where the camera buffer is 1280x720 landscape.
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
        #else
        let x = visionPoint.x * viewSize.width
        let y = (1 - visionPoint.y) * viewSize.height
        return CGPoint(x: x, y: y)
        #endif
    }
    
    // Returns translated list that treats some anchor joint (e.g. wrist) as the origin (0,0)
    // and the locations of every other joint relative to it.
    func convertAbsolutePointsToRelativePoints(
        _ hand: VNHumanHandPoseObservation,
        joints: [VNHumanHandPoseObservation.JointName],
        anchor: VNHumanHandPoseObservation.JointName = .wrist,
        minConf: Float = 0.5
    ) -> [CGPoint]? {
        guard
            let a = try? hand.recognizedPoint(anchor),
            a.confidence >= minConf
        else { return nil }

        var rel: [CGPoint] = []
        rel.reserveCapacity(joints.count)

        for j in joints {
            guard let p = try? hand.recognizedPoint(j), p.confidence >= minConf else { return nil }
            rel.append(CGPoint(x: p.location.x - a.location.x,
                               y: p.location.y - a.location.y))
        }
        return rel
    }

    /// Returns body joints (shoulders + elbows) normalized relative to the body center,
    /// defined as the midpoint of both shoulders (body center = 0,0).
    func convertBodyPointsToRelativePoints(
        _ body: VNHumanBodyPoseObservation,
        joints: [VNHumanBodyPoseObservation.JointName] = [.leftShoulder, .rightShoulder, .leftElbow, .rightElbow],
        minConf: Float = 0.3
    ) -> [VNHumanBodyPoseObservation.JointName: CGPoint]? {
        guard let ls = try? body.recognizedPoint(.leftShoulder),
              let rs = try? body.recognizedPoint(.rightShoulder),
              ls.confidence >= minConf,
              rs.confidence >= minConf
        else { return nil }

        let centerX = (ls.location.x + rs.location.x) / 2
        let centerY = (ls.location.y + rs.location.y) / 2

        var rel: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        for j in joints {
            guard let p = try? body.recognizedPoint(j), p.confidence >= minConf else { continue }
            rel[j] = CGPoint(x: p.location.x - centerX, y: p.location.y - centerY)
        }

        return rel.isEmpty ? nil : rel
    }
    
    /// Removes all frames that were recorded after `cutoff`.
    /// Call this before `filterFrames` / `filterReferences` to discard the
    /// trailing grace-period where hands were no longer visible.
    func trimFrames(after cutoff: CMTime) {
        recordedFrames.removeAll { $0.timestamp > cutoff }
    }

    // Filter frames (SignFrame-based)
    // Relaxed thresholds (8 joints, 0.6 confidence) to support difficult hand shapes
    // like "m" where fingers touching can reduce Vision's joint detection.
    func filterFrames(_ frames: [SignFrame]) -> [SignFrame] {
        let requiredJoints = 8
        let minConfidence: Float = 0.6

        return frames.filter { frame in
            let leftHandCount = frame.joints.keys.filter { $0.hasPrefix("left") && !$0.contains("Shoulder") && !$0.contains("Elbow") }.count
            let rightHandCount = frame.joints.keys.filter { $0.hasPrefix("right") && !$0.contains("Shoulder") && !$0.contains("Elbow") }.count

            guard leftHandCount >= requiredJoints || rightHandCount >= requiredJoints else { return false }

            let totalConfidence = frame.joints.values.reduce(0) { $0 + $1.confidence }
            let avgConfidence = totalConfidence / Float(frame.joints.count)

            return avgConfidence >= minConfidence
        }
    }
    
    // MARK: - Scale invariance / unit-box normalization (SignFrame ONLY)

    struct NormalizedHand {
        /// Points normalized into a standard unit bounding box [0,1]x[0,1]
        /// keyed by SignFrame's joint name strings.
        let unitPoints: [String: CGPoint]

        /// Bounding box in Vision normalized image coords (0..1)
        let rawBounds: CGRect

        /// Uniform scale applied (1 / max(width,height))
        let scale: CGFloat

        /// Translation applied before scale (subtracting minX/minY)
        let translation: CGPoint
        
        /// Optional padding to center the scaled hand within the unit box
        let padding: CGPoint
    }

    /// Same name as the original normalization API, but now purely SignFrame-based.
    /// This normalizes the hand so it always fits within a standard unit bounding box,
    /// regardless of how large the hand appears in the camera frame.
    func normalizeHandToUnitBox(
        hand: SignFrame,
        minConfidence: Float = 0.5,
        centerInBox: Bool = true
    ) -> NormalizedHand? {

        // 1) Gather reliable landmarks in Vision normalized coordinates (0..1)
        var raw: [String: CGPoint] = [:]
        raw.reserveCapacity(hand.joints.count)

        for (name, j) in hand.joints {
            guard j.confidence >= minConfidence else { continue }
            raw[name] = CGPoint(x: j.x, y: j.y)
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

        var unit: [String: CGPoint] = [:]
        unit.reserveCapacity(raw.count)

        for (name, p) in raw {
            let ux = (p.x + translation.x) * s + padding.x
            let uy = (p.y + translation.y) * s + padding.y
            unit[name] = CGPoint(x: ux, y: uy)
        }

        return NormalizedHand(
            unitPoints: unit,
            rawBounds: bounds,
            scale: s,
            translation: translation,
            padding: padding
        )
    }

    // MARK: - Per-sign reference storage (Vision/References/<signName>.json)

    /// In DEBUG builds, derives the repo's Vision/References/ path from this
    /// source file's compile-time location so JSONs land directly in the repo.
    /// Falls back to Documents/References/ on device (where the repo path
    /// doesn't exist on the filesystem).
    private func referencesDirectoryURL(sourceFile: String = #filePath) throws -> URL {
        let fm = FileManager.default

        #if DEBUG
        // CameraVM.swift lives at .../Vision/ViewModels/CameraVM.swift
        // Go up 2 levels → .../Vision/, then append References/
        let visionDir = URL(fileURLWithPath: sourceFile)
            .deletingLastPathComponent()  // ViewModels/
            .deletingLastPathComponent()  // Vision/
        let repoDir = visionDir.appendingPathComponent("References", isDirectory: true)

        if fm.isWritableFile(atPath: visionDir.path) {
            if !fm.fileExists(atPath: repoDir.path) {
                try fm.createDirectory(at: repoDir, withIntermediateDirectories: true)
            }
            return repoDir
        }
        #endif

        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fallback = docs.appendingPathComponent("References", isDirectory: true)
        if !fm.fileExists(atPath: fallback.path) {
            try fm.createDirectory(at: fallback, withIntermediateDirectories: true)
        }
        return fallback
    }

    private func signFileURL(forSign signName: String) throws -> URL {
        let dir = try referencesDirectoryURL()
        return dir.appendingPathComponent("\(signName).json")
    }

    /// Saves a single SignReference to the per-sign JSON file,
    /// replacing any previous recording for that sign.
    /// `signName` should already be lowercased by the caller.
    func saveSignReference(_ ref: SignReference, forSign signName: String) throws {
        let fileURL = try signFileURL(forSign: signName)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode([ref])
        try data.write(to: fileURL, options: [.atomic])

        print("Saved SignReference for '\(signName)' (\(ref.frames.count) frames)")
    }

    func loadSignReferences(forSign signName: String) throws -> [SignReference] {
        let fileURL = try signFileURL(forSign: signName)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            let data = try Data(contentsOf: fileURL)
            if !data.isEmpty {
                return try JSONDecoder().decode([SignReference].self, from: data)
            }
        }
        let bundleURL = Bundle.main.url(forResource: signName, withExtension: "json", subdirectory: "Vision/References")
            ?? Bundle.main.url(forResource: signName, withExtension: "json")
        if let url = bundleURL {
            let data = try Data(contentsOf: url)
            if !data.isEmpty {
                return try JSONDecoder().decode([SignReference].self, from: data)
            }
        }
        return []
    }

    // MARK: - Local recording storage (SignFrame JSON)

    private func recordingsDirectoryURL() throws -> URL {
        let fm = FileManager.default
        let appSupport = try fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let dir = appSupport.appendingPathComponent("Recordings", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// Saves the given frames to Application Support/Recordings/*.json and returns the file URL.
    func saveRecordingFramesToJSON(_ frames: [SignFrame], filename: String? = nil) throws -> URL {
        let dir = try recordingsDirectoryURL()

        let finalName: String = {
            if let filename, !filename.isEmpty {
                return filename.hasSuffix(".json") ? filename : "\(filename).json"
            }
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            return "recording_\(df.string(from: Date())).json"
        }()

        let url = dir.appendingPathComponent(finalName)
        let data = try SignFrame.encodeArray(frames, pretty: true)
        try data.write(to: url, options: [.atomic])
        return url
    }
    
    func trimFramesByVelocity(_ frames: [SignFrame]) -> [SignFrame] {
        guard frames.count > 1 else { return frames }
        
        let velocityThreshold = 0.015
        let padding = 3
        
        // Use raw Vision-normalized coordinates (0...1), not normalizedJoints.
        // normalizedJoints are anchor-relative, so wrist positions would always be ~0,0.
        let trackedJointKeys = [
            "leftVNHLKWRI", "rightVNHLKWRI",
            "leftVNHLKITIP", "rightVNHLKITIP"
        ]
        
        func distance(_ a: Joint, _ b: Joint) -> Double {
            let dx = a.x - b.x
            let dy = a.y - b.y
            return sqrt(dx * dx + dy * dy)
        }
        
        // Marks whether each frame contains meaningful motion.
        // active[i] describes motion from frames[i - 1] -> frames[i]
        var active = Array(repeating: false, count: frames.count)
        
        for i in 1..<frames.count {
            let previous = frames[i - 1]
            let current = frames[i]
            
            var maxMotion = 0.0
            
            for key in trackedJointKeys {
                guard
                    let prevJoint = previous.joints[key],
                    let currJoint = current.joints[key]
                else {
                    continue
                }
                
                let motion = distance(prevJoint, currJoint)
                maxMotion = max(maxMotion, motion)
            }
            
            active[i] = maxMotion >= velocityThreshold
        }
        
        guard let firstActive = active.firstIndex(of: true) else {
            return []
        }
        
        // Scan backwards to find the first quiet gap >= 1 second.
        // This discards trailing motion from reaching to press stop.
        let quietGapThreshold: Double = 1.0
        var endCutoff = frames.count - 1
        
        var i = frames.count - 1
        while i >= firstActive {
            if !active[i] {
                let quietEnd = i
                while i >= firstActive && !active[i] {
                    i -= 1
                }
                let quietStart = i + 1
                let gapDuration = frames[quietEnd].timestamp.seconds
                                - frames[quietStart].timestamp.seconds
                if gapDuration >= quietGapThreshold {
                    endCutoff = quietStart - 1
                    break
                }
            } else {
                i -= 1
            }
        }
        
        let startIndex = max(0, firstActive - padding)
        let endIndex = min(endCutoff, frames.count - 1)
        
        guard endIndex >= startIndex else { return [] }
        
        return Array(frames[startIndex...endIndex])
    }

    /// Loads SignFrames from a local recording JSON.
    func loadRecordingFramesFromJSON(url: URL) throws -> [SignFrame] {
        try SignFrame.decodeArray(from: url)
    }
}
