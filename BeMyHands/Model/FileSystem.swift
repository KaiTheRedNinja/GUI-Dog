//
//  FileSystem.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 28/7/24.
//

import Foundation
import OSLog

private let logger = Logger(subsystem: #fileID, category: "BeMyHands")

enum FileSystem {
    /// Reads a type from a file
    static func read<T: Decodable>(_ type: T.Type, from file: String) -> T? {
        let filename = getDocumentsDirectory().appendingPathComponent(file)
        if let data = try? Data(contentsOf: filename) {
            if let values = try? JSONDecoder().decode(T.self, from: data) {
                return values
            }
        }

        return nil
    }

    /// Writes a type to a file
    static func write<T: Encodable>(_ value: T, to file: String, error onError: @escaping (Error) -> Void = { _ in }) {
        var encoded: Data

        do {
            encoded = try JSONEncoder().encode(value)
        } catch {
            onError(error)
            return
        }

        let filename = getDocumentsDirectory().appendingPathComponent(file)
        if file.contains("/") {
            try? FileManager.default.createDirectory(
                atPath: filename.deletingLastPathComponent().path,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        do {
            try encoded.write(to: filename)
            return
        } catch {
            // failed to write file – bad permissions, bad filename,
            // missing permissions, or more likely it can't be converted to the encoding
            onError(error)
        }
    }

    /// Checks if a file exists at a path
    static func exists(file: String) -> Bool {
        let path = getDocumentsDirectory().appendingPathComponent(file)
        return FileManager.default.fileExists(atPath: path.relativePath)
    }

    /// Returns the URL of the path
    static func path(file: String) -> URL {
        getDocumentsDirectory().appendingPathComponent(file)
    }

    /// Gets the documents directory
    static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let path = paths[0].appending(path: "com.kaithebuilder.BeMyHands")

        // if the path doesn't exist, create it
        if !FileManager.default.fileExists(atPath: path.relativePath) {
            try? FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
        }

        return path
    }
}

public extension URL {
    /// The attributes of a url
    var attributes: [FileAttributeKey: Any]? {
        do {
            return try FileManager.default.attributesOfItem(atPath: path)
        } catch let error as NSError {
            logger.error("FileAttribute error: \(error)")
        }
        return nil
    }

    /// The file size of the url
    var fileSize: UInt64 {
        return attributes?[.size] as? UInt64 ?? UInt64(0)
    }

    /// The file size of the url as a string
    var fileSizeString: String {
        return ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
    }

    /// The date of creation of the file
    var creationDate: Date? {
        return attributes?[.creationDate] as? Date
    }
}
