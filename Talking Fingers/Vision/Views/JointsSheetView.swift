//
//  SwiftUIView.swift
//  Talking Fingers
//
//  Created by Nikola Cao on 2/6/26.
//
#if os(iOS)

import SwiftUI
import Vision

struct JointsSheetView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var jointVisibility: [VNHumanHandPoseObservation.JointName: Bool]

    // Human-readable labels for each joint
    static let jointLabels: [(name: VNHumanHandPoseObservation.JointName, label: String)] = [
        (.wrist, "Wrist"),
        (.thumbCMC, "Thumb CMC"),
        (.thumbMP, "Thumb MP"),
        (.thumbIP, "Thumb IP"),
        (.thumbTip, "Thumb Tip"),
        (.indexMCP, "Index MCP"),
        (.indexPIP, "Index PIP"),
        (.indexDIP, "Index DIP"),
        (.indexTip, "Index Tip"),
        (.middleMCP, "Middle MCP"),
        (.middlePIP, "Middle PIP"),
        (.middleDIP, "Middle DIP"),
        (.middleTip, "Middle Tip"),
        (.ringMCP, "Ring MCP"),
        (.ringPIP, "Ring PIP"),
        (.ringDIP, "Ring DIP"),
        (.ringTip, "Ring Tip"),
        (.littleMCP, "Little MCP"),
        (.littlePIP, "Little PIP"),
        (.littleDIP, "Little DIP"),
        (.littleTip, "Little Tip"),
    ]

    var body: some View {
        VStack {
            List {
                ForEach(Self.jointLabels, id: \.name) { joint in
                    Toggle(joint.label, isOn: binding(for: joint.name))
                }
            }
            .navigationTitle("Joint Overlays")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    /// Creates a `Binding<Bool>` for a dictionary key so each Toggle can read/write the dictionary.
    private func binding(for joint: VNHumanHandPoseObservation.JointName) -> Binding<Bool> {
        Binding(
            get: { jointVisibility[joint] ?? false },
            set: { jointVisibility[joint] = $0 }
        )
    }
}

#Preview {
    @Previewable @State var preview: [VNHumanHandPoseObservation.JointName: Bool] = [
        .thumbTip: true,
        .indexTip: false
    ]
    NavigationStack {
        JointsSheetView(jointVisibility: $preview)
    }
}

#endif
