//
//  ProfileWidgetsView.swift
//  Talking Fingers
//
//  Created by Assistant on 4/19/26.
//

import SwiftUI

enum TFWidgetColors {
    static let gold = Color(hex: 0xF8BC3A)
    static let black = Color(hex: 0x000000)
    static let green = Color(hex: 0x97C171)
    static let gray = Color(hex: 0xAFAFAF)
    static let paleGold = Color(hex: 0xFDF2D8)
    static let paleGreen = Color(hex: 0xEAF3E3)
    static let white = Color(hex: 0xFFFFFF)
    static let lightBlue = Color(hex: 0xA9CEEC)
    static let trackBlue = Color(hex: 0xD9E5EF)
    static let darkGray = Color(hex: 0x5A5A5A)
    static let darkerGray = Color(hex: 0x464646)
    static let blue = Color(hex: 0x58A0DA)
    static let border = Color(hex: 0xDDDDDD)
    static let pill = Color(hex: 0xEEEEEE)
    static let offWhite = Color(hex: 0xF7F7F7)
    static let iconGray = Color(hex: 0x777777)
    static let lockGray = Color(hex: 0x8B8B8B)
    static let badgeLockedBg = Color(hex: 0xEFEFEF)
    
    // Chart accents
    static let chartPlotFill = Color(hex: 0xDBEFFF)
    static let chartBarStroke = Color(hex: 0x52A0DF)
    static let practiceGreen = Color(hex: 0xADCE8F)
    static let textMuted = Color(hex: 0x646464)
    static let textDark = Color(hex: 0x434343)
    static let controlGray = Color(hex: 0x646464)
}

#if os(iOS)
struct ProfileWidgetsView: View {
    enum PresentationStyle {
        case profile
        case embedded
    }
    
    private enum ScreenMode {
        case regular
        case edit
        case add
    }
    
    @StateObject private var vm = ProfileWidgetsVM()
    @State private var mode: ScreenMode = .regular
    @Environment(AuthenticationViewModel.self) var authVM
    @State private var showProfile = false
    
    private let presentation: PresentationStyle
    
    init(presentation: PresentationStyle = .profile) {
        self.presentation = presentation
    }
    
    var body: some View {
        ZStack {
            TFWidgetColors.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                switch mode {
                case .add:
                    AddWidgetsScreen(
                        vm: vm,
                        onBack: { mode = .edit },
                        onDone: { mode = .edit }
                    )
                case .regular, .edit:
                    topBar
                    actionRow
                    
                    Rectangle()
                        .fill(TFWidgetColors.border)
                        .frame(height: 1)
                        .padding(.horizontal, 16)
                    
                    List {
                        ForEach(widgetRows, id: \.id) { row in
                            switch row.kind {
                            case .pair(let left, let right):
                                HStack(spacing: 12) {
                                    WidgetCardView(
                                        widget: left,
                                        isEditMode: isEditMode,
                                        onRemove: { remove(left) }
                                    )
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 96)
                                    
                                    WidgetCardView(
                                        widget: right,
                                        isEditMode: isEditMode,
                                        onRemove: { remove(right) }
                                    )
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 96)
                                }
                                .listRowInsets(.init(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                
                            case .single(let widget):
                                WidgetCardView(
                                    widget: widget,
                                    isEditMode: isEditMode,
                                    onRemove: { remove(widget) }
                                )
                                .listRowInsets(.init(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            }
                        }
                        .onMove(perform: moveRows)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .environment(\.editMode, .constant(isEditMode ? .active : .inactive))
                    .padding(.vertical, 8)
                }
            }
            
            if showProfile {
                ZStack {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                        .onTapGesture { withAnimation(.easeInOut(duration: 0.2)) { showProfile = false } }
                    profileSheet(onClose: { withAnimation(.easeInOut(duration: 0.2)) { showProfile = false } })
                        .environment(authVM)
                        .background(TFWidgetColors.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.black.opacity(0.2), radius: 16, x: 0, y: 8)
                        .transition(.scale.combined(with: .opacity))
                }
                .animation(.easeInOut(duration: 0.2), value: showProfile)
            }
        }
    }
    
    private var topBar: some View {
        HStack {
            Text("Profile")
                .font(.system(size: 34, weight: .bold))
                .fontWeight(.bold)
            Spacer()
            Button {showProfile.toggle()} label : {
                Image(systemName: "person.circle")
                    .font(.system(size: 26, weight: .regular))
                    .foregroundStyle(TFWidgetColors.black)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }
    struct profileSheet: View {
        let onClose: () -> Void
        @Environment(AuthenticationViewModel.self) var authVM
        var body: some View {
            VStack(spacing: 0) {
                // Header with dismiss button on the top-right
                HStack {
                    Spacer()
                    Button(action: { onClose() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(TFWidgetColors.black)
                            .padding(8)
                            .background(TFWidgetColors.pill)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding([.top, .horizontal], 12)

                // Content
                VStack(spacing: 12) {
                    Text(authVM.currentUser?.name ?? "Loading...")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(TFWidgetColors.black)

                    Button(action: { authVM.signOut(); onClose() }) {
                        Text("Log Out")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(TFWidgetColors.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
            }
            .frame(width: 280)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, 16)
        }
    }
    
    private var actionRow: some View {
        HStack {
            if isEditMode {
                Button(action: { mode = .add }) {
                    Text("Add Widgets")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(TFWidgetColors.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(TFWidgetColors.pill)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                Spacer()
                Button(action: { mode = .regular }) {
                    Text("Done")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(TFWidgetColors.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(TFWidgetColors.pill)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            } else {
                Button(action: { mode = .edit }) {
                    Text("Edit Widgets")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(TFWidgetColors.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(TFWidgetColors.pill)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                Spacer()
                Text(formattedToday)
                    .font(.subheadline)
                    .foregroundStyle(TFWidgetColors.darkerGray)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    private struct WidgetRow: Identifiable {
        enum Kind {
            case single(ProfileWidget)
            case pair(ProfileWidget, ProfileWidget)
        }
        
        let id: String
        let kind: Kind
    }
    
    private var widgetRows: [WidgetRow] {
        buildWidgetRows(from: vm.displayedWidgets.sorted(by: { $0.order < $1.order }))
    }
    
    private func buildWidgetRows(from widgets: [ProfileWidget]) -> [WidgetRow] {
        var rows: [WidgetRow] = []
        var i = 0
        
        while i < widgets.count {
            let w = widgets[i]
            
            if w.type == .streak, i + 1 < widgets.count, widgets[i + 1].type == .wordsLearned {
                let left = w
                let right = widgets[i + 1]
                rows.append(
                    WidgetRow(
                        id: "pair:\(left.id.uuidString):\(right.id.uuidString)",
                        kind: .pair(left, right)
                    )
                )
                i += 2
                continue
            }
            
            rows.append(WidgetRow(id: "single:\(w.id.uuidString)", kind: .single(w)))
            i += 1
        }
        
        return rows
    }
    
    private func expandedWidgets(from rows: [WidgetRow]) -> [ProfileWidget] {
        var out: [ProfileWidget] = []
        out.reserveCapacity(rows.count * 2)
        
        for row in rows {
            switch row.kind {
            case .single(let w):
                out.append(w)
            case .pair(let a, let b):
                out.append(a)
                out.append(b)
            }
        }
        
        return out
    }
    
    private func moveRows(from source: IndexSet, to destination: Int) {
        var rows = widgetRows
        rows.move(fromOffsets: source, toOffset: destination)
        
        let newWidgets = expandedWidgets(from: rows)
        guard newWidgets.count == vm.displayedWidgets.count else { return }
        
        vm.applyOrderedWidgets(newWidgets)
    }
    
    private func widget(_ type: WidgetType) -> ProfileWidget? {
        vm.displayedWidgets.first { $0.type == type }
    }
    
    private var isEditMode: Bool { mode == .edit }
    
    private func remove(_ widget: ProfileWidget) {
        guard let index = vm.displayedWidgets.firstIndex(where: { $0.id == widget.id }) else { return }
        vm.removeWidget(at: IndexSet([index]))
    }
    
    private var formattedToday: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
}
#endif

struct ProfileHeaderView: View {
    let user: User?
    
    var body: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 80, height: 80)
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
            }
            
            // Name and Email
            VStack(spacing: 4) {
                Text(user?.name ?? "User")
                    .font(.title)
                    .fontWeight(.semibold)
                Text(user?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }
}

struct WidgetCardView: View {
    let widget: ProfileWidget
    let isEditMode: Bool
    let onRemove: () -> Void
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 12) {
                if !widgetTitle.isEmpty {
                    HStack {
                        Text(widgetTitle)
                            .font(.headline)
                            .foregroundStyle(TFWidgetColors.black)
                        Spacer()
                        if widget.type == .dailyChallenge {
                            DailyChallengeHeaderTrailing()
                        } else if showsAccessory {
                            Image(systemName: accessoryIcon)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(widget.type == .masteryBadges ? TFWidgetColors.gray : TFWidgetColors.iconGray)
                                .padding(7)
                                .background(widget.type == .masteryBadges ? TFWidgetColors.white : TFWidgetColors.pill)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(TFWidgetColors.border, lineWidth: 1)
                                )
                        }
                    }
                }
                
                // Content
                switch widget.type {
                case .streak:
                    StreakWidgetContent()
                case .wordsLearned:
                    WordsLearnedWidgetContent()
                case .recentProgress:
                    RecentProgressWidgetContent()
                case .dailyChallenge:
                    DailyChallengeWidgetContent()
                case .masteryBadges:
                    MasteryBadgesWidgetContent()
                case .weeklyActivity:
                    WeeklyActivityWidgetContent()
                case .accuracy:
                    AccuracyWidgetContent()
                }
            }
            .padding(widgetTitle.isEmpty ? 14 : 16)
            .background(TFWidgetColors.white)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(TFWidgetColors.border, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
            
            // Remove button
            if isEditMode && isRemovable {
                Button(action: onRemove) {
                    ZStack {
                        Circle()
                            .fill(TFWidgetColors.controlGray)
                            .frame(width: 24, height: 24)
                        Image(systemName: "minus")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
                .offset(x: -8, y: -8)
            }
        }
        .modifier(WidgetWiggleModifier(isActive: isEditMode))
    }
    
    private var isRemovable: Bool {
        true
    }
    
    private var showsAccessory: Bool {
        widget.type == .weeklyActivity || widget.type == .accuracy || widget.type == .masteryBadges
    }
    
    private var accessoryIcon: String {
        switch widget.type {
        case .weeklyActivity, .accuracy, .masteryBadges:
            return "chevron.right"
        default:
            return "chevron.right"
        }
    }
    
    private var widgetTitle: String {
        switch widget.type {
        case .wordsLearned:
            return ""
        case .recentProgress:
            return "Recent Progress"
        case .dailyChallenge:
            return "Daily Challenge"
        case .masteryBadges:
            return "Mastery Badges"
        case .weeklyActivity:
            return "Weekly Activity"
        case .accuracy:
            return "Accuracy"
        case .streak:
            return ""
        }
    }
}

// Home-screen style jiggle applied to each widget card while edit mode is on.
// Small per-widget phase offset keeps neighbours out of sync.
struct WidgetWiggleModifier: ViewModifier {
    let isActive: Bool
    @State private var angle: Double = 0

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(angle))
            .task(id: isActive) {
                if isActive {
                    angle = Double.random(in: 0.2...0.4)
                    try? await Task.sleep(nanoseconds: UInt64.random(in: 0...120_000_000))
                    guard !Task.isCancelled else { return }
                    withAnimation(
                        .easeInOut(duration: 0.15)
                            .repeatForever(autoreverses: true)
                    ) {
                        angle = -0.4
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.18)) { angle = 0 }
                }
            }
    }
}

private struct DailyChallengeHeaderTrailing: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(TFWidgetColors.gold)
            Text("2 Day Streak")
                .font(.subheadline)
                .foregroundStyle(TFWidgetColors.black)
        }
    }
}

struct AddWidgetsScreen: View {
    @ObservedObject var vm: ProfileWidgetsVM
    let onBack: () -> Void
    let onDone: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(vm.availableWidgets, id: \.self) { type in
                        AddWidgetCardView(type: type, onAdd: {
                            vm.addWidget(type: type)
                        })
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
        .background(TFWidgetColors.white.ignoresSafeArea())
    }
    
    private var header: some View {
        ZStack {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(TFWidgetColors.black)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 8)
                }
                .buttonStyle(.plain)
                Spacer()
                Button(action: onDone) {
                    Text("Done")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(TFWidgetColors.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(TFWidgetColors.pill)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            
            Text("Add Widgets")
                .font(.headline)
                .foregroundStyle(TFWidgetColors.black)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 6)
        .background(TFWidgetColors.white)
    }
}

struct StreakWidgetContent: View {
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "flame.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(TFWidgetColors.gold)
            VStack(alignment: .leading, spacing: 4) {
                Text("10")
                    .font(.system(size: 28, weight: .bold))
                    .fontWeight(.bold)
                Text("days in a row")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(TFWidgetColors.darkerGray)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct WordsLearnedWidgetContent: View {
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "book.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(TFWidgetColors.gold)
            VStack(alignment: .leading, spacing: 4) {
                Text("67")
                    .font(.system(size: 28, weight: .bold))
                    .fontWeight(.bold)
                Text("words learned")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(TFWidgetColors.darkerGray)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct RecentProgressWidgetContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "medal")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(TFWidgetColors.lightBlue)
                Text("People")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(TFWidgetColors.textMuted)
                Spacer()
            }
            
            HStack(spacing: 10) {
                GeometryReader { proxy in
                    let w = proxy.size.width
                    let h: CGFloat = 10
                    let progress: CGFloat = 0.27
                    let fillW = max(0, w * progress)
                    
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(TFWidgetColors.trackBlue)
                        Capsule()
                            .fill(TFWidgetColors.blue)
                            .frame(width: fillW)
                    }
                    .frame(height: h)
                }
                .frame(height: 10)
                
                Text("27%")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(TFWidgetColors.black)
                    .frame(width: 44, alignment: .trailing)
            }
        }
    }
}

struct DailyChallengeWidgetContent: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ForEach(Array(["M", "T", "W", "T", "F", "S", "S"].enumerated()), id: \.offset) { index, day in
                    let isOn = index <= 2
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(isOn ? TFWidgetColors.paleGreen : TFWidgetColors.badgeLockedBg)
                                .overlay(
                                    Circle()
                                        .stroke(isOn ? TFWidgetColors.green : TFWidgetColors.gray, lineWidth: 1.2)
                                )
                                .frame(width: 34, height: 34)
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(isOn ? TFWidgetColors.green : TFWidgetColors.gray)
                        }
                        Text(day)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(TFWidgetColors.darkerGray)
                    }
                }
            }
        }
    }
}

struct MasteryBadgesWidgetContent: View {
    var body: some View {
        GeometryReader { proxy in
            let horizontalPadding: CGFloat = 2
            let interItem: CGFloat = 10
            let columns: CGFloat = 4
            let usableWidth = max(0, proxy.size.width - horizontalPadding * 2 - interItem * (columns - 1))
            // Cap tile size so two rows + labels don't overflow at wide macOS windows.
            let side = min(floor(usableWidth / columns), 100)
            
            VStack(spacing: 14) {
                HStack(spacing: interItem) {
                    MasteryBadgeItem(isLocked: false, side: side)
                    MasteryBadgeItem(isLocked: false, side: side)
                    MasteryBadgeItem(isLocked: false, side: side)
                    MasteryBadgeItem(isLocked: false, side: side)
                }
                HStack(spacing: interItem) {
                    MasteryBadgeItem(isLocked: false, side: side)
                    MasteryBadgeItem(isLocked: true, side: side)
                    MasteryBadgeItem(isLocked: true, side: side)
                    MasteryBadgeItem(isLocked: true, side: side)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, horizontalPadding)
            .padding(.bottom, 6)
        }
        .frame(minHeight: 198)
    }
}

struct MasteryBadgeItem: View {
    let isLocked: Bool
    let side: CGFloat
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isLocked ? TFWidgetColors.badgeLockedBg : TFWidgetColors.paleGold)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(isLocked ? TFWidgetColors.gray : TFWidgetColors.gold, lineWidth: 1)
                    )
                    .frame(width: side, height: side)
                
                Image(systemName: isLocked ? "lock.fill" : "trophy")
                    .font(.system(size: min(22, side * 0.42), weight: .semibold))
                    .foregroundStyle(isLocked ? TFWidgetColors.textDark : TFWidgetColors.gold)
            }
            Text("Name")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(TFWidgetColors.textMuted)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct WeeklyActivityWidgetContent: View {
    var body: some View {
        WeeklyActivityChartView()
    }
}

struct AccuracyWidgetContent: View {
    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 12) {
                AccuracyRow(label: "Alphabet", percentage: 85)
                AccuracyRow(label: "Numbers", percentage: 93)
                AccuracyRow(label: "Greetings", percentage: 76)
                AccuracyRow(label: "Food", percentage: 66)
            }
            
            HStack(alignment: .center) {
                Text("Review Again?")
                    .font(.subheadline)
                    .foregroundStyle(TFWidgetColors.black)
                Spacer()
                Button(action: {}) {
                    Text("Practice")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TFWidgetColors.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(TFWidgetColors.practiceGreen)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct AccuracyRow: View {
    let label: String
    let percentage: Int
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Text(label)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(TFWidgetColors.textDark)
                .frame(width: 92, alignment: .leading)
            
            GeometryReader { proxy in
                let w = proxy.size.width
                let h: CGFloat = 10
                let fillW = max(0, w * CGFloat(percentage) / 100)
                
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(TFWidgetColors.chartPlotFill)
                    Capsule()
                        .fill(TFWidgetColors.blue)
                        .frame(width: fillW)
                }
                .frame(height: h)
                .overlay(
                    Capsule()
                        .stroke(TFWidgetColors.chartBarStroke.opacity(0.35), lineWidth: 1)
                )
            }
            .frame(height: 10)
            
            Text("\(percentage)%")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(TFWidgetColors.textMuted)
                .frame(width: 44, alignment: .trailing)
        }
    }
}

private struct WeeklyActivityChartView: View {
    private let days = ["M", "T", "W", "T", "F", "S", "S"]
    private let minutes = [35, 30, 10, 52, 35, 12, 30]
    private let yTicks = [60, 45, 30, 15, 0]
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .trailing, spacing: 0) {
                Text("time")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(TFWidgetColors.textMuted)
                    .rotationEffect(.degrees(-90))
                    .fixedSize()
                Text("(minutes)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(TFWidgetColors.textMuted)
                    .rotationEffect(.degrees(-90))
                    .fixedSize()
                    .padding(.top, 2)
            }
            .frame(width: 22)
            
            VStack(alignment: .leading, spacing: 10) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(TFWidgetColors.chartPlotFill.opacity(0.55))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(TFWidgetColors.border, lineWidth: 1)
                        )
                    
                    HStack(alignment: .top, spacing: 0) {
                        VStack(alignment: .trailing, spacing: 0) {
                            ForEach(yTicks, id: \.self) { tick in
                                Text("\(tick)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(TFWidgetColors.textMuted)
                                    .frame(height: chartInnerHeight / CGFloat(yTicks.count - 1), alignment: .top)
                            }
                        }
                        .frame(width: 30, alignment: .trailing)
                        .padding(.leading, 6)
                        .padding(.top, 6)
                        
                        VStack(spacing: 0) {
                            ForEach(0..<(yTicks.count - 1), id: \.self) { _ in
                                Rectangle()
                                    .fill(TFWidgetColors.gray.opacity(0.25))
                                    .frame(height: 1)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 6)
                                    .frame(height: chartInnerHeight / CGFloat(yTicks.count - 1), alignment: .top)
                            }
                        }
                        .padding(.top, 6)
                        .frame(maxWidth: .infinity)
                    }
                    
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(days.indices, id: \.self) { index in
                            let value = minutes[index]
                            let barH = max(6, chartInnerHeight * CGFloat(value) / 60)
                            
                            VStack(spacing: 8) {
                                Spacer(minLength: 0)
                                
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(TFWidgetColors.lightBlue)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .stroke(TFWidgetColors.chartBarStroke, lineWidth: 1)
                                    )
                                    .frame(height: barH)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.leading, 40)
                    .padding(.trailing, 10)
                    .padding(.top, 6)
                    .padding(.bottom, 26)
                }
                .frame(height: chartOuterHeight)
                
                HStack(spacing: 8) {
                    ForEach(days.indices, id: \.self) { index in
                        Text(days[index])
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(TFWidgetColors.textMuted)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 6)
            }
        }
    }
    
    private var chartOuterHeight: CGFloat { 170 }
    private var chartInnerHeight: CGFloat { chartOuterHeight - 32 }
}

#if os(iOS)
struct AddWidgetsView: View {
    @ObservedObject var vm: ProfileWidgetsVM
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(vm.availableWidgets, id: \.self) { type in
                        AddWidgetCardView(type: type, onAdd: {
                            vm.addWidget(type: type)
                            isPresented = false
                        })
                    }
                }
                .padding()
            }
            .navigationTitle("Add Widgets")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button(action: {
                isPresented = false
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.blue)
            })
        }
    }
}
#endif

struct AddWidgetCardView: View {
    let type: WidgetType
    let onAdd: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(type.rawValue)
                        .font(.headline)
                        .foregroundStyle(TFWidgetColors.black)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(TFWidgetColors.gray)
                        .padding(7)
                        .background(TFWidgetColors.white)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(TFWidgetColors.border, lineWidth: 1)
                        )
                }
                
                // Content
                switch type {
                case .weeklyActivity:
                    WeeklyActivityPreview()
                case .accuracy:
                    AccuracyPreview()
                default:
                    EmptyView()
                }
            }
            .padding()
            .background(TFWidgetColors.white)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(TFWidgetColors.border, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
            
            // Plus button
            Button(action: onAdd) {
                ZStack {
                    Circle()
                        .fill(TFWidgetColors.controlGray)
                        .frame(width: 32, height: 32)
                    Image(systemName: "plus")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .offset(x: 8, y: -8)
        }
    }
}

struct WeeklyActivityPreview: View {
    var body: some View {
        WeeklyActivityChartView()
    }
}

struct AccuracyPreview: View {
    var body: some View {
        VStack(spacing: 12) {
            AccuracyRow(label: "Alphabet", percentage: 85)
            AccuracyRow(label: "Numbers", percentage: 93)
            AccuracyRow(label: "Greetings", percentage: 76)
            AccuracyRow(label: "Food", percentage: 66)
            
            HStack(alignment: .center) {
                Text("Review Again?")
                    .font(.subheadline)
                    .foregroundStyle(TFWidgetColors.black)
                Spacer()
                Button(action: {}) {
                    Text("Practice")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TFWidgetColors.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(TFWidgetColors.practiceGreen)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}



#if os(iOS)
#Preview {
    ProfileWidgetsView()
}
#endif

