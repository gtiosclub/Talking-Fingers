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
}
