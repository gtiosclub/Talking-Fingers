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
        case .a:
            return "A.gif"
        case .b:
            return "B.gif"
        case .c:
            return "C.gif"
        case .d:
            return "D.gif"
        case .e:
            return "E.gif"
        case .f:
            return "F.gif"
        case .g:
            return "G.gif"
        case .h:
            return "H.gif"
        case .i:
            return "I.gif"
        case .j:
            return "J.gif"
        case .k:
            return "K.gif"
        case .l:
            return "L.gif"
        case .m:
            return "M.gif"
        case .n:
            return "N.gif"
        case .o:
            return "O.gif"
        case .p:
            return "P.gif"
        case .q:
            return "Q.gif"
        case .r:
            return "R.gif"
        case .s:
            return "S.gif"
        case .t:
            return "T.gif"
        case .u:
            return "U.gif"
        case .v:
            return "V.gif"
        case .w:
            return "W.gif"
        case .x:
            return "X.gif"
        case .y:
            return "Y.gif"
        case .z:
            return "Z.gif"
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
