//
//  AppModel.swift
//  Meridian
//

internal import Foundation
internal import Observation

@MainActor
@Observable
final class AppModel {

    enum Phase {
        case coldStart
        case ready
        case error(String)
    }

    private(set) var phase: Phase = .coldStart
    private(set) var sessions: [Session] = []
    var activeSessionId: Session.ID?

    private(set) var llmProgress: String = ""
    private(set) var embedderProgress: String = ""
    private(set) var newSessionProgress: String = ""
    private(set) var newSessionError: String?

    let llm = LLMEngine()
    let embedder = EmbeddingEngine()
    private let packs = PackService()

    private var loadTask: Task<Void, Never>?
    private var newSessionTask: Task<Void, Never>?

    var activeSession: Session? {
        guard let id = activeSessionId else { return nil }
        return sessions.first { $0.id == id }
    }

    // MARK: - Cold start

    func loadModels() {
        if case .ready = phase { return }
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            await self?.performLoad()
        }
    }

    private func performLoad() async {
        phase = .coldStart
        llmProgress = "Starting LLM..."
        embedderProgress = "Starting embedder..."

        do {
            async let llmLoad: Void = llm.load { [weak self] msg in
                Task { @MainActor in self?.llmProgress = msg }
            }
            async let embedderLoad: Void = embedder.load { [weak self] msg in
                Task { @MainActor in self?.embedderProgress = msg }
            }
            try await llmLoad
            try await embedderLoad
            try Task.checkCancellation()
            phase = .ready
        } catch is CancellationError {
            return
        } catch {
            phase = .error(error.localizedDescription)
        }
    }

    // MARK: - Sessions

    func newSession(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard llm.isLoaded, embedder.isLoaded else { return }

        newSessionTask?.cancel()
        newSessionTask = Task { [weak self] in
            await self?.performNewSession(query: trimmed)
        }
    }

    private func performNewSession(query: String) async {
        newSessionError = nil
        newSessionProgress = "Querying..."
        do {
            let url = try await packs.fetchPack(query: query) { [weak self] msg in
                Task { @MainActor in self?.newSessionProgress = msg }
            }
            try Task.checkCancellation()

            let pipeline = RAGPipeline(llm: llm, embedder: embedder)
            try await pipeline.setup(packURL: url)
            try Task.checkCancellation()

            let session = Session(
                query: query,
                packURL: url,
                chat: ChatViewModel(pipeline: pipeline)
            )
            sessions.insert(session, at: 0)
            activeSessionId = session.id
            newSessionProgress = ""
        } catch is CancellationError {
            return
        } catch {
            newSessionProgress = ""
            newSessionError = error.localizedDescription
        }
    }

    func clearNewSessionError() {
        newSessionError = nil
    }

    func selectSession(_ id: Session.ID) {
        activeSessionId = id
    }

    func deleteSession(_ id: Session.ID) {
        sessions.removeAll { $0.id == id }
        if activeSessionId == id {
            activeSessionId = sessions.first?.id
        }
    }

    func clearActiveSelection() {
        activeSessionId = nil
    }

    func retry() {
        guard case .error = phase else { return }
        phase = .coldStart
        llmProgress = ""
        embedderProgress = ""
        loadModels()
    }
}

struct Session: Identifiable, Hashable {
    let id = UUID()
    let query: String
    let createdAt = Date()
    let packURL: URL
    let chat: ChatViewModel

    static func == (lhs: Session, rhs: Session) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
