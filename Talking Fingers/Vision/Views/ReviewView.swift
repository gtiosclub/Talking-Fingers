//
//  ReviewView.swift
//  Talking Fingers
//
//  Created by Hawthorne Brown on 4/14/26.
//
#if os(iOS)
import SwiftUI
import AVFoundation
import Vision

struct ReviewView: View {
    let signName: String

    init(signName: String = "") {
        self.signName = signName
    }

    @State private var cameraVM: CameraVM = CameraVM()
    @State private var hands: [VNHumanHandPoseObservation] = []

    @State private var countdown: Int = 0
    @State private var countdownTask: Task<Void, Never>?

    @State private var handsLastSeenDate: Date?
    @State private var handsLastSeenPTS: CMTime?
    private let autoStopGracePeriod: TimeInterval = 1.5

    @State private var createdTake: RecordedSignTake?
    @State private var showPlayback = false

    var body: some View {
        NavigationStack {
            ZStack {
                if cameraVM.isAuthorized {
                    CameraPreviewView(session: cameraVM.session)
                        .ignoresSafeArea()
                } else {
                    ContentUnavailableView(
                        "Camera Access Required",
                        systemImage: "camera.fill",
                        description: Text("Please allow camera access in Settings to use review capture.")
                    )
                }

                if countdown > 0 {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)

                    Text("\(countdown)")
                        .font(.system(size: 120, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.5), radius: 8, y: 4)
                }

                VStack {
                    Spacer()

                    Button(action: toggleRecording) {
                        Image(systemName: cameraVM.isRecording ? "stop.circle.fill" : "record.circle")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.red, .white)
                            .font(.system(size: 72))
                    }
                    .disabled(countdown > 0 || signName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
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
                    RecordedSignPlaybackView(take: take)
                }
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

#Preview {
    ReviewView(signName: "hello")
}
#endif
