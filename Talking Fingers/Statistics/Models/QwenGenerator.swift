//
//  QwenGenerator.swift
//  Talking Fingers
//
//  Created by Krish Prasad on 2/15/26.
//

import Foundation
import CoreML

final class QwenGenerator {

    private let model: QwenSentenceGen
    private let tokenizer = QwenTokenizer()

    private let maxSequenceLength = 128
    private let vocabSize = 151_936

    init() {
        let config = MLModelConfiguration()
        config.computeUnits = .all

        do {
            model = try QwenSentenceGen(configuration: config)
            print("✅ Qwen model loaded")
        } catch {
            fatalError("Failed to load model: \(error)")
        }
    }


    func generate(prompt: String, maxNewTokens: Int = 20) -> String {

        var tokens = tokenizer.encode(prompt)

        for _ in 0..<maxNewTokens {
            guard tokens.count < maxSequenceLength else { break }

            guard let next = predictNextToken(tokens: tokens) else { break }
            tokens.append(next)
        }

        return tokenizer.decode(tokens)
    }

    private func predictNextToken(tokens: [Int32]) -> Int32? {

        do {
            let inputIDs = try makeInputArray(from: tokens)
            let positionIDs = try makePositionArray()

            let output = try model.prediction(
                input_ids: inputIDs,
                position_ids: positionIDs
            )

            let logits = output.var_3625

            return argmaxLastToken(
                logits: logits,
                sequenceLength: tokens.count
            )

        } catch {
            print("Inference error:", error)
            return nil
        }
    }


    private func makeInputArray(from tokens: [Int32]) throws -> MLMultiArray {
        let array = try MLMultiArray(shape: [1, NSNumber(value: maxSequenceLength)], dataType: .int32)

        for i in 0..<maxSequenceLength {
            if i < tokens.count {
                array[i] = NSNumber(value: tokens[i])
            } else {
                array[i] = 0
            }
        }

        return array
    }

    private func makePositionArray() throws -> MLMultiArray {
        let array = try MLMultiArray(shape: [1, NSNumber(value: maxSequenceLength)], dataType: .int32)

        for i in 0..<maxSequenceLength {
            array[i] = NSNumber(value: i)
        }

        return array
    }

    private func argmaxLastToken(logits: MLMultiArray, sequenceLength: Int) -> Int32 {
        let lastIndex = sequenceLength - 1

        var maxValue = Float.leastNormalMagnitude
        var maxIndex: Int32 = 0

        for v in 0..<vocabSize {
            let index = lastIndex * vocabSize + v
            let value = logits[index].floatValue

            if value > maxValue {
                maxValue = value
                maxIndex = Int32(v)
            }
        }

        return maxIndex
    }
}
