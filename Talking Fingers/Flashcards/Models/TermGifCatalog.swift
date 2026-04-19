//
//  TermGifCatalog.swift
//  Talking Fingers
//
//  Maps flashcard terms to bundled GIF files. Add new entries here as GIF
//  assets are downloaded and converted.
//

import Foundation

enum TermGifCatalog {
    static func gifFileName(for term: Term) -> String? {
        switch term {
        case .hello:
            return "helloGIF.gif"
        case .zero:
            return "zero.gif"
        case .one:
            return "one.gif"
        case .two:
            return "two.gif"
        case .three:
            return "three.gif"
        case .four:
            return "four.gif"
        case .five:
            return "five.gif"
        case .six:
            return "six.gif"
        case .seven:
            return "seven.gif"
        case .eight:
            return "eight.gif"
        case .nine:
            return "nine.gif"
        default:
            return nil
        }
    }
}

extension Term {
    var defaultGifFileName: String? {
        TermGifCatalog.gifFileName(for: self)
    }
}
