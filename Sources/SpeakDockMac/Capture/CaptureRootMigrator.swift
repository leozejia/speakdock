import Foundation

protocol CaptureRootMigrating {
    func migrate(from sourceURL: URL, to destinationURL: URL) throws
}

enum CaptureRootMigrationError: Error, Equatable, LocalizedError {
    case destinationConflict(String)
    case sourceIsNotDirectory
    case destinationIsNotDirectory

    var errorDescription: String? {
        switch self {
        case let .destinationConflict(itemName):
            AppLocalizer.formatted(.captureRootConflict, [itemName])
        case .sourceIsNotDirectory:
            AppLocalizer.string(.captureRootSourceNotDirectory)
        case .destinationIsNotDirectory:
            AppLocalizer.string(.captureRootDestinationNotDirectory)
        }
    }
}

struct CaptureRootMigrator: CaptureRootMigrating {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func migrate(from sourceURL: URL, to destinationURL: URL) throws {
        let sourceURL = sourceURL.standardizedFileURL
        let destinationURL = destinationURL.standardizedFileURL

        guard sourceURL != destinationURL else {
            return
        }

        var isSourceDirectory: ObjCBool = false
        let sourceExists = fileManager.fileExists(atPath: sourceURL.path, isDirectory: &isSourceDirectory)

        if sourceExists, !isSourceDirectory.boolValue {
            throw CaptureRootMigrationError.sourceIsNotDirectory
        }

        var isDestinationDirectory: ObjCBool = false
        let destinationExists = fileManager.fileExists(atPath: destinationURL.path, isDirectory: &isDestinationDirectory)

        if destinationExists, !isDestinationDirectory.boolValue {
            throw CaptureRootMigrationError.destinationIsNotDirectory
        }

        if !destinationExists {
            try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true)
        }

        guard sourceExists else {
            return
        }

        let sourceItems = try fileManager.contentsOfDirectory(
            at: sourceURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        for sourceItem in sourceItems {
            let destinationItem = destinationURL.appendingPathComponent(sourceItem.lastPathComponent)
            if fileManager.fileExists(atPath: destinationItem.path) {
                throw CaptureRootMigrationError.destinationConflict(sourceItem.lastPathComponent)
            }
        }

        for sourceItem in sourceItems {
            let destinationItem = destinationURL.appendingPathComponent(sourceItem.lastPathComponent)
            try fileManager.moveItem(at: sourceItem, to: destinationItem)
        }

        let remainingItems = try fileManager.contentsOfDirectory(
            at: sourceURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        if remainingItems.isEmpty {
            try? fileManager.removeItem(at: sourceURL)
        }
    }
}
