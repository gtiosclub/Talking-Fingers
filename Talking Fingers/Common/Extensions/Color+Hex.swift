//
//  Color+Hex.swift
//  Talking Fingers
//
//  Color extension for initializing from hex strings.
//

import SwiftUI

extension Color {
    /// Creates a `Color` from a hex string (e.g. `"#FF5733"`, `"FF5733"`, `"#FF5733AA"`).
    /// - Parameter hex: Hex string with optional leading `#`. Supports 6-digit RGB and 8-digit RGBA.
    /// - Returns: A `Color`, or `nil` if the string is invalid.
    init?(hex: String) {
        let cleaned = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        let length = cleaned.count

        guard length == 6 || length == 8 else { return nil }

        var hexNumber: UInt64 = 0
        guard Scanner(string: cleaned).scanHexInt64(&hexNumber) else { return nil }

        let r, g, b, a: Double
        if length == 8 {
            r = Double((hexNumber >> 24) & 0xFF) / 255
            g = Double((hexNumber >> 16) & 0xFF) / 255
            b = Double((hexNumber >> 8) & 0xFF) / 255
            a = Double(hexNumber & 0xFF) / 255
        } else {
            r = Double((hexNumber >> 16) & 0xFF) / 255
            g = Double((hexNumber >> 8) & 0xFF) / 255
            b = Double(hexNumber & 0xFF) / 255
            a = 1
        }
        self.init(red: r, green: g, blue: b, opacity: a)
    }

    /// Creates a `Color` from a hex integer (e.g. `0xFF5733` for RGB, or 32-bit ARGB).
    /// - Parameter hex: 24-bit RGB or 32-bit ARGB (alpha in high byte) value.
    /// - Parameter alpha: Optional alpha (0...1). If `nil`, 24-bit uses 1; 32-bit uses the high byte.
    init(hex: UInt32, alpha: Double? = nil) {
        let hasAlpha = hex > 0xFFFFFF
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double((hex >> 0) & 0xFF) / 255
        let a: Double
        if let alpha = alpha {
            a = alpha
        } else {
            a = hasAlpha ? Double((hex >> 24) & 0xFF) / 255 : 1
        }
        self.init(red: r, green: g, blue: b, opacity: a)
    }
}
