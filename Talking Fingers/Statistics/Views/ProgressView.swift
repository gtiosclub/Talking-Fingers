//
//  ProgressView.swift
//  Talking Fingers
//
//  Created by Jagat Sachdeva on 2/19/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct WidgetItem: Identifiable, Equatable, Hashable {
    let id: UUID
    var title: String
}

struct TFProgressView: View {
    @State private var widgets: [WidgetItem] = [WidgetItem(id: UUID(), title: "Widget A"), WidgetItem(id: UUID(), title: "Widget B"), WidgetItem(id: UUID(), title: "Widget C")]
    @State private var draggingItem: WidgetItem?
    @State private var dragStartIndex: Int?
    @State private var rowFrames: [UUID: CGRect] = [:]
    @State private var dragStartCenterY: CGFloat = 0
    @State private var overlayCenterY: CGFloat = 0
    @State private var isEditing: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if isEditing {
                    Button(action: {
                        // TODO: Add widgets action
                    }) {
                        Text("Add Widgets")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.thinMaterial)
                            .cornerRadius(8)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: {
                        withAnimation { isEditing = false }
                        // Cancel any in-progress drag
                        draggingItem = nil
                        dragStartIndex = nil
                    }) {
                        Text("Done")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.thinMaterial)
                            .cornerRadius(8)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Button(action: {
                        withAnimation { isEditing = true }
                    }) {
                        Text("Edit Widgets")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.thinMaterial)
                            .cornerRadius(8)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: {
                        
                    }) {
                        Label("", systemImage: "person.crop.circle")
                            .font(.system(size: 32))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            Text("Progress")
                .font(.largeTitle)
                .bold()
            
            Text(Date.now.formatted(date: .abbreviated, time: .omitted))
                .font(.title2)
                .foregroundColor(.secondary)
                .fontWeight(.semibold)
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(widgets.enumerated()), id: \.element.id) { index, item in
                        WidgetComponent(title: item.title)
                            .background(
                                GeometryReader { geo in
                                    Color.clear.preference(key: RowFrameKey.self, value: [item.id: geo.frame(in: .named("reorderArea"))])
                                }
                            )
                            .opacity(draggingItem?.id == item.id ? 0 : 1)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        guard isEditing else { return }
                                        if draggingItem == nil {
                                            draggingItem = item
                                            dragStartIndex = index
                                            dragStartCenterY = rowFrames[item.id]?.midY ?? 0
                                            overlayCenterY = dragStartCenterY
                                        }
                                        overlayCenterY = dragStartCenterY + value.translation.height
                                        guard let currentItem = draggingItem else { return }
                                        if let from = widgets.firstIndex(of: currentItem) {
                                            let insertion = insertionIndex(for: overlayCenterY, excluding: currentItem.id)
                                            var to = insertion
                                            if to >= from { to += 1 }
                                            if to != from {
                                                withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.85)) {
                                                    widgets.move(fromOffsets: IndexSet(integer: from), toOffset: to)
                                                }
                                            }
                                        }
                                    }
                                    .onEnded { _ in
                                        guard isEditing else { return }
                                        draggingItem = nil
                                        dragStartIndex = nil
                                    }
                            )
                            .overlay(alignment: .trailing) {
                                if isEditing {
                                    Image(systemName: "line.3.horizontal")
                                        .foregroundStyle(.secondary)
                                        .padding()
                                }
                            }
                    }
                }
                .onPreferenceChange(RowFrameKey.self) { frames in
                    self.rowFrames = frames
                }
            }
            .coordinateSpace(name: "reorderArea")
            .overlay(alignment: .topLeading) {
                if isEditing, let draggingItem = draggingItem, let frame = rowFrames[draggingItem.id] {
                    WidgetComponent(title: draggingItem.title)
                        .frame(width: frame.width, height: frame.height)
                        .position(x: frame.midX, y: overlayCenterY)
                        .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 4)
                        .zIndex(10000)
                }
            }
            .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.85), value: widgets)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }
    
    private func insertionIndex(for centerY: CGFloat, excluding id: UUID) -> Int {
        let ids = widgets.map(\.id).filter { $0 != id }
        for (i, other) in ids.enumerated() {
            if let f = rowFrames[other], centerY < f.midY {
                return i
            }
        }
        return ids.count
    }
}

private struct RowFrameKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]
    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

#Preview {
    TFProgressView()
}

