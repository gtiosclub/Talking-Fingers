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
        case .ten:
            return "ten.gif"
        case .fifteen:
            return "fifteen.gif"
        case .twenty:
            return "twenty.gif"
        case .hundred:
            return "hundred.gif"
        case .hello:
            return "hello.gif"
        case .bye:
            return "bye.gif"
        case .hi:
            return "hi.gif"
        case .good:
            return "good.gif"
        case .morning:
            return "morning.gif"
        case .afternoon:
            return "afternoon.gif"
        case .evening:
            return "evening.gif"
        case .night:
            return "night.gif"
        case .see:
            return "see.gif"
        case .you:
            return "you.gif"
        case .later:
            return "later.gif"
        case .nice:
            return "nice.gif"
        case .meet:
            return "meet.gif"
        case .how:
            return "how.gif"
//        case .whatUp:
//            return "whatUp.gif"
        case .sorry:
            return "sorry.gif"
        case .up:
            return "up.gif"
        case .go:
            return "go.gif"
        case .he:
            return "he.gif"
        case .her:
            return "her.gif"
        case .his:
            return "his.gif"
        case .its:
            return "its.gif"
        case .it:
            return "it.gif"
        case .she:
            return "she.gif"
        case .me:
            return "me.gif"
        case .my:
            return "my.gif"
        case .our:
            return "our.gif"
        case .their:
            return "their.gif"
        case .they:
            return "they.gif"
        case .we:
            return "we.gif"
        case .your:
            return "your.gif"
        case .when:
            return "when.gif"
        case .where:
            return "where.gif"
        case .who:
            return "who.gif"
        case .why:
            return "why.gif"
        case .student:
            return "student.gif"
        case .work:
            return "work.gif"
        case .like:
            return "like.gif"
        case .live:
            return "live.gif"
        case .age:
            return "age.gif"
        case .favorite:
            return "favorite.gif"
        case .name:
            return "name.gif"
        case .what:
            return "what.gif"
        case .son:
            return "son.gif"
        case .daughter:
            return "daughter.gif"
        case .grandson:
            return "grandson.gif"
        case .granddaughter:
            return "granddaughter.gif"
        case .grandchild:
            return "grandchild.gif"

        
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
