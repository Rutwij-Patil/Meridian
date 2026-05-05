//
//  ChatViewModel.swift
//  Meridian
//
//  Created by Rutwij on 05/05/26.
//

internal import Foundation
internal import Observation

@MainActor
@Observable
final class ChatViewModel {

    enum State {
        case idle
        case thinking
        case streaming
        case error(String)
    }

    enum Role {
        case user
        case assistant
    }

    struct Message: Identifiable {
        let id = UUID()
        let role: Role
        var text: String
    }

    private(set) var state: State = .idle
    private(set) var messages: [Message] = []

    private let pipeline: RAGPipeline
    private var sendTask: Task<Void, Never>?

    init(pipeline: RAGPipeline) {
        self.pipeline = pipeline
    }

    // MARK: - Send

    func send(_ question: String) {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        sendTask?.cancel()

        messages.append(Message(role: .user, text: trimmed))
        let assistant = Message(role: .assistant, text: "")
        messages.append(assistant)
        let assistantId = assistant.id
        state = .thinking

        sendTask = Task { [weak self] in
            await self?.performSend(question: trimmed, assistantId: assistantId)
        }
    }

    private func performSend(question: String, assistantId: UUID) async {
        do {
            _ = try await pipeline.answer(question: question) { [weak self] token in
                Task { @MainActor in
                    guard let self else { return }
                    if case .thinking = self.state {
                        self.state = .streaming
                    }
                    if let idx = self.messages.firstIndex(where: { $0.id == assistantId }) {
                        self.messages[idx].text += token
                    }
                }
            }
            try Task.checkCancellation()
            state = .idle
        } catch is CancellationError {
            return
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    // MARK: - Control

    func cancel() {
        sendTask?.cancel()
        sendTask = nil
        switch state {
        case .thinking, .streaming:
            state = .idle
        default:
            break
        }
    }

    func clear() {
        sendTask?.cancel()
        sendTask = nil
        messages.removeAll()
        state = .idle
    }
}
