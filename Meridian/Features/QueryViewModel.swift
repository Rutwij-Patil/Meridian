//
//  QueryViewModel.swift
//  Meridian
//
//  Created by Rutwij on 05/05/26.
//

internal import Foundation
internal import Observation

@MainActor
@Observable
final class QueryViewModel {

    enum State {
        case idle
        case loadingModels
        case ready
        case fetchingPack
        case error(String)
    }

    private(set) var state: State = .idle
    private(set) var llmProgress: String = ""
    private(set) var embedderProgress: String = ""
    private(set) var packProgress: String = ""
    private(set) var chat: ChatViewModel?

    private let llm = LLMEngine()
    private let embedder = EmbeddingEngine()
    private let packs = PackService()

    private var loadTask: Task<Void, Never>?
    private var fetchTask: Task<Void, Never>?

    // MARK: - Cold start

    func loadModels() {
        switch state {
        case .idle, .error:
            break
        default:
            return
        }

        loadTask?.cancel()
        loadTask = Task { [weak self] in
            await self?.performLoad()
        }
    }

    private func performLoad() async {
        state = .loadingModels
        llmProgress = "Starting LLM..."
        embedderProgress = "Starting embedder..."

        do {
            async let llmLoad: Void = llm.load { [weak self] msg in
                Task { @MainActor in
                    self?.llmProgress = msg
                }
            }
            async let embedderLoad: Void = embedder.load { [weak self] msg in
                Task { @MainActor in
                    self?.embedderProgress = msg
                }
            }

            try await llmLoad
            try await embedderLoad
            try Task.checkCancellation()

            state = .ready
        } catch is CancellationError {
            return
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    // MARK: - Pack fetch

    func fetchPack(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard llm.isLoaded, embedder.isLoaded else { return }

        fetchTask?.cancel()
        fetchTask = Task { [weak self] in
            await self?.performFetch(query: trimmed)
        }
    }

    private func performFetch(query: String) async {
        state = .fetchingPack
        packProgress = "Querying..."
        chat = nil

        do {
            let url = try await packs.fetchPack(query: query) { [weak self] msg in
                Task { @MainActor in
                    self?.packProgress = msg
                }
            }
            try Task.checkCancellation()

            let pipeline = RAGPipeline(llm: llm, embedder: embedder)
            try await pipeline.setup(packURL: url)
            try Task.checkCancellation()

            chat = ChatViewModel(pipeline: pipeline)
            state = .ready
        } catch is CancellationError {
            return
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    // MARK: - Recovery

    func retry() {
        guard case .error = state else { return }
        state = .idle
        llmProgress = ""
        embedderProgress = ""
        packProgress = ""
        loadModels()
    }
}
