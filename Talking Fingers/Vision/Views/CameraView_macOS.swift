//
//  CameraView_macOS.swift
//  Talking Fingers
//
//  Created by Jihoon Kim on 1/29/26.
//

#if os(macOS)
import SwiftUI
import AVFoundation
import AppKit

struct CameraView: View {
    @Environment(AuthenticationViewModel.self) var authVM

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 18) {
                    topStrip
                    headerArea
                    practiceSurface
                    bottomControlsRow
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)

                rightWidgetsColumn
            }
            .padding(28)
        }
        .toolbar {
        }
    }
}

private extension CameraView {
    var topStrip: some View {
        HStack {
            EmptyView()
            Spacer(minLength: 12)
            EmptyView()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
    }

    var headerArea: some View {
        VStack(alignment: .leading, spacing: 10) {
            EmptyView()
            EmptyView()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var practiceSurface: some View {
        PracticeSurfaceCardView {
            VStack(spacing: 18) {
                EmptyView()

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

struct CameraPreviewView: NSViewRepresentable {
    let session: AVCaptureSession
    var isMirrored: Bool = true

    final class VideoPreviewView: NSView {
        let previewLayer = AVCaptureVideoPreviewLayer()

        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            wantsLayer = true
            layer = CALayer()
            layer?.masksToBounds = true

            previewLayer.videoGravity = .resizeAspectFill
            layer?.addSublayer(previewLayer)
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            wantsLayer = true
            layer = CALayer()
            layer?.masksToBounds = true

            previewLayer.videoGravity = .resizeAspectFill
            layer?.addSublayer(previewLayer)
        }

        override func layout() {
            super.layout()
            previewLayer.frame = bounds
        }
    }

    func makeNSView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        configure(view)
        return view
    }

    func updateNSView(_ nsView: VideoPreviewView, context: Context) {
        configure(nsView)
    }

    private func configure(_ view: VideoPreviewView) {
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.previewLayer.frame = view.bounds

        if isMirrored {
            view.previewLayer.setAffineTransform(CGAffineTransform(scaleX: -1, y: 1))
        } else {
            view.previewLayer.setAffineTransform(.identity)
        }
    }
}

#Preview {
    CameraView()
        .environment(AuthenticationViewModel())
}
#endif
