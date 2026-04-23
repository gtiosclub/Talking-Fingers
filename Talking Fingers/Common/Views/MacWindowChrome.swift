//
//  MacWindowChrome.swift
//  Talking Fingers
//
//  Configures the macOS window to have a transparent title bar with the
//  traffic-light buttons (close/minimize/zoom) visible in the top-left.
//  Content extends under the title bar for a clean, modern look.
//

#if os(macOS)
import SwiftUI
import AppKit

struct MacWindowChromeConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let probe = WindowProbe()
        return probe
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    /// A zero-size view whose only job is to find its parent `NSWindow` on
    /// first layout and configure it.
    final class WindowProbe: NSView {
        private var didConfigure = false

        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            self.translatesAutoresizingMaskIntoConstraints = false
        }

        required init?(coder: NSCoder) { fatalError() }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard !didConfigure, let window = self.window else { return }
            didConfigure = true
            configureWindow(window)
        }

        private func configureWindow(_ w: NSWindow) {
            w.styleMask.insert(.fullSizeContentView)
            w.titlebarAppearsTransparent = true
            w.titleVisibility = .hidden
            w.isMovableByWindowBackground = true
        }
    }
}

extension View {
    /// Configure the enclosing macOS window to have a transparent title bar
    /// with content extending underneath. Traffic lights remain visible and
    /// functional. No-op on other platforms.
    @ViewBuilder
    func configureMacWindowChrome() -> some View {
        self.background(
            MacWindowChromeConfigurator()
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
        )
    }
}
#else
import SwiftUI

extension View {
    func configureMacWindowChrome() -> some View { self }
}
#endif
