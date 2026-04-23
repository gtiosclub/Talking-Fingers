import SwiftUI

/* .textInputAutocapitalization() is a function that only applies to iOS as it's a part of UIKit
 Thus, if we have that in our code and try to build for a mac target, the build fails.
 Instead we can make our own function called universalAutocapitalization like below.
 Now, if we build on an iPhone, it functions just like the old function and if we build
 on a mac, it won't do anything because we don't need autocapitalization.
*/
// MARK: - Types
#if os(iOS)
typealias UniversalAutocapitalizationStyle = TextInputAutocapitalization // .textInputAutocapitalization replacement
#else
/// Placeholder for macOS to allow code to compile without UIKit
enum UniversalAutocapitalizationStyle {
    case never, words, sentences, characters
}
#endif

// MARK: - View Extensions
extension View {
    /// Applies autocapitalization on iOS and ignores it on macOS
    func universalAutocapitalization(_ style: UniversalAutocapitalizationStyle) -> some View {
        #if os(iOS)
        return self.textInputAutocapitalization(style)
        #else
        return self
        #endif
    }
    
    /// Helper to apply padding or frames specifically for the Mac
    @ViewBuilder
    func macOnly(padding: CGFloat) -> some View {
        #if os(macOS)
        self.padding(padding)
        #else
        self
        #endif
    }

    /// Helper to apply horizontal padding only on iOS; no-op on macOS.
    @ViewBuilder
    func iosOnly(horizontalPadding: CGFloat) -> some View {
        #if os(iOS)
        self.padding(.horizontal, horizontalPadding)
        #else
        self
        #endif
    }

    @ViewBuilder
    func universalFullScreenCover<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        #if os(iOS)
        self.fullScreenCover(isPresented: isPresented, content: content)
        #else
        self.overlay(alignment: .topLeading) {
            if isPresented.wrappedValue {
                content()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(nsColor: .windowBackgroundColor))
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isPresented.wrappedValue)
        #endif
    }

    @ViewBuilder
    func macCentered(widthFraction: CGFloat = 0.75) -> some View {
        #if os(macOS)
        GeometryReader { proxy in
            self
                .frame(width: proxy.size.width * widthFraction)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        #else
        self
        #endif
    }
}

#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
typealias PlatformColor = UIColor
#elseif canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
typealias PlatformColor = NSColor
#endif

func loadImage(baseName: String, ext: String) -> PlatformImage? {
    guard let url = Bundle.main.url(forResource: baseName, withExtension: ext) else {
        return nil
    }

    #if canImport(UIKit)
    return UIImage(contentsOfFile: url.path)
    #elseif canImport(AppKit)
    return NSImage(contentsOf: url)
    #else
    return nil
    #endif
}

extension View {
    @ViewBuilder
    func universalImage(baseName: String, ext: String, height: CGFloat = 250) -> some View {
            if let img = loadImage(baseName: baseName, ext: ext) {
                #if canImport(UIKit)
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(height: height)
                #elseif canImport(AppKit)
                Image(nsImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(height: height)
                #endif
            }
        }
    }

extension Color {
    static var categoryComponentColor: Color {
        #if canImport(UIKit)
        Color(UIColor.systemGroupedBackground)
        #elseif canImport(AppKit)
        Color(NSColor.windowBackgroundColor)
        #endif
    }
}

extension Color {
    static var tfSurface: Color {
        #if canImport(UIKit)
        return Color(PlatformColor.systemGray6)
        #elseif canImport(AppKit)
        return Color(PlatformColor.controlBackgroundColor)
        #else
        return Color.gray.opacity(0.12)
        #endif
    }
}
