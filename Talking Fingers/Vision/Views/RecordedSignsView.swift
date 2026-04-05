//
//  RecordedSignsView.swift
//  Talking Fingers
//

#if os(iOS)
import SwiftUI

struct RecordedSignsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var cameraVM = CameraVM()
    @State private var takes: [RecordedSignTake] = []
    @State private var errorMessage: String?

    private var groupedTakes: [(key: String, value: [RecordedSignTake])] {
        Dictionary(grouping: takes, by: { $0.signName })
            .sorted { lhs, rhs in
                lhs.key.localizedCaseInsensitiveCompare(rhs.key) == .orderedAscending
            }
    }

    var body: some View {
        List {
            if takes.isEmpty {
                ContentUnavailableView(
                    "No Recorded Signs",
                    systemImage: "play.slash",
                    description: Text("Record a sign from the camera view and it will show up here for playback.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(groupedTakes, id: \.key) { group in
                    Section(group.key.capitalized) {
                        ForEach(group.value) { take in
                            NavigationLink {
                                RecordedSignPlaybackView(take: take)
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(take.displayFileName)
                                        .font(.headline)
                                        .lineLimit(1)

                                    HStack(spacing: 8) {
                                        Text(take.createdAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)

                                        if take.videoAvailable {
                                            Label("Video", systemImage: "video.fill")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }

                                        if take.frameDataAvailable {
                                            Label("Joints", systemImage: "point.3.filled.connected.trianglepath.dotted")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    delete(take)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Recorded Signs")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Done") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    loadTakes()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task {
            loadTakes()
        }
        .alert("Could Not Load Recordings", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
    }

    private func loadTakes() {
        do {
            takes = try cameraVM.listRecordedTakes()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func delete(_ take: RecordedSignTake) {
        do {
            try cameraVM.deleteTake(take)
            takes.removeAll { $0.id == take.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        RecordedSignsView()
    }
}
#endif
