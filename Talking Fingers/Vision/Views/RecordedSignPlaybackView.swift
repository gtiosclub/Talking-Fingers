//
//  RecordedSignPlaybackView.swift
//  Talking Fingers
//

#if os(iOS)
import SwiftUI
import AVFoundation
import AVKit

struct RecordedSignPlaybackView: View {
    let take: RecordedSignTake

    @State private var cameraVM = CameraVM()
    @State private var frames: [SignFrame] = []
    @State private var player: AVPlayer?
    @State private var currentPlaybackTime: Double = 0
    @State private var isPlaying: Bool = false
    @State private var timeObserverToken: Any?
    @State private var playbackEndedObserver: NSObjectProtocol?
    @State private var errorMessage: String?

    private let fallbackFPS: Double = 24.0

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.black)

                    if let player {
                        PlayerLayerView(player: player)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay {
                                GeometryReader { geo in
                                    if let currentFrame {
                                        RecordedJointOverlayView(
                                            frame: currentFrame,
                                            viewSize: geo.size
                                        )
                                        .allowsHitTesting(false)
                                    }
                                }
                            }
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "video.slash")
                                .font(.jakartaLargeTitle)
                                .foregroundStyle(.white.opacity(0.8))
                            Text("No recorded video available")
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                }
                .aspectRatio(9.0 / 16.0, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                )
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label(take.signName.capitalized, systemImage: "hands.sparkles.fill")
                            .font(.jakartaHeadline)

                        Spacer()

                        Text("\(frames.count) frames")
                            .font(.jakartaSubheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text(take.displayFileName)
                        .font(.jakartaSubheadline)
                        .foregroundStyle(.secondary)

                    if !frames.isEmpty {
                        HStack {
                            Text("Overlay frame: \(currentFrameIndexDisplay)")
                                .font(.jakartaSubheadline)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Text(String(format: "%.2fs", currentPlaybackTime))
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack(spacing: 12) {
                        Button {
                            seek(by: -1.0 / fallbackFPS)
                        } label: {
                            Image(systemName: "gobackward.frame")
                                .font(.jakartaTitle3)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            togglePlayPause()
                        } label: {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.jakartaTitle3)
                                .frame(minWidth: 28)
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            seek(by: 1.0 / fallbackFPS)
                        } label: {
                            Image(systemName: "goforward.frame")
                                .font(.jakartaTitle3)
                        }
                        .buttonStyle(.bordered)

                        Spacer()

                        Button("Restart") {
                            restart()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .navigationTitle(take.signName.capitalized)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            loadAssets()
        }
        .onDisappear {
            cleanupPlayer()
        }
        .alert("Playback Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
    }

    // MARK: - Frame selection

    private var currentFrame: SignFrame? {
        guard !frames.isEmpty else { return nil }

        // Prevent the "frozen last pose" effect near the end:
        // once playback goes past the last captured pose by more than half a frame,
        // stop drawing the overlay.
        if let last = frames.last {
            let cutoff = last.timestamp.seconds + (frameDuration / 2.0)
            if currentPlaybackTime > cutoff {
                return nil
            }
        }

        let idx = nearestFrameIndex(for: currentPlaybackTime)
        guard frames.indices.contains(idx) else { return nil }
        return frames[idx]
    }

    private var currentFrameIndexDisplay: String {
        guard !frames.isEmpty else { return "0 / 0" }

        if let last = frames.last {
            let cutoff = last.timestamp.seconds + (frameDuration / 2.0)
            if currentPlaybackTime > cutoff {
                return "\(frames.count) / \(frames.count)"
            }
        }

        let idx = nearestFrameIndex(for: currentPlaybackTime)
        return "\(idx + 1) / \(frames.count)"
    }

    private var frameDuration: Double {
        guard frames.count >= 2 else { return 1.0 / fallbackFPS }

        let deltas = zip(frames, frames.dropFirst()).map { max(0.0001, $1.timestamp.seconds - $0.timestamp.seconds) }
        let avg = deltas.reduce(0, +) / Double(deltas.count)
        return avg.isFinite ? avg : (1.0 / fallbackFPS)
    }

    private func nearestFrameIndex(for time: Double) -> Int {
        guard !frames.isEmpty else { return 0 }
        if frames.count == 1 { return 0 }

        // Binary search for first frame whose timestamp >= time
        var low = 0
        var high = frames.count - 1

        while low < high {
            let mid = (low + high) / 2
            if frames[mid].timestamp.seconds < time {
                low = mid + 1
            } else {
                high = mid
            }
        }

        let right = low
        let left = max(0, right - 1)

        let leftTime = frames[left].timestamp.seconds
        let rightTime = frames[right].timestamp.seconds

        if abs(time - leftTime) <= abs(rightTime - time) {
            return left
        } else {
            return right
        }
    }

    // MARK: - Loading

    private func loadAssets() {
        do {
            if let jsonURL = take.jsonURL {
                frames = try cameraVM.loadRecordingFramesFromJSON(url: jsonURL)
            } else {
                frames = []
            }

            if let videoURL = take.videoURL {
                let newPlayer = AVPlayer(url: videoURL)
                newPlayer.actionAtItemEnd = .pause
                player = newPlayer
                installTimeObserver(on: newPlayer)
            } else {
                player = nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Controls

    private func togglePlayPause() {
        guard let player else { return }

        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    private func restart() {
        guard let player else { return }
        player.seek(to: .zero)
        currentPlaybackTime = 0
        player.pause()
        isPlaying = false
    }

    private func seek(by delta: Double) {
        guard let player else { return }

        let durationSeconds = player.currentItem?.duration.seconds ?? 0
        let upperBound = durationSeconds.isFinite ? durationSeconds : max(0, currentPlaybackTime + delta)
        let newTime = max(0, min(currentPlaybackTime + delta, upperBound))
        let target = CMTime(seconds: newTime, preferredTimescale: 600)

        player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero)
        currentPlaybackTime = newTime
    }

    // MARK: - Timing

    private func installTimeObserver(on player: AVPlayer) {
        cleanupPlayer(removePlayerOnly: false)

        // Higher-frequency updates reduce overlay lag.
        let interval = CMTime(seconds: 1.0 / 60.0, preferredTimescale: 600)

        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            currentPlaybackTime = max(0, time.seconds)
            isPlaying = player.timeControlStatus == .playing
        }

        playbackEndedObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            isPlaying = false

            // Snap displayed time to the true end.
            if let end = player.currentItem?.duration.seconds, end.isFinite {
                currentPlaybackTime = max(0, end)
            }
        }
    }

    private func cleanupPlayer(removePlayerOnly: Bool = true) {
        if let player, let token = timeObserverToken {
            player.removeTimeObserver(token)
            timeObserverToken = nil
        }

        if let playbackEndedObserver {
            NotificationCenter.default.removeObserver(playbackEndedObserver)
            self.playbackEndedObserver = nil
        }

        player?.pause()

        if removePlayerOnly {
            player = nil
        }

        isPlaying = false
    }
}

// MARK: - Lightweight player view

private struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.playerLayer.videoGravity = .resizeAspectFill
        view.playerLayer.player = player
        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        uiView.playerLayer.player = player
    }
}

private final class PlayerContainerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }

    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }
}

// MARK: - Joint overlay

private struct RecordedJointOverlayView: View {
    let frame: SignFrame
    let viewSize: CGSize

    private let handConnections: [(String, String)] = [
        ("leftVNHLKWRI", "leftVNHLKTCMC"), ("leftVNHLKTCMC", "leftVNHLKTMP"), ("leftVNHLKTMP", "leftVNHLKTIP"), ("leftVNHLKTIP", "leftVNHLKTTIP"),
        ("leftVNHLKWRI", "leftVNHLKIMCP"), ("leftVNHLKIMCP", "leftVNHLKIPIP"), ("leftVNHLKIPIP", "leftVNHLKIDIP"), ("leftVNHLKIDIP", "leftVNHLKITIP"),
        ("leftVNHLKWRI", "leftVNHLKMMCP"), ("leftVNHLKMMCP", "leftVNHLKMPIP"), ("leftVNHLKMPIP", "leftVNHLKMDIP"), ("leftVNHLKMDIP", "leftVNHLKMTIP"),
        ("leftVNHLKWRI", "leftVNHLKRMCP"), ("leftVNHLKRMCP", "leftVNHLKRPIP"), ("leftVNHLKRPIP", "leftVNHLKRDIP"), ("leftVNHLKRDIP", "leftVNHLKRTIP"),
        ("leftVNHLKWRI", "leftVNHLKLMCP"), ("leftVNHLKLMCP", "leftVNHLKLPIP"), ("leftVNHLKLPIP", "leftVNHLKLDIP"), ("leftVNHLKLDIP", "leftVNHLKLTIP"),

        ("rightVNHLKWRI", "rightVNHLKTCMC"), ("rightVNHLKTCMC", "rightVNHLKTMP"), ("rightVNHLKTMP", "rightVNHLKTIP"), ("rightVNHLKTIP", "rightVNHLKTTIP"),
        ("rightVNHLKWRI", "rightVNHLKIMCP"), ("rightVNHLKIMCP", "rightVNHLKIPIP"), ("rightVNHLKIPIP", "rightVNHLKIDIP"), ("rightVNHLKIDIP", "rightVNHLKITIP"),
        ("rightVNHLKWRI", "rightVNHLKMMCP"), ("rightVNHLKMMCP", "rightVNHLKMPIP"), ("rightVNHLKMPIP", "rightVNHLKMDIP"), ("rightVNHLKMDIP", "rightVNHLKMTIP"),
        ("rightVNHLKWRI", "rightVNHLKRMCP"), ("rightVNHLKRMCP", "rightVNHLKRPIP"), ("rightVNHLKRPIP", "rightVNHLKRDIP"), ("rightVNHLKRDIP", "rightVNHLKRTIP"),
        ("rightVNHLKWRI", "rightVNHLKLMCP"), ("rightVNHLKLMCP", "rightVNHLKLPIP"), ("rightVNHLKLPIP", "rightVNHLKLDIP"), ("rightVNHLKLDIP", "rightVNHLKLTIP")
    ]

    private let bodyConnections: [(String, String)] = [
        ("left_shoulder_1_joint", "left_elbow_1_joint"),
        ("right_shoulder_1_joint", "right_elbow_1_joint")
    ]

    var body: some View {
        Canvas { context, _ in
            drawBodyConnections(in: &context)
            drawHandConnections(in: &context)
            drawJointDots(in: &context)
        }
    }

    private func drawBodyConnections(in context: inout GraphicsContext) {
        for (fromKey, toKey) in bodyConnections {
            guard let from = frame.joints[fromKey], let to = frame.joints[toKey],
                  from.confidence > 0.3, to.confidence > 0.3 else { continue }

            var path = Path()
            path.move(to: point(from))
            path.addLine(to: point(to))
            context.stroke(path, with: .color(.orange.opacity(0.85)), lineWidth: 4)
        }
    }

    private func drawHandConnections(in context: inout GraphicsContext) {
        for (fromKey, toKey) in handConnections {
            guard let from = frame.joints[fromKey], let to = frame.joints[toKey],
                  from.confidence > 0.3, to.confidence > 0.3 else { continue }

            let color: Color = fromKey.hasPrefix("left") ? .blue : .purple

            var path = Path()
            path.move(to: point(from))
            path.addLine(to: point(to))
            context.stroke(path, with: .color(color.opacity(0.75)), lineWidth: 3)
        }
    }

    private func drawJointDots(in context: inout GraphicsContext) {
        for (key, joint) in frame.joints where joint.confidence > 0.3 {
            let p = point(joint)
            let rect = CGRect(x: p.x - 4, y: p.y - 4, width: 8, height: 8)

            let color: Color = {
                if key.hasPrefix("left") { return .blue }
                if key.hasPrefix("right") { return .purple }
                return .orange
            }()

            context.fill(Path(ellipseIn: rect), with: .color(color))
        }
    }

    private func point(_ joint: Joint) -> CGPoint {
        CGPoint(
            x: joint.x * viewSize.width,
            y: (1 - joint.y) * viewSize.height
        )
    }
}

#Preview {
    NavigationStack {
        RecordedSignPlaybackView(
            take: RecordedSignTake(
                baseName: "hello_2026-04-05_18-00-00",
                signName: "hello",
                createdAt: .now,
                jsonURL: nil,
                videoURL: nil
            )
        )
    }
}
#endif
