import Foundation

/// Where Transkrito keeps its plain files. See shared/SPEC.md "Files".
enum AppPaths {
    static let dataDir: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Transkrito", isDirectory: true)
    }()

    static var dictionary: URL { dataDir.appendingPathComponent("dictionary.json") }
    static var history: URL { dataDir.appendingPathComponent("history.json") }
    static var settings: URL { dataDir.appendingPathComponent("settings.json") }

    static func ensureDirs() {
        try? FileManager.default.createDirectory(at: dataDir, withIntermediateDirectories: true)
    }
}

/// Locates bundled resources whether built by SwiftPM (`Bundle.module`) or Xcode (`Bundle.main`).
enum AppResources {
    static func url(forResource name: String, withExtension ext: String) -> URL? {
        if let u = Bundle.main.url(forResource: name, withExtension: ext) { return u }
        #if SWIFT_PACKAGE
        return Bundle.module.url(forResource: name, withExtension: ext)
        #else
        return nil
        #endif
    }
}
