//
//  StringBuilder.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 11/7/24.
//

@resultBuilder
enum StringBuilder {
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
}
