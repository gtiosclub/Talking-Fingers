//
//  RecordedSignPlaybackView.swift
//  Talking Fingers
//
//  Created by Akshaj Nadimpalli on 4/5/26.
//

#if os(iOS)
import SwiftUI
import CoreMedia

struct RecordedSignPlaybackView: View {
    let recording: RecordedSignFile

    @State private var cameraVM = CameraVM()
    @State private var frames: [SignFrame] = []
    @State private var currentFrameIndex: Int = 0
    @State private var isPlaying: Bool = false
    @State private var playbackTask: Task<Void, Never>?
    @State private var errorMessage: String?

    private let bodyConnections: [(String, String)] = [
        ("left_shoulder_1_joint", "left_elbow_1_joint"),
        ("right_shoulder_1_joint", "right_elbow_1_joint")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.black)

                    if let currentFrame {
                        RecordedFrameCanvas(
                            frame: currentFrame,
                            bodyConnections: bodyConnections
                        )
                        .padding(12)
                    } else {
                        ContentUnavailableView(
                            "No Frames",
                            systemImage: "video.slash",
                            description: Text("This recording does not contain any playable frames.")
                        )
                        .foregroundStyle(.white)
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
                        Label(recording.signName.capitalized, systemImage: "hands.sparkles.fill")
                            .font(.headline)

                        Spacer()

                        Text("\(frames.count) frames")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text(recording.fileName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if !frames.isEmpty {
                        VStack(spacing: 10) {
                            Slider(
                                value: Binding(
                                    get: { Double(currentFrameIndex) },
                                    set: { newValue in
                                        stopPlayback()
                                        currentFrameIndex = min(max(Int(newValue.rounded()), 0), max(frames.count - 1, 0))
                                    }
                                ),
                                in: 0...Double(max(frames.count - 1, 0)),
                                step: 1
                            )

                            HStack {
                                Text("Frame \(currentFrameIndex + 1) / \(frames.count)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Text(currentTimestampLabel)
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }

                            HStack(spacing: 16) {
                                Button {
                                    stepBackward()
                                } label: {
                                    Image(systemName: "backward.frame.fill")
                                        .font(.title2)
                                }

                                Button {
                                    togglePlayback()
                                } label: {
                                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 42))
                                }

                                Button {
                                    stepForward()
                                } label: {
                                    Image(systemName: "forward.frame.fill")
                                        .font(.title2)
                                }

                                Spacer()

                                Button("Restart") {
                                    restartPlayback()
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .navigationTitle(recording.signName.capitalized)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            loadFrames()
        }
        .onDisappear {
            stopPlayback()
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

    private var currentFrame: SignFrame? {
        guard frames.indices.contains(currentFrameIndex) else { return nil }
        return frames[currentFrameIndex]
    }

    private var currentTimestampLabel: String {
        guard let currentFrame else { return "0.00s" }
        return String(format: "%.2fs", currentFrame.timestamp.seconds)
    }

    private func loadFrames() {
        do {
            frames = try cameraVM.loadRecordingFramesFromJSON(url: recording.url)
            currentFrameIndex = 0
            isPlaying = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func togglePlayback() {
        guard !frames.isEmpty else { return }

        if isPlaying {
            stopPlayback()
        } else {
            startPlayback()
        }
    }

    private func startPlayback() {
        guard !frames.isEmpty else { return }

        stopPlayback()
        isPlaying = true

        playbackTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(42))

                await MainActor.run {
                    guard !frames.isEmpty else {
                        stopPlayback()
                        return
                    }

                    if currentFrameIndex >= frames.count - 1 {
                        stopPlayback()
                    } else {
                        currentFrameIndex += 1
                    }
                }
            }
        }
    }

    private func stopPlayback() {
        isPlaying = false
        playbackTask?.cancel()
        playbackTask = nil
    }

    private func restartPlayback() {
        stopPlayback()
        currentFrameIndex = 0
    }

    private func stepBackward() {
        stopPlayback()
        currentFrameIndex = max(currentFrameIndex - 1, 0)
    }

    private func stepForward() {
        stopPlayback()
        currentFrameIndex = min(currentFrameIndex + 1, max(frames.count - 1, 0))
    }
}

private struct RecordedFrameCanvas: View {
    let frame: SignFrame
    let bodyConnections: [(String, String)]

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                drawSkeleton(in: &context, size: size)
            }
        }
    }

    private func drawSkeleton(in context: inout GraphicsContext, size: CGSize) {
        drawBodyConnections(in: &context, size: size)
        drawJointDots(in: &context, size: size)
    }

    private func drawBodyConnections(in context: inout GraphicsContext, size: CGSize) {
        for (fromKey, toKey) in bodyConnections {
            guard let from = frame.joints[fromKey], let to = frame.joints[toKey],
                  from.confidence > 0.3, to.confidence > 0.3 else { continue }

            let start = screenPoint(x: from.x, y: from.y, in: size)
            let end = screenPoint(x: to.x, y: to.y, in: size)

            var path = Path()
            path.move(to: start)
            path.addLine(to: end)

            context.stroke(path, with: .color(.orange.opacity(0.9)), lineWidth: 4)
        }
    }

    private func drawJointDots(in context: inout GraphicsContext, size: CGSize) {
        for (key, joint) in frame.joints where joint.confidence > 0.3 {
            let point = screenPoint(x: joint.x, y: joint.y, in: size)
            let rect = CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8)

            let color: Color = {
                if key.hasPrefix("left") { return .blue }
                if key.hasPrefix("right") { return .purple }
                return .orange
            }()

            context.fill(Path(ellipseIn: rect), with: .color(color))
        }
    }

    private func screenPoint(x: Double, y: Double, in size: CGSize) -> CGPoint {
        CGPoint(
            x: x * size.width,
            y: (1 - y) * size.height
        )
    }
}

#Preview {
    NavigationStack {
        RecordedSignPlaybackView(
            recording: RecordedSignFile(
                url: URL(fileURLWithPath: "/tmp/example.json"),
                signName: "hello",
                createdAt: .now,
                fileName: "hello_2026-04-05_12-00-00.json"
            )
        )
    }
}
#endif
