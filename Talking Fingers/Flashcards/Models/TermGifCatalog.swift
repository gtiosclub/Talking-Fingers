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
