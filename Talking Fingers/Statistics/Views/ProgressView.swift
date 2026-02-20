//
//  ProgressView.swift
//  Talking Fingers
//
//  Created by Jagat Sachdeva on 2/19/26.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct TFProgressView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm = AnalyticsVM()

    // Drag UI state (view-only)
    @State private var draggingItem: StatsWidget?
    @State private var dragStartIndex: Int?
    @State private var rowFrames: [UUID: CGRect] = [:]
    @State private var dragStartCenterY: CGFloat = 0
    @State private var overlayCenterY: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            headerBar
            titleSection
            widgetList
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
        .onAppear {
            vm.configure(modelContext: modelContext)
        }
        .sheet(isPresented: $vm.isShowingAddSheet) {
            AddWidgetSheet { (title: String) in
                vm.addWidget(title: title)
            }
            .presentationDetents([PresentationDetent.medium, PresentationDetent.large])
            .presentationDragIndicator(Visibility.visible)
            .presentationBackground(Color.white)
        }
        .alert("Delete Widget?", isPresented: $vm.showDeleteAlert, presenting: vm.pendingDelete) { item in
            Button("Delete", role: .destructive) {
                withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.85)) {
                    vm.confirmDelete()
                }
            }
            Button("Cancel", role: .cancel) {
                vm.cancelDelete()
            }
        } message: { item in
            Text("Are you sure you want to delete \(item.title)?")
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var headerBar: some View {
        HStack {
            if vm.isEditing {
                Button(action: {
                    draggingItem = nil
                    dragStartIndex = nil
                    vm.isShowingAddSheet = true
                }) {
                    Text("Add")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.thinMaterial)
                        .cornerRadius(8)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: {
                    withAnimation { vm.doneEditing() }
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
                    withAnimation { vm.startEditing() }
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
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Progress")
                .font(.largeTitle)
                .bold()

            Text(Date.now.formatted(date: .abbreviated, time: .omitted))
                .font(.title2)
                .foregroundColor(.secondary)
                .fontWeight(.semibold)
        }
    }

    @ViewBuilder
    private var widgetList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(vm.widgets.enumerated()), id: \.element.id) { index, item in
                    widgetRow(index: index, item: item)
                }
            }
            .onPreferenceChange(RowFrameKey.self) { frames in
                self.rowFrames = frames
            }
        }
        .coordinateSpace(name: "reorderArea")
        .scrollClipDisabled()
        .overlay(alignment: .topLeading) {
            dragOverlay
        }
        .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.85), value: vm.widgets)
        .padding(.top, 8)
    }

    @ViewBuilder
    private func widgetRow(index: Int, item: StatsWidget) -> some View {
        WidgetComponent(title: item.title)
            .background(
                GeometryReader { geo in
                    Color.clear.preference(key: RowFrameKey.self, value: [item.id: geo.frame(in: .named("reorderArea"))])
                }
            )
            .opacity(draggingItem?.id == item.id ? 0 : 1)
            .gesture(dragGesture(index: index, item: item))
            .overlay(alignment: .trailing) {
                if vm.isEditing, draggingItem?.id != item.id {
                    Image(systemName: "line.3.horizontal")
                        .foregroundStyle(.secondary)
                        .padding()
                }
            }
            .overlay(alignment: .topLeading) {
                if vm.isEditing, draggingItem?.id != item.id {
                    Button(action: {
                        vm.requestDelete(item)
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .offset(x: -11, y: -11)
                }
            }
    }

    @ViewBuilder
    private var dragOverlay: some View {
        if vm.isEditing, let draggingItem = draggingItem, let frame = rowFrames[draggingItem.id] {
            WidgetComponent(title: draggingItem.title)
                .overlay(alignment: .trailing) {
                    Image(systemName: "line.3.horizontal")
                        .foregroundStyle(.secondary)
                        .padding()
                }
                .frame(width: frame.width, height: frame.height)
                .position(x: frame.midX, y: overlayCenterY)
                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 4)
                .zIndex(10000)
        }
    }

    // MARK: - Gestures & Helpers

    private func dragGesture(index: Int, item: StatsWidget) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard vm.isEditing else { return }
                if draggingItem == nil {
                    draggingItem = item
                    dragStartIndex = index
                    dragStartCenterY = rowFrames[item.id]?.midY ?? 0
                    overlayCenterY = dragStartCenterY
                }
                overlayCenterY = dragStartCenterY + value.translation.height
                guard let currentItem = draggingItem else { return }
                if let from = vm.widgets.firstIndex(of: currentItem) {
                    let insertion = insertionIndex(for: overlayCenterY, excluding: currentItem.id)
                    var to = insertion
                    if to >= from { to += 1 }
                    if to != from {
                        withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.85)) {
                            vm.moveWidget(from: from, to: to)
                        }
                    }
                }
            }
            .onEnded { _ in
                guard vm.isEditing else { return }
                draggingItem = nil
                dragStartIndex = nil
            }
    }

    private func insertionIndex(for centerY: CGFloat, excluding id: UUID) -> Int {
        let ids = vm.widgets.map(\.id).filter { $0 != id }
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
        .modelContainer(for: StatsWidget.self, inMemory: true)
}
