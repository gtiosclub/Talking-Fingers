//
//  ExerciseSettingsMenu.swift
//  Talking Fingers
//

import SwiftUI

/// Which input modality the user is practising with during an exercise session.
/// `.mixed` means both Flashcards and Camera are active; each card randomly uses one.
enum ExerciseInputMode: Equatable {
    case flashcards
    case camera
    case mixed
}

/// Top-bar menu that lets the user toggle Flashcard and/or Camera exercise modes mid-session.
/// Both options can be active simultaneously (`.mixed` mode).
struct ExerciseSettingsMenu: View {
    @Binding var mode: ExerciseInputMode

    var body: some View {
        Menu {
            Button {
                toggleFlashcards()
            } label: {
                Label(
                    "Flashcards",
                    systemImage: flashcardsSelected ? "checkmark" : "rectangle.stack"
                )
            }

            #if os(iOS)
            Button {
                toggleCamera()
            } label: {
                Label(
                    "Camera",
                    systemImage: cameraSelected ? "checkmark" : "camera"
                )
            }
            #endif
        } label: {
            HStack(spacing: 6) {
                Text("Exercise Settings")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.black)
            }
        }
        .menuOrder(.fixed)
    }

    // MARK: - Helpers

    private var flashcardsSelected: Bool {
        mode == .flashcards || mode == .mixed
    }

    private var cameraSelected: Bool {
        mode == .camera || mode == .mixed
    }

    private func toggleFlashcards() {
        switch mode {
        case .flashcards: break        // already the only active option — keep it
        case .camera:     mode = .mixed
        case .mixed:      mode = .camera
        }
    }

    private func toggleCamera() {
        switch mode {
        case .camera:     break        // already the only active option — keep it
        case .flashcards: mode = .mixed
        case .mixed:      mode = .flashcards
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ExerciseSettingsMenu(mode: .constant(.flashcards))
        ExerciseSettingsMenu(mode: .constant(.camera))
        ExerciseSettingsMenu(mode: .constant(.mixed))
    }
    .padding()
}
