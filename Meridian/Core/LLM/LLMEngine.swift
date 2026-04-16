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

@MainActor
final class LLMEngine: ObservableObject {
    @Published var state: String = "Not loaded"
    @Published var output: String = ""
    @Published var isRunning: Bool = false

    var isLoaded: Bool { container != nil }
    private var container: ModelContainer?

    func load() async {
        guard container == nil else { return }
        Memory.cacheLimit = 20 * 1024 * 1024

        let documentsURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]

        let modelCacheURL = documentsURL
            .appendingPathComponent("models/mlx-community/gemma-2-9b-it-4bit")
        let alreadyDownloaded = FileManager.default
            .fileExists(atPath: modelCacheURL.appendingPathComponent("config.json").path)

        state = alreadyDownloaded ? "Loading..." : "Downloading..."

        do {
            let hub = HubApi(downloadBase: documentsURL)
            container = try await LLMModelFactory.shared.loadContainer(
                hub: hub,
                configuration: LLMRegistry.gemma_2_9b_it_4bit
            ) { [weak self] progress in
                guard let self, !alreadyDownloaded else { return }
                Task { @MainActor in
                    self.state = "Downloading: \(Int(progress.fractionCompleted * 100))%"
                }
            }
            state = "Ready"
        } catch {
            state = "Error: \(error.localizedDescription)"
        }
    }

    func generate(prompt: String) async {
        guard let container else { return }
        isRunning = true
        output = ""
        state = "Generating..."

        do {
            let formatted = "<start_of_turn>user\n\(prompt)<end_of_turn>\n<start_of_turn>model\n"

            try await container.perform { context in
                let tokens = context.tokenizer.encode(text: formatted)
                let input = LMInput(tokens: MLXArray(tokens))

                let stream = try MLXLMCommon.generate(
                    input: input,
                    cache: nil,
                    parameters: GenerateParameters(temperature: 0.7),
                    context: context
                )

                for try await generation in stream {
                    if let chunk = generation.chunk {
                        await MainActor.run { self.output += chunk }
                    } else if let info = generation.info {
                        await MainActor.run { self.state = "Done (\(info.generationTokenCount) tokens)" }
                    }
                }
            }
        } catch {
            state = "Error: \(error.localizedDescription)"
        }

        isRunning = false
    }
}
