//
//  EmbeddingEngine.swift
//  Meridian
//
//  Created by Rutwij on 17/04/26.
//

import MLX
import MLXEmbedders
import MLXLMCommon
internal import Tokenizers
internal import Foundation

final class EmbeddingEngine {

    private var model: (any MLXEmbedders.EmbeddingModel)?
    private var tokenizer: (any Tokenizers.Tokenizer)?

    var isLoaded: Bool { model != nil }

    func load(onProgress: @escaping (String) -> Void) async throws {
        onProgress("Loading embedder...")
        let (m, t) = try await MLXEmbedders.load(
            configuration: .minilm_l6
        ) { progress in
            onProgress("Downloading embedder: \(Int(progress.fractionCompleted * 100))%")
        }
        self.model = m
        self.tokenizer = t
    }

    func embed(_ text: String) throws -> [Float] {
        guard let model, let tokenizer else { throw EmbedError.notLoaded }

        let tokens = tokenizer.encode(text: text)
        let seqLen = tokens.count
        let input = MLXArray(tokens).expandedDimensions(axis: 0)
        let positionIds = MLXArray(Array(0..<seqLen)).expandedDimensions(axis: 0)
        let tokenTypeIds = MLXArray(Array(repeating: 0, count: seqLen)).expandedDimensions(axis: 0)
        let attentionMask = MLXArray(Array(repeating: 1, count: seqLen)).expandedDimensions(axis: 0)

        let output = model(
            input,
            positionIds: positionIds,
            tokenTypeIds: tokenTypeIds,
            attentionMask: attentionMask
        )

        let embedding: MLXArray
        if let pooled = output.pooledOutput {
            embedding = pooled.squeezed()
        } else if let hidden = output.hiddenStates {
            embedding = hidden.mean(axis: 1).squeezed()
        } else {
            throw EmbedError.noOutput
        }

        MLX.eval(embedding)
        return normalize(embedding.asArray(Float.self))
    }

    private func normalize(_ vec: [Float]) -> [Float] {
        let norm = sqrt(vec.map { $0 * $0 }.reduce(0, +))
        return norm > 0 ? vec.map { $0 / norm } : vec
    }
}

extension EmbeddingEngine {
    enum EmbedError: LocalizedError {
        case notLoaded
        case noOutput

        var errorDescription: String? {
            switch self {
            case .notLoaded: return "Embedding model is not loaded"
            case .noOutput:  return "Embedding model produced no output"
            }
        }
    }
}
