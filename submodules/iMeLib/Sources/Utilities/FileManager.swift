//
//  FileManager.swift
//  AiGramLib
//
//  Created by Valeriy Mikholapov on 03/07/2019.
//  Copyright © 2019 Ol Corporation. All rights reserved.
//

import Foundation

final class FileManager {

    static let shared: FileManager = .init()

    private let fileManager: Foundation.FileManager = .default

    private lazy var documentDirectory: URL = fileManager
        .urls(for: .documentDirectory, in: .userDomainMask)
        .first
        .unsafelyUnwrapped

    private lazy var tempDirectory: URL = fileManager.temporaryDirectory

    private init() {
//        clearChatbots()
    }

    /// Moves specified file to doc directory by relative path.
    ///
    /// - Parameters:
    ///   - sourceUrl: Url of file to move
    ///   - relativePath: Where in the doc directory to store the file
    ///   - overwriting: Bool indicating whether the already existing file with
    ///     the same name should be overriden.
    /// - Returns: File url
    /// - Throws: Underlying `FileManager` errors and `FileManager.Error`
    @discardableResult
    func moveFileToDocDir(
        from sourceUrl: URL,
        to relativePath: String,
        overwriting: Bool = false
    ) throws -> URL {
        guard check(itemAtUrl: sourceUrl, is: .file) else { throw Error.notFile }

        let destUrl = documentDirectory
            .appendingPathComponent(relativePath)

        try ensureDestPathExist(by: destUrl)

        if
            overwriting && check(itemAtUrl: destUrl, is: .file),
            let newFileUrl = try fileManager.replaceItemAt(destUrl, withItemAt: sourceUrl)
        {
            return newFileUrl
        } else {
            try fileManager.moveItem(at: sourceUrl, to: destUrl)
        }
        return destUrl
    }

    /// Moves file to temporary directory and generates new name.
    ///
    /// - Parameter sourceUrl: Original file URL
    /// - Returns: Temporary file url
    /// - Throws: Underlying `FileManager` errors and `FileManager.Error`
    @discardableResult
    func moveFileToTempDir(from sourceUrl: URL) throws -> URL {
        guard check(itemAtUrl: sourceUrl, is: .file) else { throw Error.notFile }

        let ext = sourceUrl.pathExtension
        let name = "temp_\(UInt.random(in: .min ... .max))\(ext.isEmpty ? "" : "." + ext)"

        let destUrl = tempDirectory
            .appendingPathComponent(name, isDirectory: false)

        try fileManager.moveItem(at: sourceUrl, to: destUrl)

        return destUrl
    }

    /// Removes file at specified URL.
    ///
    /// - Throws: `FileManager.Error` or underlying `Foundation.FileManager` errors.
    func delete(file url: URL) throws {
        guard url.isFileURL else { throw Error.notFile }
        try fileManager.removeItem(at: url)
    }

    /// Finds all folders within specified folder.
    ///
    /// - Parameter relativePath: Path relative to Documents directory.
    /// - Returns: URLs of folders at specified path.
    /// - Throws: `FileManager.Error` or underlying `Foundation.FileManager` errors.
    func folders(atRelativePath relativePath: String) throws -> [URL] {
        let folderUrl = documentDirectory.appendingPathComponent(relativePath)
        return try folders(at: folderUrl)
    }

    /// Finds all folders within specified folder.
    ///
    /// - Parameter folderUrl: URL of the directory.
    /// - Returns: URLs of folders at specified directory.
    /// - Throws: `FileManager.Error` or underlying `Foundation.FileManager` errors.
    func folders(at folderUrl: URL) throws -> [URL] {
        guard check(itemAtUrl: folderUrl, is: .folder) else {
            throw Error.notFolder
        }

        return try fileManager.contentsOfDirectory(
            at: folderUrl,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        )
    }

    /// Moves all contents of directory at `sourceUrl` to `destUrl`.
    ///
    /// - Throws: `FileManager.Error` or underlying `Foundation.FileManager` errors.
    func moveContents(of sourceUrl: URL, to destUrl: URL) throws -> URL {
        guard check(itemAtUrl: sourceUrl, is: .folder) else {
            throw Error.notFolder
        }

        let tempUrl = sourceUrl
            .deletingLastPathComponent()
            .appendingPathComponent(destUrl.lastPathComponent, isDirectory: true)

        try fileManager.moveItem(at: sourceUrl, to: tempUrl)

        try ensureDestPathExist(by: destUrl)

        if !check(itemAtUrl: destUrl, is: .folder) {
            try fileManager.createDirectory(at: destUrl, withIntermediateDirectories: true)
        }

        return try fileManager.replaceItemAt(destUrl, withItemAt: tempUrl) ?? destUrl
    }

    // MARK: - Helpers

    private func check(itemAtUrl url: URL, is item: Item) -> Bool {
        var isDirectory = ObjCBool(item == .folder ? true : false)
        return fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
    }

    private func ensureDestPathExist(by url: URL) throws {
        let destFolderUrl = url.deletingLastPathComponent()
        if !check(itemAtUrl: url, is: .folder) {
            try fileManager.createDirectory(at: destFolderUrl, withIntermediateDirectories: true)
        }
    }

    private func clearChatbots() {
        let items = try! fileManager.contentsOfDirectory(
            at: documentDirectory.appendingPathComponent("chatbots", isDirectory: true),
            includingPropertiesForKeys: [],
            options: []
        )

        items.forEach {
            try! delete(file: $0)
        }
    }
}

// MARK: - Inner types

extension FileManager {

    enum Error: Swift.Error {
        case notFile, notFolder
    }

    enum Item {
        case file, folder
    }

}
