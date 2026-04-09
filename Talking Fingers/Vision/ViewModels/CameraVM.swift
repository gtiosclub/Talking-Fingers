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
class CameraVM: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate {

    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let movieOutput = AVCaptureMovieFileOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")

    // Keep track of normalized hand observations
    var normalizedHands: [NormalizedHandModel] = []

    // --- Recording Logic ---
    var isRecording = false
    private(set) var recordedFrames: [SignFrame] = []
    var recordingStartTime: CMTime? = nil
    private(set) var currentRecordingBaseName: String?
    private(set) var lastFinishedVideoURL: URL?

    // --- Callbacks ---
    var onPoseDetected: (([VNHumanHandPoseObservation], CMTime) -> Void)?
    var onBodyPoseDetected: (([VNHumanBodyPoseObservation], CMTime) -> Void)?

    var isAuthorized = false
    var isMirrored = true

    // MARK: - Sign recognition
    var frameBuffer: SignReference = SignReference()
    private let dtwEngine = DTWService()
    var lastScore = 30.0
    private var frameCounter = 0
    private let stride = 12
    private let maxBufferSize = 75
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
        defer { session.commitConfiguration() }

        session.sessionPreset = .hd1280x720

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }

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

        if session.canAddOutput(movieOutput) { session.addOutput(movieOutput) }

        if let connection = videoOutput.connection(with: .video) {
            #if os(iOS)
            connection.videoOrientation = .portrait
            #else
            connection.videoRotationAngle = 0
            #endif
            connection.isVideoMirrored = self.isMirrored
        }

        if let movieConnection = movieOutput.connection(with: .video) {
            #if os(iOS)
            movieConnection.videoOrientation = .portrait
            #else
            movieConnection.videoRotationAngle = 0
            #endif
            movieConnection.isVideoMirrored = self.isMirrored
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

        motionManager.deviceMotionUpdateInterval = 1.0 / 24.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let motion = motion else { return }
            self?.currentPitch = motion.attitude.pitch
        }
        #else
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
            stopVideoRecording()
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

    func compareStaticFrames(live: SignFrame, reference: SignFrame) -> Double {
        let liveJoints = live.joints
        let refJoints = reference.joints

        var matchedLive: [(x: Double, y: Double)] = []
        var matchedRef: [(x: Double, y: Double)] = []

        for (key, refJoint) in refJoints {
            guard key.contains("VNHLK") else { continue }
            guard let liveJoint = liveJoints[key] else { continue }
            guard refJoint.confidence > 0.3, liveJoint.confidence > 0.3 else { continue }
            matchedLive.append((x: liveJoint.x, y: liveJoint.y))
            matchedRef.append((x: refJoint.x, y: refJoint.y))
        }

        guard matchedLive.count >= 5 else { return 0 }

        let n = Double(matchedLive.count)

        let liveCx = matchedLive.reduce(0.0) { $0 + $1.x } / n
        let liveCy = matchedLive.reduce(0.0) { $0 + $1.y } / n
        let refCx = matchedRef.reduce(0.0) { $0 + $1.x } / n
        let refCy = matchedRef.reduce(0.0) { $0 + $1.y } / n

        let liveScale = max(matchedLive.reduce(0.0) { max($0, hypot($1.x - liveCx, $1.y - liveCy)) }, 1e-6)
        let refScale = max(matchedRef.reduce(0.0) { max($0, hypot($1.x - refCx, $1.y - refCy)) }, 1e-6)

        var totalDist: Double = 0
        for i in 0..<matchedLive.count {
            let lx = (matchedLive[i].x - liveCx) / liveScale
            let ly = (matchedLive[i].y - liveCy) / liveScale
            let rx = (matchedRef[i].x - refCx) / refScale
            let ry = (matchedRef[i].y - refCy) / refScale
            totalDist += hypot(lx - rx, ly - ry)
        }

        let avgDist = totalDist / n
        return max(0, min(100, 100.0 * exp(-3.0 * avgDist)))
    }

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

                    self.processFrame(body: primaryBody, hands: handObservations, pitch: self.currentPitch, timestamp: pts)

                    self.normalizedHands = handObservations.compactMap {
                        NormalizedHandModel(from: $0, pitch: self.currentPitch - (.pi / 2))
                    }

                    if self.isRecording {
                        if self.recordingStartTime == nil {
                            self.recordingStartTime = pts
                        }

                        let relativePTS = CMTimeSubtract(pts, self.recordingStartTime ?? pts)

                        let frame = SignFrame(
                            body: primaryBody,
                            hands: handObservations,
                            at: relativePTS
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

    func processFrame(body: VNHumanBodyPoseObservation?, hands: [VNHumanHandPoseObservation], pitch: Double, timestamp: CMTime) {
        let currentFrame = createSignFrame(body: body, hands: hands, at: timestamp)

        if isComparing, let ref = comparisonReference {
            if ref.signType == .static, let refFrame = ref.frames.first {
                let rawScore = compareStaticFrames(live: currentFrame, reference: refFrame)
                let displayed = min(100, rawScore * 1.3)
                smoothedConfidence = smoothedConfidence * (1 - smoothingFactor) + displayed * smoothingFactor
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
        let x = visionPoint.x * viewSize.width
        let y = (1 - visionPoint.y) * viewSize.height
        return CGPoint(x: x, y: y)
    }

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

    func trimFrames(after cutoff: CMTime) {
        let relativeCutoff: CMTime
        if let start = recordingStartTime {
            relativeCutoff = CMTimeSubtract(cutoff, start)
        } else {
            relativeCutoff = cutoff
        }

        recordedFrames.removeAll { $0.timestamp > relativeCutoff }
    }

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

    // MARK: - Scale invariance / unit-box normalization

    struct NormalizedHand {
        let unitPoints: [String: CGPoint]
        let rawBounds: CGRect
        let scale: CGFloat
        let translation: CGPoint
        let padding: CGPoint
    }

    func normalizeHandToUnitBox(
        hand: SignFrame,
        minConfidence: Float = 0.5,
        centerInBox: Bool = true
    ) -> NormalizedHand? {

        var raw: [String: CGPoint] = [:]
        raw.reserveCapacity(hand.joints.count)

        for (name, j) in hand.joints {
            guard j.confidence >= minConfidence else { continue }
            raw[name] = CGPoint(x: j.x, y: j.y)
        }

        guard raw.count >= 3 else { return nil }

        let xs = raw.values.map { $0.x }
        let ys = raw.values.map { $0.y }
        guard let minX = xs.min(), let maxX = xs.max(),
              let minY = ys.min(), let maxY = ys.max() else { return nil }

        let width = max(maxX - minX, 1e-6)
        let height = max(maxY - minY, 1e-6)
        let bounds = CGRect(x: minX, y: minY, width: width, height: height)

        let s = 1.0 / max(width, height)
        let translation = CGPoint(x: -minX, y: -minY)

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

    // MARK: - Reference storage

    private func referencesDirectoryURL(sourceFile: String = #filePath) throws -> URL {
        let fm = FileManager.default

        #if DEBUG
        let visionDir = URL(fileURLWithPath: sourceFile)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
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

    // MARK: - Local recording storage

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

    func makeRecordingBaseName(forSign signName: String) -> String {
        let normalized = signName
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "_")

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd_HH-mm-ss"

        return "\(normalized)_\(df.string(from: Date()))"
    }

    func beginVideoRecording(forSign signName: String) throws {
        guard !movieOutput.isRecording else { return }

        let baseName = makeRecordingBaseName(forSign: signName)
        let dir = try recordingsDirectoryURL()
        let url = dir.appendingPathComponent("\(baseName).mov")

        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }

        currentRecordingBaseName = baseName
        lastFinishedVideoURL = nil
        movieOutput.startRecording(to: url, recordingDelegate: self)
    }

    func stopVideoRecording() {
        guard movieOutput.isRecording else { return }
        movieOutput.stopRecording()
    }

    func saveRecordingFramesToJSON(_ frames: [SignFrame], baseName: String? = nil) throws -> URL {
        let dir = try recordingsDirectoryURL()
        let resolvedBaseName = baseName ?? "recording_\(Int(Date().timeIntervalSince1970))"
        let url = dir.appendingPathComponent("\(resolvedBaseName).json")
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

    func loadRecordingFramesFromJSON(url: URL) throws -> [SignFrame] {
        try SignFrame.decodeArray(from: url)
    }

    func listRecordedTakes() throws -> [RecordedSignTake] {
        let dir = try recordingsDirectoryURL()
        let urls = try FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: [.creationDateKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )

        var grouped: [String: (jsonURL: URL?, videoURL: URL?, createdAt: Date)] = [:]

        for url in urls {
            let ext = url.pathExtension.lowercased()
            guard ext == "json" || ext == "mov" else { continue }

            let baseName = url.deletingPathExtension().lastPathComponent
            let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
            let createdAt = (attrs?[.creationDate] as? Date) ?? (attrs?[.modificationDate] as? Date) ?? Date()

            if grouped[baseName] == nil {
                grouped[baseName] = (nil, nil, createdAt)
            }

            if ext == "json" {
                grouped[baseName]?.jsonURL = url
            } else if ext == "mov" {
                grouped[baseName]?.videoURL = url
            }

            if let existing = grouped[baseName], createdAt < existing.createdAt {
                grouped[baseName]?.createdAt = createdAt
            }
        }

        return grouped.map { baseName, item in
            RecordedSignTake(
                baseName: baseName,
                signName: Self.extractSignName(from: baseName),
                createdAt: item.createdAt,
                jsonURL: item.jsonURL,
                videoURL: item.videoURL
            )
        }
        .sorted { lhs, rhs in
            if lhs.signName.localizedCaseInsensitiveCompare(rhs.signName) == .orderedSame {
                return lhs.createdAt > rhs.createdAt
            }
            return lhs.signName.localizedCaseInsensitiveCompare(rhs.signName) == .orderedAscending
        }
    }

    func deleteTake(_ take: RecordedSignTake) throws {
        if let jsonURL = take.jsonURL, FileManager.default.fileExists(atPath: jsonURL.path) {
            try FileManager.default.removeItem(at: jsonURL)
        }
        if let videoURL = take.videoURL, FileManager.default.fileExists(atPath: videoURL.path) {
            try FileManager.default.removeItem(at: videoURL)
        }
    }

    private static func extractSignName(from baseName: String) -> String {
        let pieces = baseName.split(separator: "_")
        guard pieces.count >= 3 else {
            return baseName.replacingOccurrences(of: "_", with: " ")
        }

        let tail = pieces.suffix(2).joined(separator: "_")
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd_HH-mm-ss"

        if df.date(from: tail) != nil {
            return pieces.dropLast(2).joined(separator: " ")
        }

        return baseName.replacingOccurrences(of: "_", with: " ")
    }

    // MARK: - AVCaptureFileOutputRecordingDelegate

    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        DispatchQueue.main.async {
            self.lastFinishedVideoURL = nil
        }
    }

    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        DispatchQueue.main.async {
            if let error {
                print("Video recording error: \(error)")
            } else {
                self.lastFinishedVideoURL = outputFileURL
                print("Saved video recording: \(outputFileURL.path)")
            }
        }
    }
}
