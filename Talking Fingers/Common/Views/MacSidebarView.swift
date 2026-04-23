//
//  MacSidebarView.swift
//  Talking Fingers
//
//  Custom macOS sidebar that replaces the default NavigationSplitView sidebar.
//  - Expanded: shows the full Talking Fingers logo (TF_full), user name, and
//    icon + label rows.
//  - Collapsed: shows the compact logo (TF_partial), a pfp dot, and icon-only
//    rows. Never collapses all the way to 0pt.
//

#if os(macOS)
import SwiftUI

struct MacSidebarView: View {
    @Binding var selection: MainNavigationView.NavigationSection
    @Binding var isCollapsed: Bool
    let userName: String

    static let expandedWidth: CGFloat = 220
    static let collapsedWidth: CGFloat = 68

    private var width: CGFloat { isCollapsed ? Self.collapsedWidth : Self.expandedWidth }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Leave room for the (hover-revealed) traffic lights.
            Color.clear.frame(height: 28)

            headerSection
                .padding(.horizontal, 14)
                .padding(.bottom, 18)

            userSection
                .padding(.horizontal, 14)
                .padding(.bottom, 22)

            navItemsSection
                .padding(.horizontal, 10)

            Spacer(minLength: 0)
        }
        .frame(width: width, alignment: .leading)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.white)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color(hex: "#E8E8E8"))
                .frame(width: 1)
        }
        .animation(.easeInOut(duration: 0.22), value: isCollapsed)
    }

    // MARK: - Header (logo + collapse toggle)

    @ViewBuilder
    private var headerSection: some View {
        if isCollapsed {
            // Logo stacked above the toggle so both stay centered in the
            // narrow column.
            VStack(spacing: 8) {
                logoImage(named: "TF_partial", height: 18)
                collapseToggle
            }
            .frame(maxWidth: .infinity)
        } else {
            HStack(spacing: 6) {
                logoImage(named: "TF_full", height: 18)
                Spacer(minLength: 0)
                collapseToggle
            }
            .frame(height: 24)
        }
    }

    private func logoImage(named name: String, height: CGFloat) -> some View {
        Image(name)
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: height)
            .foregroundColor(Color(hex: "#464646"))
    }

    private var collapseToggle: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.22)) { isCollapsed.toggle() }
        } label: {
            Image(systemName: "sidebar.left")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(hex: "#767676"))
                .padding(6)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(isCollapsed ? "Expand sidebar" : "Collapse sidebar")
    }

    // MARK: - User row (avatar + name)

    private var userSection: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color(hex: "#C7C7C7"))
                .frame(width: 22, height: 22)

            if !isCollapsed {
                Text(displayUserName)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.black)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: isCollapsed ? .center : .leading)
    }

    private var displayUserName: String {
        let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Jane Doe" : trimmed
    }

    // MARK: - Nav items

    private var navItemsSection: some View {
        VStack(spacing: 4) {
            ForEach(Self.items, id: \.section) { item in
                MacSidebarNavItem(
                    title: item.title,
                    systemImage: item.systemImage,
                    isSelected: selection == item.section,
                    isCollapsed: isCollapsed
                ) {
                    selection = item.section
                }
            }
        }
    }

    fileprivate struct Item {
        let section: MainNavigationView.NavigationSection
        let title: String
        let systemImage: String
    }

    fileprivate static let items: [Item] = [
        .init(section: .home,       title: "Home",          systemImage: "house"),
        .init(section: .flashcards, title: "Flashcards",    systemImage: "rectangle.stack"),
        .init(section: .sentences,  title: "Practice",      systemImage: "hand.wave"),
        .init(section: .stats,      title: "Profile",       systemImage: "person"),
        .init(section: .camera,     title: "Vision",        systemImage: "eyeglasses"),
        .init(section: .review,     title: "Review",        systemImage: "film.stack"),
        .init(section: .practice,   title: "Practice Test", systemImage: "pencil.and.scribble"),
    ]
}

// MARK: - Individual nav row

struct MacSidebarNavItem: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let isCollapsed: Bool
    let action: () -> Void

    @State private var isHovering = false

    private let selectedTint = Color(hex: "#2A7BBC")
    private let selectedBackground = Color(hex: "#E6F1FA")
    private let hoverBackground = Color(hex: "#F3F6F9")
    private let neutralText = Color(hex: "#1F1F1F")
    private let neutralIcon = Color(hex: "#464646")

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 22, alignment: .center)
                    .foregroundColor(isSelected ? selectedTint : neutralIcon)

                if !isCollapsed {
                    Text(title)
                        .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? selectedTint : neutralText)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: isCollapsed ? .center : .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(background)
            )
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { hovering in isHovering = hovering }
        .help(title)
    }

    private var background: Color {
        if isSelected { return selectedBackground }
        if isHovering { return hoverBackground }
        return .clear
    }
}
#endif
