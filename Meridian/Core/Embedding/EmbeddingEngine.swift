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
import Foundation
internal import Combine

class EmbeddingEngine: ObservableObject {
    @Published var state: String = "Not loaded"

    private var model: (any MLXEmbedders.EmbeddingModel)?
    private var tokenizer: (any Tokenizers.Tokenizer)?

    @MainActor
    func load() async {
        state = "Loading embedder..."
        do {
            let (m, t) = try await MLXEmbedders.load(
                configuration: .minilm_l6
            ) { [weak self] progress in
                Task { @MainActor in
                    self?.state = "Downloading: \(Int(progress.fractionCompleted * 100))%"
                }
            }
            self.model = m
            self.tokenizer = t
            await MainActor.run { state = "Embedder ready" }
        } catch {
            await MainActor.run { state = "Error: \(error.localizedDescription)" }
        }
    }

    func embed(_ text: String) throws -> [Float] {
        guard let model, let tokenizer else {
            throw EmbedError.notLoaded
        }

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
    enum EmbedError: Error {
        case notLoaded
        case noOutput
    }
}
