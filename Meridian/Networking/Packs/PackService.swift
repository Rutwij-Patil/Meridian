//
//  PackError.swift
//  Meridian
//
//  Created by Rutwij on 05/05/26.
//


//
//  PackService.swift
//  Meridian
//

internal import Foundation
import ZIPFoundation

enum PackError: LocalizedError {
    case noDBFound
    case unzipFailed(String)

    var errorDescription: String? {
        switch self {
        case .noDBFound:            return "chunks.db not found in downloaded package"
        case .unzipFailed(let msg): return "Unzip failed: \(msg)"
        }
    }
}

final class PackService {

    private let client: APIClient
    private var packsRoot: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("packs")
    }

    init(client: APIClient = .shared) {
        self.client = client
    }

    func fetchPack(query: String, onProgress: @escaping (String) -> Void) async throws -> URL {
        onProgress("Querying API...")
        let response = try await client.send(PackAPI.queryPack(query: query))

        let packDir = packsRoot.appendingPathComponent(response.sessionId)
        if FileManager.default.fileExists(atPath: packDir.appendingPathComponent("chunks.db").path) {
            onProgress("Loaded from cache")
            return packDir
        }

        onProgress("Downloading pack...")
        let tempZip = try await client.download(from: response.packageUrl)

        try FileManager.default.createDirectory(at: packsRoot, withIntermediateDirectories: true)
        let stableZip = packsRoot.appendingPathComponent("\(response.sessionId).zip")
        try? FileManager.default.removeItem(at: stableZip)
        try FileManager.default.moveItem(at: tempZip, to: stableZip)

        onProgress("Unpacking...")
        try FileManager.default.unzipItem(at: stableZip, to: packDir)

        guard FileManager.default.fileExists(atPath: packDir.appendingPathComponent("chunks.db").path) else {
            throw PackError.noDBFound
        }

        try? FileManager.default.removeItem(at: stableZip)
        onProgress("Ready")
        return packDir
    }
}
