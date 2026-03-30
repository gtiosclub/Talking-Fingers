//
//  CameraView_macOS.swift
//  Talking Fingers
//
//  Created by Jihoon Kim on 1/29/26.
//

#if os(macOS)
import SwiftUI

struct CameraView: View {
    @Environment(AuthenticationViewModel.self) var authVM

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            HStack(alignment: .top, spacing: 24) {
                // Main column (center)
                VStack(alignment: .leading, spacing: 18) {
                    topStrip
                    headerArea
                    practiceSurface
                    bottomControlsRow
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)

                // Right widgets column
                rightWidgetsColumn
            }
            .padding(28)
        }
        .toolbar {
            // Intentionally empty for now.
            // Teammates can add real toolbar items later without undoing layout work.
        }
    }
}

// MARK: - Sections

private extension CameraView {
    var topStrip: some View {
        HStack {
            // Leave area (empty)
            EmptyView()

            Spacer(minLength: 12)

            // Progress area (empty)
            EmptyView()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
    }

    var headerArea: some View {
        VStack(alignment: .leading, spacing: 10) {
            // "Try sign it out!" area (empty)
            EmptyView()

            // Big sentence area (empty)
            EmptyView()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var practiceSurface: some View {
        PracticeSurfaceCardView {
            VStack(spacing: 18) {
                // Tip chip area (empty)
                EmptyView()

                // Camera feed container (empty now; teammate can drop in their real view later)
                CameraFeedContainerView {
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(22)
        }
        .frame(maxWidth: 820, minHeight: 560)
    }

    var bottomControlsRow: some View {
        // Bottom icon row area (empty)
        HStack {
            Spacer()
            EmptyView()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    var rightWidgetsColumn: some View {
        VStack(spacing: 18) {
            WidgetCardView { EmptyView() }
                .frame(width: 260, height: 150)

            WidgetCardView { EmptyView() }
                .frame(width: 260, height: 150)

            WidgetCardView { EmptyView() }
                .frame(width: 260, height: 150)

            Spacer(minLength: 0)
        }
        .padding(.top, 44)
    }
}

// MARK: - Styled Containers (no placeholder text)

private struct PracticeSurfaceCardView<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .overlay { content() }
            .shadow(color: Color.black.opacity(0.25), radius: 18, x: 0, y: 8)
    }
}

private struct CameraFeedContainerView<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.white.opacity(0.03))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
            )
            .overlay { content() }
            .frame(maxWidth: 430, maxHeight: 330)
    }
}

private struct WidgetCardView<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .overlay { content() }
            .shadow(color: Color.black.opacity(0.20), radius: 14, x: 0, y: 6)
    }
}

#Preview {
    CameraView()
        .environment(AuthenticationViewModel())
}
#endif
