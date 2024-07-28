import Element
import Output

/// Accessibility reader context.
@AccessActor
public final class AccessReader {
    /// Specialized reader strategy.
    let strategy: AccessGenericReader

    /// Creates a new reader.
    /// - Parameter element: Element to wrap.
    public init(for element: Element) async throws {
        if let role = try await element.getAttribute(.role) as? ElementRole {
            switch role {
            case .row, .column, .cell:
                strategy = try await AccessPassThroughReader(for: element)
            case .outline, .table:
                strategy = try await AccessContainerReader(for: element)
            default:
                strategy = try await AccessGenericReader(for: element)
            }
        } else {
            strategy = try await AccessGenericReader(for: element)
        }
    }

    /// Reads the accessibility content of the element.
    /// - Returns: Semantically described output content.
    public func read() async throws -> [OutputSemantic] {
        return try await strategy.read()
    }

    /// Reads a short description of the element.
    /// - Returns: Semantically described output content.
    public func readSummary() async throws -> [OutputSemantic] {
        return try await strategy.readSummary()
    }

    /// Reads the accessibility label of the element.
    /// - Returns: Semantically described output content.
    public func readLabel() async throws -> [OutputSemantic] {
        return try await strategy.readLabel()
    }

    /// Reads the value of the element.
    /// - Returns: Semantically described output content.
    public func readValue() async throws -> [OutputSemantic] {
        return try await strategy.readValue()
    }

    /// Reads the accessibility role of the element.
    /// - Returns: Semantically described output content.
    public func readRole() async throws -> [OutputSemantic] {
        return try await strategy.readRole()
    }

    /// Reads the state of the element.
    /// - Returns: Semantically described output content.
    public func readState() async throws -> [OutputSemantic] {
        return try await strategy.readState()
    }

    /// Reads the help information of the element.
    /// - Returns: Semantically described output content.
    public func readHelp() async throws -> [OutputSemantic] {
        return try await strategy.readHelp()
    }
}
