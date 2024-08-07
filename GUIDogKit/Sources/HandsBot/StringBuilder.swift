//
//  StringBuilder.swift
//  GUIDog
//
//  Created by Kai Quan Tay on 11/7/24.
//

/// Builds a string
@resultBuilder
public enum StringBuilder {
    /// Builds a string from many strings.
    public static func buildBlock(_ components: String...) -> String {
        components.joined(separator: "\n")
    }

    /// Builds a string from an optional string
    public static func buildOptional(_ component: String?) -> String {
        component ?? ""
    }

    /// Builds a string from an if's first block
    public static func buildEither(first component: String) -> String {
        component
    }

    /// Builds a string from an if's second block
    public static func buildEither(second component: String) -> String {
        component
    }

    /// Builds a string from an array, like for in.
    public static func buildArray(_ components: [String]) -> String {
        components.joined(separator: "\n")
    }
}

public extension String {
    /// Builds a string from a StringBuilder
    static func build(@StringBuilder content: () -> String) -> String {
        return content()
    }

    /// Builds a string from an async StringBuilder
    static func build(@StringBuilder content: () async -> String) async -> String {
        return await content()
    }

    /// Builds a string from a throwing StringBuilder
    static func build(@StringBuilder content: () throws -> String) throws -> String {
        return try content()
    }

    /// Builds a string from an async throwing StringBuilder
    static func build(@StringBuilder content: () async throws -> String) async throws -> String {
        return try await content()
    }

    /// Adds a tab to every line
    /// - Parameters:
    ///   - useSpaces: Whether the tab should use spaces `" "` or tabs `"\t"`
    ///   - count: The number of spaces or tabs to use
    /// - Returns: A string, with the appropriate tabs prefixed to every line
    func tab(useSpaces: Bool = true, count: Int = 2) -> String {
        let prefix = String(repeating: useSpaces ?  " " : "\t", count: count)
        return self
            .split(separator: "\n")
            .map {
                prefix + $0
            }
            .joined(separator: "\n")
    }
}

/// Uses `dump` from the swift standard library to dump the description of a value
public func dumpDescription<T>(of value: T) -> String {
    var output = DumpOutput()
    dump(value, to: &output)
    return output.store
}

struct DumpOutput: TextOutputStream {
    var store: String = ""

    mutating func write(_ string: String) {
        store += string
    }
}
