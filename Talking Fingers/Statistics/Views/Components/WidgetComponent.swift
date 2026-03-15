import SwiftUI

struct WidgetComponent: View {
    var cornerRadius: CGFloat = 16
    var padding: CGFloat = 0
    var minHeight: CGFloat = 72
    var title: String? = nil
    var data: String = "No data yet"
    @State private var isPressed: Bool = false
    @State private var isHovering: Bool = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background material card
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.clear)
                .background(
                    .ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(.quaternary, lineWidth: 1)
                )
                .overlay(
                    // Subtle gradient tint for depth
                    LinearGradient(
                        colors: [Color.white.opacity(0.06), Color.black.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                )
                .shadow(color: Color.black.opacity(isPressed ? 0.05 : (isHovering ? 0.08 : 0.06)), radius: isPressed ? 2 : 6, x: 0, y: isPressed ? 1 : 3)

            VStack(alignment: .leading, spacing: 6) {
                if let title, !title.isEmpty {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                if !data.isEmpty {
                    Text(data)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.vertical, 12)
            .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
        .scaleEffect(1)
        .opacity(1)
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .padding(padding)
        #if os(macOS)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) { isHovering = hovering }
        }
        #endif
    }
}

#Preview("WidgetComponent") {
    VStack(spacing: 12) {
        WidgetComponent(title: "Widget Title", data: "42% complete")
    }
    .padding()
}

