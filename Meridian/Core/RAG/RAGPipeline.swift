//
//  RAGPipeline.swift
//  Meridian
//
//  Created by Rutwij on 05/05/26.
//

internal import Foundation

final class RAGPipeline {

    private let vectorStore = VectorStore()
    private let llm: LLMEngine
    private let embedder: EmbeddingEngine

    init(llm: LLMEngine, embedder: EmbeddingEngine) {
        self.llm = llm
        self.embedder = embedder
    }

    func setup(packURL: URL) async throws {
        let dbURL = packURL.appendingPathComponent("chunks.db")
        try await vectorStore.open(url: dbURL)
    }

    func answer(
        question: String,
        onToken: @escaping (String) -> Void
    ) async throws -> String {
        let queryVec = try embedder.embed(question)
        let results = try await vectorStore.search(queryVector: queryVec, topK: 3)

        let threshold: Float = 0.3
        let relevantChunks = results
            .filter { $0.score > threshold }
            .map { $0.text }

        let prompt = Soul.prompt(
            context: relevantChunks.isEmpty ? nil : relevantChunks,
            question: question
        )

        return try await llm.generate(prompt: prompt, onToken: onToken)
    }
}
