//
//  QwenTokenizer.swift
//  Talking Fingers
//
//  Created by Krish Prasad on 2/15/26.
//

//import Foundation
//
//final class QwenTokenizer {
//    private var idToToken: [Int: String] = [:]
//    private var tokenToId: [String: Int] = [:]
//
//    init() {
//        loadTokenizer()
//    }
//
//    private func loadTokenizer() {
//        guard let url = Bundle.main.url(forResource: "tokenizer", withExtension: "json"),
//              let data = try? Data(contentsOf: url),
//              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
//              let model = json["model"] as? [String: Any],
//              let vocab = model["vocab"] as? [String: Int] else {
//            fatalError("Failed to load tokenizer.json")
//        }
//
//        for (token, id) in vocab {
//            tokenToId[token] = id
//            idToToken[id] = token
//        }
//
//        print("✅ Tokenizer loaded with \(vocab.count) tokens")
//    }
//
//    func encode(_ text: String) -> [Int32] {
//        let words = text.split(separator: " ")
//        var tokens: [Int32] = []
//
//        for word in words {
//            let token = String(word)
//            if let id = tokenToId[token] {
//                tokens.append(Int32(id))
//            } else if let unknown = tokenToId["<unk>"] {
//                tokens.append(Int32(unknown))
//            }
//        }
//
//        return tokens
//    }
//
//    func decode(_ tokens: [Int32]) -> String {
//        var text = ""
//
//        for token in tokens {
//            if let piece = idToToken[Int(token)] {
//                text += piece
//            }
//        }
//
//        return text
//    }
//}
