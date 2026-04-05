//
//  RecordedSignsView.swift
//  Talking Fingers
//
//  Created by Akshaj Nadimpalli on 4/5/26.
//


#if os(iOS)
import SwiftUI

struct RecordedSignsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var cameraVM = CameraVM()
    @State private var recordings: [RecordedSignFile] = []
    @State private var errorMessage: String?

    private var groupedRecordings: [(key: String, value: [RecordedSignFile])] {
        Dictionary(grouping: recordings, by: { $0.signName })
            .sorted { lhs, rhs in
                lhs.key.localizedCaseInsensitiveCompare(rhs.key) == .orderedAscending
            }
    }

    var body: some View {
        List {
            if recordings.isEmpty {
                ContentUnavailableView(
                    "No Recorded Signs",
                    systemImage: "play.slash",
                    description: Text("Record a sign from the camera view and it will show up here for playback.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(groupedRecordings, id: \.key) { group in
                    Section(group.key.capitalized) {
                        ForEach(group.value) { recording in
                            NavigationLink {
                                RecordedSignPlaybackView(recording: recording)
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(recording.fileName)
                                        .font(.headline)
                                        .lineLimit(1)

                                    Text(recording.createdAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 2)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    delete(recording)
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
                    loadRecordings()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task {
            loadRecordings()
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

    private func loadRecordings() {
        do {
            recordings = try cameraVM.listRecordedSignFiles()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func delete(_ recording: RecordedSignFile) {
        do {
            try cameraVM.deleteRecording(recording)
            recordings.removeAll { $0.id == recording.id }
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
