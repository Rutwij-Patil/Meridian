//
//  LLMEngine.swift
//  Meridian
//
//  Created by Rutwij on 17/04/26.
//

import MLX
import MLXLLM
import MLXLMCommon
import Hub
import SwiftUI
internal import Combine
internal import Tokenizers

final class LLMEngine {

    private var container: ModelContainer?
    var isLoaded: Bool { container != nil }

    func load(onProgress: @escaping (String) -> Void) async throws {
        guard container == nil else { return }
        Memory.cacheLimit = 20 * 1024 * 1024

        let documentsURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]

        let modelCacheURL = documentsURL
            .appendingPathComponent("models/mlx-community/gemma-2-9b-it-4bit")
        let alreadyDownloaded = FileManager.default
            .fileExists(atPath: modelCacheURL.appendingPathComponent("config.json").path)

        onProgress(alreadyDownloaded ? "Loading..." : "Downloading...")

        let hub = HubApi(downloadBase: documentsURL)
        container = try await LLMModelFactory.shared.loadContainer(
            hub: hub,
            configuration: LLMRegistry.gemma3_1B_qat_4bit
        ) { progress in
            guard !alreadyDownloaded else { return }
            onProgress("Downloading: \(Int(progress.fractionCompleted * 100))%")
        }
    }

    func generate(prompt: String, onToken: @escaping (String) -> Void) async throws -> String {
        guard let container else { throw LLMError.notLoaded }

        let formatted = "<start_of_turn>user\n\(prompt)<end_of_turn>\n<start_of_turn>model\n"

        return try await container.perform { context in
            let tokens = context.tokenizer.encode(text: formatted)
            let input = LMInput(tokens: MLXArray(tokens))

            let stream = try MLXLMCommon.generate(
                input: input,
                cache: nil,
                parameters: GenerateParameters(temperature: 0.7),
                context: context
            )

            var fullOutput = ""
            for try await generation in stream {
                if let chunk = generation.chunk {
                    fullOutput += chunk
                    onToken(chunk)
                }
            }
            return fullOutput
        }
    }
}

extension LLMEngine {
    enum LLMError: LocalizedError {
        case notLoaded

        var errorDescription: String? {
            switch self {
            case .notLoaded: return "LLM model is not loaded"
            }
        }
    }
}
