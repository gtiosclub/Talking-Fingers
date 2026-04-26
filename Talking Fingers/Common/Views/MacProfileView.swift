//
//  MacProfileView.swift
//  Talking Fingers
//
//  macOS-only profile page showing user identity + customizable widgets.
//  Reuses widget content views defined in ProfileWidgetsView.swift.
//

#if os(macOS)
import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct MacProfileView: View {
    @Environment(AuthenticationViewModel.self) private var authVM
    @StateObject private var vm = ProfileWidgetsVM()
    @State private var isEditing: Bool = false
    @State private var showingAddWidgets: Bool = false
    @State private var draggingWidgetID: UUID?

    // Persisted user choices.
    @AppStorage("mac_profile_avatar_data") private var avatarData: Data = Data()
    @AppStorage("mac_profile_column_map") private var columnMapData: Data = Data()

    // Default column per widget type (used when there is no explicit override).
    private static let defaultLeftTypes: Set<WidgetType> = [
        .streak, .wordsLearned, .recentProgress, .dailyChallenge
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                bannerSection
                Rectangle()
                    .fill(TFWidgetColors.border)
                    .frame(height: 1)
                    .padding(.horizontal, 32)

                actionRow
                    .padding(.horizontal, 32)
                    .padding(.top, 18)
                    .padding(.bottom, 14)

                widgetsArea
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.white)
        .sheet(isPresented: $showingAddWidgets) {
            MacAddWidgetsSheet(
                vm: vm,
                onAdd: { type in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        vm.addWidget(type: type)
                    }
                },
                onClose: { showingAddWidgets = false }
            )
        }
    }

    // MARK: - Banner (green band + avatar + identity)

    private var bannerSection: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color(hex: 0xA1B486).opacity(0.5))
                    .frame(height: 110)
                Color.clear.frame(height: 80)
            }

            HStack(alignment: .top, spacing: 24) {
                avatarButton
                    .padding(.top, 50)

                VStack(alignment: .leading, spacing: 4) {
                    Text(displayName)
                        .font(.jakarta(size: 30, weight: .bold))
                        .foregroundStyle(TFWidgetColors.black)
                    Text(identitySubtitle)
                        .font(.jakarta(size: 14, weight: .regular))
                        .foregroundStyle(TFWidgetColors.textMuted)
                }
                .padding(.top, 118)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 40)
        }
        .padding(.bottom, 16)
    }

    private var avatarButton: some View {
        Button(action: pickAvatar) {
            ZStack {
                avatarImage
                if isHoveringAvatar {
                    Circle()
                        .fill(Color.black.opacity(0.35))
                    Image(systemName: "camera.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 120, height: 120)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 3))
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) { isHoveringAvatar = hovering }
        }
        .help("Change profile picture")
    }

    @State private var isHoveringAvatar: Bool = false

    @ViewBuilder
    private var avatarImage: some View {
        if !avatarData.isEmpty, let nsImage = NSImage(data: avatarData) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 120, height: 120)
        } else {
            ZStack {
                Color(hex: 0xA1B486).opacity(0.5)
                Image(systemName: "cat.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.black)
                    .padding(24)
            }
        }
    }

    private func pickAvatar() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image, .png, .jpeg, .heic, .tiff, .gif]
        panel.title = "Choose a profile picture"
        panel.prompt = "Choose"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard let image = NSImage(contentsOf: url) else { return }
        guard let resized = squareThumbnail(image, side: 256),
              let data = pngData(resized) else { return }
        avatarData = data
    }

    // Crop to square (center) and resize to `side × side`.
    private func squareThumbnail(_ image: NSImage, side: CGFloat) -> NSImage? {
        let srcSize = image.size
        guard srcSize.width > 0, srcSize.height > 0 else { return nil }
        let shortSide = min(srcSize.width, srcSize.height)
        let cropRect = NSRect(
            x: (srcSize.width - shortSide) / 2,
            y: (srcSize.height - shortSide) / 2,
            width: shortSide, height: shortSide
        )

        let target = NSImage(size: NSSize(width: side, height: side))
        target.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(
            in: NSRect(x: 0, y: 0, width: side, height: side),
            from: cropRect,
            operation: .copy,
            fraction: 1.0
        )
        target.unlockFocus()
        return target
    }

    private func pngData(_ image: NSImage) -> Data? {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }

    private var displayName: String {
        let trimmed = (authVM.currentUser?.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Nikola Cao" : trimmed
    }

    private var identitySubtitle: String {
        let handle = authVM.currentUser?.email.components(separatedBy: "@").first
        let username = (handle?.isEmpty == false) ? handle! : "nikola123"
        return "@\(username) · Joined in March 2026"
    }

    // MARK: - Action row

    private var actionRow: some View {
        HStack {
            if isEditing {
                pillButton(title: "Add Widgets") { showingAddWidgets = true }
                Spacer()
                pillButton(title: "Done") {
                    withAnimation(.easeInOut(duration: 0.2)) { isEditing = false }
                }
            } else {
                pillButton(title: "Edit Widgets") {
                    withAnimation(.easeInOut(duration: 0.2)) { isEditing = true }
                }
                Spacer()
                Text(formattedToday)
                    .font(.jakarta(size: 14, weight: .semibold))
                    .foregroundStyle(TFWidgetColors.textDark)
            }
        }
    }

    private func pillButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.jakarta(size: 13, weight: .semibold))
                .foregroundStyle(TFWidgetColors.black)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(TFWidgetColors.pill)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(TFWidgetColors.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var formattedToday: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: Date())
    }

    // MARK: - Column assignment (persisted overrides + type default)

    private enum WidgetColumn: String { case left, right }

    private func currentColumnMap() -> [String: String] {
        guard !columnMapData.isEmpty,
              let map = try? JSONDecoder().decode([String: String].self, from: columnMapData) else {
            return [:]
        }
        return map
    }

    private func saveColumn(_ column: WidgetColumn, for id: UUID) {
        var map = currentColumnMap()
        map[id.uuidString] = column.rawValue
        if let data = try? JSONEncoder().encode(map) {
            columnMapData = data
        }
    }

    private func effectiveColumn(for widget: ProfileWidget) -> WidgetColumn {
        if let raw = currentColumnMap()[widget.id.uuidString],
           let col = WidgetColumn(rawValue: raw) {
            return col
        }
        return Self.defaultLeftTypes.contains(widget.type) ? .left : .right
    }

    private var leftWidgets: [ProfileWidget] {
        vm.displayedWidgets
            .filter { effectiveColumn(for: $0) == .left }
            .sorted(by: { $0.order < $1.order })
    }

    private var rightWidgets: [ProfileWidget] {
        vm.displayedWidgets
            .filter { effectiveColumn(for: $0) == .right }
            .sorted(by: { $0.order < $1.order })
    }

    // MARK: - Widgets area

    private var widgetsArea: some View {
        HStack(alignment: .top, spacing: 20) {
            leftColumn
                .frame(maxWidth: .infinity, alignment: .top)

            Rectangle()
                .fill(TFWidgetColors.border)
                .frame(width: 1)
                .frame(minHeight: 240)

            rightColumn
                .frame(maxWidth: .infinity, alignment: .top)
        }
    }

    @ViewBuilder
    private var leftColumn: some View {
        VStack(spacing: 14) {
            let rows = buildLeftRows(from: leftWidgets)
            ForEach(rows, id: \.id) { row in
                switch row.kind {
                case .pair(let a, let b):
                    HStack(spacing: 12) {
                        reorderableCard(widget: a, height: 96)
                        reorderableCard(widget: b, height: 96)
                    }
                    .transition(.scale.combined(with: .opacity))
                case .single(let w):
                    reorderableCard(widget: w, height: preferredHeight(for: w.type))
                        .transition(.scale.combined(with: .opacity))
                }
            }

            if isEditing {
                columnDropZone(target: .left)
            }
        }
    }

    @ViewBuilder
    private var rightColumn: some View {
        VStack(spacing: 14) {
            ForEach(rightWidgets) { w in
                reorderableCard(widget: w, height: preferredHeight(for: w.type))
                    .transition(.scale.combined(with: .opacity))
            }

            if isEditing {
                columnDropZone(target: .right)
            }
        }
    }

    // Drop area shown at the end of each column in edit mode. Accepts drops so
    // users can move a widget to the bottom of a (possibly empty) column,
    // including across columns.
    private func columnDropZone(target: WidgetColumn) -> some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
            .foregroundStyle(TFWidgetColors.border)
            .frame(height: 44)
            .overlay(
                Text("Drop here")
                    .font(.jakarta(size: 12, weight: .semibold))
                    .foregroundStyle(TFWidgetColors.textMuted)
            )
            .opacity(draggingWidgetID == nil ? 0.0 : 0.8)
            .animation(.easeInOut(duration: 0.15), value: draggingWidgetID)
            .onDrop(of: [.plainText], isTargeted: nil) { providers in
                acceptDrop(providers: providers) { sourceID in
                    handleDrop(sourceID: sourceID, intoColumn: target, onto: nil)
                }
            }
    }

    private func preferredHeight(for type: WidgetType) -> CGFloat {
        switch type {
        case .streak, .wordsLearned:   return 96
        case .recentProgress:          return 96
        case .dailyChallenge:          return 124
        case .masteryBadges:           return 330
        case .weeklyActivity:          return 280
        case .accuracy:                return 250
        }
    }

    // MARK: - Card with drag/drop + wiggle + remove button

    @ViewBuilder
    private func reorderableCard(widget: ProfileWidget, height: CGFloat) -> some View {
        WidgetCardView(
            widget: widget,
            isEditMode: isEditing,
            onRemove: { removeAnimated(widget) }
        )
        .frame(height: height)
        .opacity(draggingWidgetID == widget.id ? 0.35 : 1.0)
        .modifier(DragReorderModifier(
            widgetID: widget.id,
            isEnabled: isEditing,
            draggingID: $draggingWidgetID,
            onDrop: { sourceID in
                let targetColumn = effectiveColumn(for: widget)
                handleDrop(sourceID: sourceID, intoColumn: targetColumn, onto: widget.id)
            }
        ))
    }

    private func removeAnimated(_ widget: ProfileWidget) {
        guard let idx = vm.displayedWidgets.firstIndex(where: { $0.id == widget.id }) else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            vm.removeWidget(at: IndexSet([idx]))
        }
    }

    // A generic drop acceptor for plain-text UUID payloads.
    private func acceptDrop(providers: [NSItemProvider], handler: @escaping (UUID) -> Void) -> Bool {
        guard let provider = providers.first else { return false }
        _ = provider.loadObject(ofClass: NSString.self) { item, _ in
            guard let str = item as? String, let uuid = UUID(uuidString: str) else { return }
            DispatchQueue.main.async {
                handler(uuid)
                draggingWidgetID = nil
            }
        }
        return true
    }

    // Handle a drop of `sourceID` into `intoColumn`. If `onto` is provided,
    // insert the source at that position; otherwise append to end.
    private func handleDrop(sourceID: UUID, intoColumn column: WidgetColumn, onto targetID: UUID?) {
        guard sourceID != targetID else { return }
        guard vm.displayedWidgets.contains(where: { $0.id == sourceID }) else { return }

        // Assign the source to the target column (persisted).
        saveColumn(column, for: sourceID)

        // Compute the new flat order: iterate the target column's widgets in
        // their current order, inserting source before `targetID` if given or
        // at the end otherwise. Then splice those widgets back into the full
        // list while preserving the other column's order.
        let allSorted = vm.displayedWidgets.sorted(by: { $0.order < $1.order })
        var targetCol: [ProfileWidget] = []
        var otherCol: [ProfileWidget] = []

        for w in allSorted {
            if w.id == sourceID { continue }
            if effectiveColumn(for: w) == column {
                targetCol.append(w)
            } else {
                otherCol.append(w)
            }
        }

        guard let source = vm.displayedWidgets.first(where: { $0.id == sourceID }) else { return }

        if let targetID, let idx = targetCol.firstIndex(where: { $0.id == targetID }) {
            targetCol.insert(source, at: idx)
        } else {
            targetCol.append(source)
        }

        // Merge: interleave isn't meaningful here — we just concatenate with
        // target column first so left widgets keep appearing before right
        // widgets in the underlying `order`. Visual split happens in the
        // column computed properties anyway.
        let newOrder = otherCol + targetCol
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            vm.applyOrderedWidgets(newOrder)
        }
    }

    // MARK: - Left column pairing logic

    private struct LeftRow: Identifiable {
        enum Kind {
            case single(ProfileWidget)
            case pair(ProfileWidget, ProfileWidget)
        }
        let id: String
        let kind: Kind
    }

    private func buildLeftRows(from widgets: [ProfileWidget]) -> [LeftRow] {
        var rows: [LeftRow] = []
        var i = 0
        while i < widgets.count {
            let w = widgets[i]
            if w.type == .streak, i + 1 < widgets.count, widgets[i + 1].type == .wordsLearned {
                let right = widgets[i + 1]
                rows.append(LeftRow(id: "pair-\(w.id)-\(right.id)", kind: .pair(w, right)))
                i += 2
            } else if w.type == .wordsLearned, i + 1 < widgets.count, widgets[i + 1].type == .streak {
                let right = widgets[i + 1]
                rows.append(LeftRow(id: "pair-\(w.id)-\(right.id)", kind: .pair(w, right)))
                i += 2
            } else {
                rows.append(LeftRow(id: "single-\(w.id)", kind: .single(w)))
                i += 1
            }
        }
        return rows
    }
}

// MARK: - Drag/drop reorder helper

private struct DragReorderModifier: ViewModifier {
    let widgetID: UUID
    let isEnabled: Bool
    @Binding var draggingID: UUID?
    let onDrop: (UUID) -> Void

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .onDrag {
                    draggingID = widgetID
                    return NSItemProvider(object: widgetID.uuidString as NSString)
                }
                .onDrop(of: [.plainText], isTargeted: nil) { providers in
                    guard let provider = providers.first else {
                        draggingID = nil
                        return false
                    }
                    _ = provider.loadObject(ofClass: NSString.self) { item, _ in
                        guard let str = item as? String,
                              let uuid = UUID(uuidString: str) else { return }
                        DispatchQueue.main.async {
                            onDrop(uuid)
                            draggingID = nil
                        }
                    }
                    return true
                }
        } else {
            content
        }
    }
}

// MARK: - Add Widgets sheet (macOS)

struct MacAddWidgetsSheet: View {
    @ObservedObject var vm: ProfileWidgetsVM
    let onAdd: (WidgetType) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Add Widgets")
                    .font(.jakarta(size: 18, weight: .bold))
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(TFWidgetColors.darkerGray)
                        .padding(6)
                        .background(TFWidgetColors.pill)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 12)

            Rectangle()
                .fill(TFWidgetColors.border)
                .frame(height: 1)

            ScrollView {
                LazyVStack(spacing: 14) {
                    if vm.availableWidgets.isEmpty {
                        Text("All widgets already added")
                            .font(.jakarta(size: 14, weight: .regular))
                            .foregroundStyle(TFWidgetColors.textMuted)
                            .padding(.vertical, 40)
                    } else {
                        ForEach(vm.availableWidgets, id: \.self) { type in
                            AddWidgetCardView(type: type) {
                                onAdd(type)
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 520, height: 560)
        .background(Color.white)
    }
}
#endif
