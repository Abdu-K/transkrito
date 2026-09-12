import Foundation

/// A downloadable sherpa-onnx model kept under ~/Library/Application Support/Transkrito/models.
struct SherpaModel: Identifiable, Equatable {
    let id: String
    let name: String
    let version: String
    let url: URL
    let folder: String
    let files: [String]
    let approxMB: Int

    var dir: URL { AppPaths.modelsDir.appendingPathComponent(folder, isDirectory: true) }
    var isInstalled: Bool { files.allSatisfy { FileManager.default.fileExists(atPath: dir.appendingPathComponent($0).path) } }
    func path(_ file: String) -> String { dir.appendingPathComponent(file).path }
}

/// Models published by sherpa-onnx (github.com/k2-fsa/sherpa-onnx, release "asr-models") — same sources as Windows.
enum SherpaCatalog {
    private static let base = "https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/"

    /// Whisper tiny (multilingual) used only for spoken-language identification in Auto mode.
    static let languageID = SherpaModel(
        id: "whisper-tiny-slid", name: "Language detector (Whisper tiny)", version: "int8",
        url: URL(string: base + "sherpa-onnx-whisper-tiny.tar.bz2")!,
        folder: "sherpa-onnx-whisper-tiny",
        files: ["tiny-encoder.int8.onnx", "tiny-decoder.int8.onnx", "tiny-tokens.txt"], approxMB: 116)

    /// Nemotron 3.5 ASR Streaming 0.6B — multilingual incl. Arabic. Fallback when Apple Speech has no Arabic asset.
    static let nemotron = SherpaModel(
        id: "nemotron-3.5-asr-streaming-0.6b", name: "Nemotron 3.5 multilingual", version: "2026-06-11 \u{00B7} 560 ms \u{00B7} int8",
        url: URL(string: base + "sherpa-onnx-nemotron-3.5-asr-streaming-0.6b-560ms-int8-2026-06-11.tar.bz2")!,
        folder: "sherpa-onnx-nemotron-3.5-asr-streaming-0.6b-560ms-int8-2026-06-11",
        files: ["encoder.int8.onnx", "decoder.int8.onnx", "joiner.int8.onnx", "tokens.txt"], approxMB: 475)
}

extension AppPaths {
    static var modelsDir: URL { dataDir.appendingPathComponent("models", isDirectory: true) }
}

/// Downloads a model archive (resumable) and extracts it with the system tar. Verifies files; writes model.json.
enum SherpaModelManager {
    enum Failure: LocalizedError {
        case http(Int), extract(String), missingFiles
        var errorDescription: String? {
            switch self {
            case .http(let c): return "Download failed (HTTP \(c))."
            case .extract(let m): return "Could not unpack the model: \(m)"
            case .missingFiles: return "Archive unpacked but expected model files are missing."
            }
        }
    }

    static func download(_ model: SherpaModel, progress: @escaping @Sendable (Double) -> Void) async throws {
        if model.isInstalled { progress(1); return }
        try FileManager.default.createDirectory(at: AppPaths.modelsDir, withIntermediateDirectories: true)
        let part = AppPaths.modelsDir.appendingPathComponent(model.folder + ".tar.bz2.part")

        // Resume when the server honors ranges; otherwise start over.
        var have: Int64 = (try? FileManager.default.attributesOfItem(atPath: part.path)[.size] as? Int64) ?? 0
        var request = URLRequest(url: model.url)
        if have > 0 { request.setValue("bytes=\(have)-", forHTTPHeaderField: "Range") }
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard let http = response as? HTTPURLResponse else { throw Failure.http(0) }
        if have > 0 && http.statusCode != 206 { try? FileManager.default.removeItem(at: part); have = 0 }
        guard (200...299).contains(http.statusCode) else { throw Failure.http(http.statusCode) }
        let total = http.expectedContentLength + (http.statusCode == 206 ? have : 0)

        if !FileManager.default.fileExists(atPath: part.path) { FileManager.default.createFile(atPath: part.path, contents: nil) }
        let handle = try FileHandle(forWritingTo: part)
        try handle.seekToEnd()
        var buffer = Data(); buffer.reserveCapacity(1 << 16)
        var done = have
        for try await byte in bytes {
            buffer.append(byte)
            if buffer.count >= 1 << 16 {
                try handle.write(contentsOf: buffer); done += Int64(buffer.count); buffer.removeAll(keepingCapacity: true)
                if total > 0 { progress(Double(done) / Double(total)) }
            }
        }
        if !buffer.isEmpty { try handle.write(contentsOf: buffer); done += Int64(buffer.count) }
        try handle.close()

        progress(-1) // extracting
        let tar = Process()
        tar.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        tar.arguments = ["-xjf", part.path, "-C", AppPaths.modelsDir.path]
        let err = Pipe(); tar.standardError = err
        try tar.run(); tar.waitUntilExit()
        if tar.terminationStatus != 0 {
            let msg = String(data: err.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw Failure.extract(msg.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        try? FileManager.default.removeItem(at: part)
        guard model.isInstalled else {
            try? FileManager.default.removeItem(at: model.dir)
            throw Failure.missingFiles
        }
        let meta: [String: Any] = ["id": model.id, "name": model.name, "version": model.version, "source": model.url.absoluteString,
                                   "installed": ISO8601DateFormatter().string(from: Date())]
        if let data = try? JSONSerialization.data(withJSONObject: meta, options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: model.dir.appendingPathComponent("model.json"))
        }
        progress(1)
    }

    static func delete(_ model: SherpaModel) {
        try? FileManager.default.removeItem(at: model.dir)
        try? FileManager.default.removeItem(at: AppPaths.modelsDir.appendingPathComponent(model.folder + ".tar.bz2.part"))
    }
}
