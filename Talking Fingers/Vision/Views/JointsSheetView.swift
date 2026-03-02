//
//  JointsSheetView.swift
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
    @Binding var bodyJointVisibility: [VNHumanBodyPoseObservation.JointName: Bool]
    @Binding var dotsVisibility: Bool
    @Binding var handOutlineVisibility: Bool
    @Binding var handSkeletonVisibility: Bool
    @Binding var bodySkeletonVisibility: Bool
    // Human-readable labels for each hand joint
    static let handJointLabels: [(name: VNHumanHandPoseObservation.JointName, label: String)] = [
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
    
    static let bodyJointLabels: [(name: VNHumanBodyPoseObservation.JointName, label: String)] = [
        (.leftShoulder, "Right Shoulder"),
        (.rightShoulder, "Left Shoulder"),
        (.leftElbow, "Right Elbow"),
        (.rightElbow, "Left Elbow"),
    ]
    var body: some View {
        NavigationStack {
            List {
                Section("General Overlays") {
                    // Dots toggle
                    Toggle("Show Dots", isOn: $dotsVisibility)
                    // Hand outline toggle
                    Toggle("Show Hand Outline", isOn: $handOutlineVisibility)
                }
                
                Section("Hand Overlays") {
                    // Hand skeleton
                    Toggle("Show Hand Skeleton", isOn: $handSkeletonVisibility)
                    // All hand joints toggle
                    Toggle("Toggle All Hand Joints", isOn: Binding(
                        get: {
                            Self.handJointLabels.allSatisfy { handJointBinding(for: $0.name).wrappedValue }
                        },
                        set: { newValue in
                            for joint in Self.handJointLabels {
                                handJointBinding(for: joint.name).wrappedValue = newValue
                            }
                        }
                    ))
                    ForEach(Self.handJointLabels, id: \.name) { joint in
                        Toggle(joint.label, isOn: handJointBinding(for: joint.name))
                    }
                }
                
                Section("Body Overlays") {
                    // Body skeleton
                    Toggle("Show Body Skeleton", isOn: $bodySkeletonVisibility)
                    // All body joints toggle
                    Toggle("Toggle All Body Joints", isOn: Binding(
                        get: {
                            Self.bodyJointLabels.allSatisfy { bodyJointBinding(for: $0.name).wrappedValue }
                        },
                        set: { newValue in
                            for joint in Self.bodyJointLabels {
                                bodyJointBinding(for: joint.name).wrappedValue = newValue
                            }
                        }
                    ))
                    ForEach(Self.bodyJointLabels, id: \.name) { joint in
                        Toggle(joint.label, isOn: bodyJointBinding(for: joint.name))
                    }
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
    /// Creates a `Binding<Bool>` for a hand joint dictionary key so each Toggle can read/write the dictionary.
    private func handJointBinding(for joint: VNHumanHandPoseObservation.JointName) -> Binding<Bool> {
        Binding(
            get: { jointVisibility[joint] ?? false },
            set: { jointVisibility[joint] = $0 }
        )
    }
    
    /// Creates a `Binding<Bool>` for a body joint dictionary key so each Toggle can read/write the dictionary.
    private func bodyJointBinding(for joint: VNHumanBodyPoseObservation.JointName) -> Binding<Bool> {
        Binding(
            get: { bodyJointVisibility[joint] ?? false },
            set: { bodyJointVisibility[joint] = $0 }
        )
    }
}
#Preview {
    @Previewable @State var previewHandJoints: [VNHumanHandPoseObservation.JointName: Bool] = [
        .thumbTip: true,
        .indexTip: false
    ]
    @Previewable @State var previewBodyJoints: [VNHumanBodyPoseObservation.JointName: Bool] = [
        .leftShoulder: true,
        .rightElbow: false
    ]
    @Previewable @State var previewDots: Bool = true
    @Previewable @State var previewHandOutline: Bool = true
    @Previewable @State var previewHandSkeleton: Bool = true
    @Previewable @State var previewBodySkeleton: Bool = true
    NavigationStack {
        JointsSheetView(
            jointVisibility: $previewHandJoints,
            bodyJointVisibility: $previewBodyJoints,
            dotsVisibility: $previewDots,
            handOutlineVisibility: $previewHandOutline,
            handSkeletonVisibility: $previewHandSkeleton,
            bodySkeletonVisibility: $previewBodySkeleton
        )
    }
}
#endif  // os(iOS)66  os(iOS) 
