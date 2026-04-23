//
//  ReviewView_macOS.swift
//  Talking Fingers
//
//  Created by Codex on 4/19/26.
//

#if os(macOS)
import SwiftUI
import AVFoundation
import AVKit
import Vision

struct ReviewView: View {
    let signName: String

    init(signName: String = "") {
        self.signName = signName
    }

    @State private var cameraVM = CameraVM()
    @State private var hands: [VNHumanHandPoseObservation] = []

    @State private var countdown: Int = 0
    @State private var countdownTask: Task<Void, Never>?

    @State private var handsLastSeenDate: Date?
    @State private var handsLastSeenPTS: CMTime?
    private let autoStopGracePeriod: TimeInterval = 1.5

    @State private var createdTake: RecordedSignTake?
    @State private var showPlayback = false

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Review")
                            .font(.jakarta(size: 28, weight: .semibold))
                        Text("Record and instantly replay a sign take")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 28)
                .padding(.top, 20)

                if cameraVM.isAuthorized {
                    ZStack {
                        CameraPreviewView(session: cameraVM.session, isMirrored: cameraVM.isMirrored)

                        if countdown > 0 {
                            Color.black.opacity(0.35)
                                .allowsHitTesting(false)

                            Text("\(countdown)")
                                .font(.jakarta(size: 120, weight: .bold))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.5), radius: 8, y: 4)
                        }
                    }
                    .aspectRatio(16.0 / 9.0, contentMode: .fit)
                    .frame(maxWidth: 1100)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(.white.opacity(0.10), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 8)
                    .padding(.horizontal, 28)
                } else {
                    ContentUnavailableView(
                        "Camera Access Required",
                        systemImage: "camera.fill",
                        description: Text("Please allow camera access in System Settings to use review capture.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                Button(action: toggleRecording) {
                    Image(systemName: cameraVM.isRecording ? "stop.circle.fill" : "record.circle")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.red, .white)
                        .font(.jakarta(size: 72))
                }
                .buttonStyle(.plain)
                .disabled(countdown > 0 || signName.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            cameraVM.isMirrored = true
            cameraVM.checkPermission()

            cameraVM.onPoseDetected = { handObservations, pts in
                hands = handObservations

                guard cameraVM.isRecording else { return }

                if !handObservations.isEmpty {
                    handsLastSeenDate = Date()
                    handsLastSeenPTS = pts
                } else if let lastSeen = handsLastSeenDate,
                          Date().timeIntervalSince(lastSeen) >= autoStopGracePeriod {
                    toggleRecording()
                }
            }
        }
        .task {
            try? await Task.sleep(for: .milliseconds(300))
            cameraVM.start()
        }
        .onDisappear {
            countdownTask?.cancel()
            cameraVM.stop()
        }
        .navigationDestination(isPresented: $showPlayback) {
            if let take = createdTake {
                ReviewPlaybackView(take: take)
            }
        }
    }

    private func toggleRecording() {
        if cameraVM.isRecording {
            if let cutoff = handsLastSeenPTS {
                cameraVM.trimFrames(after: cutoff)
            }

            cameraVM.toggleRecording()
            handsLastSeenDate = nil
            handsLastSeenPTS = nil

            let normalizedName = signName.lowercased().trimmingCharacters(in: .whitespaces)
            let filteredFrames = cameraVM.recordedFrames

            guard !filteredFrames.isEmpty else {
                print("Review recording for '\(normalizedName)' produced 0 frames after filtering.")
                cameraVM.clearBuffer()
                return
            }

            do {
                let playbackFrames = filteredFrames
                guard !playbackFrames.isEmpty else {
                    print("Review recording for '\(normalizedName)' produced 0 usable frames.")
                    cameraVM.clearBuffer()
                    return
                }

                let baseName = cameraVM.currentRecordingBaseName ?? cameraVM.makeRecordingBaseName(forSign: normalizedName)
                let jsonURL = try cameraVM.saveRecordingFramesToJSON(playbackFrames, baseName: baseName)
                let decodedFrames = try cameraVM.loadRecordingFramesFromJSON(url: jsonURL)

                let videoURL = jsonURL.deletingPathExtension().appendingPathExtension("mov")
                let take = RecordedSignTake(
                    baseName: jsonURL.deletingPathExtension().lastPathComponent,
                    signName: normalizedName,
                    createdAt: Date(),
                    jsonURL: jsonURL,
                    videoURL: FileManager.default.fileExists(atPath: videoURL.path) ? videoURL : nil
                )

                print("Saved review take: \(jsonURL.path) (\(decodedFrames.count) frames)")
                createdTake = take
                showPlayback = true
            } catch {
                print("Review recording save/load error: \(error)")
            }

            cameraVM.clearBuffer()
        } else {
            startCountdownThenRecord()
        }
    }

    private func startCountdownThenRecord() {
        countdownTask?.cancel()
        countdown = 3
        handsLastSeenDate = nil
        handsLastSeenPTS = nil

        countdownTask = Task {
            for tick in stride(from: 3, through: 1, by: -1) {
                countdown = tick
                try? await Task.sleep(for: .seconds(1))

                if Task.isCancelled {
                    countdown = 0
                    return
                }
            }

            countdown = 0

            let normalizedName = signName.lowercased().trimmingCharacters(in: .whitespaces)

            do {
                try cameraVM.beginVideoRecording(forSign: normalizedName)
            } catch {
                print("Failed to start video recording: \(error)")
            }

            cameraVM.toggleRecording()
        }
    }
}

private struct ReviewPlaybackView: View {
    let take: RecordedSignTake
    @State private var player: AVPlayer?

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.black)

                if let player {
                    VideoPlayer(player: player)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                } else {
                    ContentUnavailableView(
                        "No Recorded Video",
                        systemImage: "video.slash",
                        description: Text("Could not find a video file for this take.")
                    )
                }
            }
            .aspectRatio(16.0 / 9.0, contentMode: .fit)
            .frame(maxWidth: 1100)
            .frame(maxWidth: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
            .padding(.horizontal, 28)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(take.signName.capitalized)
                        .font(.jakartaHeadline)
                    Text(take.displayFileName)
                        .font(.jakartaSubheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 18)
        }
        .navigationTitle(take.signName.capitalized)
        .task {
            guard let videoURL = take.videoURL else { return }
            player = AVPlayer(url: videoURL)
            player?.play()
        }
        .onDisappear {
            player?.pause()
        }
    }
}

#Preview {
    NavigationStack {
        ReviewView(signName: "hello")
    }
}
#endif
