//
//  VectorStore.swift
//  Meridian
//
//  Created by Rutwij on 17/04/26.
//

import SQLiteVec
import Foundation

final class VectorStore {

    private var db: Database?

    // MARK: - Lifecycle

    func open(url: URL) async throws {
        try SQLiteVec.initialize()
        db = try Database(.uri(url.path))
    }

    // MARK: - Search

    func search(queryVector: [Float], topK: Int = 3) async throws -> [(text: String, score: Float)] {
        guard let db else { throw VectorStoreError.notOpen }

        let results = try await db.query(
            """
            SELECT c.text, v.distance
            FROM vec_chunks v
            JOIN chunks c ON c.id = v.rowid
            WHERE v.embedding MATCH ?
            ORDER BY v.distance
            LIMIT ?
            """,
            params: [queryVector, topK]
        )

        return results.compactMap { row in
            guard
                let text = row["text"] as? String,
                let distance = row["distance"] as? Double
            else { return nil }
            // sqlite-vec returns L2 distance; convert to a 0-1 similarity score
            let score = 1.0 / (1.0 + Float(distance))
            return (text, score)
        }
    }
}

// MARK: - Errors

extension VectorStore {
    enum VectorStoreError: LocalizedError {
        case notOpen

        var errorDescription: String? {
            switch self {
            case .notOpen: return "VectorStore has no open database"
            }
        }
    }
}
