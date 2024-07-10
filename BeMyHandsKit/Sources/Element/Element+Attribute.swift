//
//  Element+Attribute.swift
//  
//
//  Created by Kai Quan Tay on 10/7/24.
//

import ApplicationServices

public extension Element {
    /// Retrieves the set of attributes supported by this element.
    /// - Returns: Set of attributes.
    func getAttributeSet() throws -> Set<ElementAttribute> {
        let attributes = try listAttributes()
        return Set(attributes.lazy.compactMap({ ElementAttribute(rawValue: $0) }))
    }

    /// Reads the value associated with a given attribute of this element.
    /// - Parameter attribute: Attribute whose value is to be read.
    /// - Returns: Value of the attribute, if any.
    func getAttribute(_ attribute: ElementAttribute) throws -> Any? {
        let output = try getAttribute(attribute.rawValue)
        if attribute == .role, let output = output as? String {
            return ElementRole(rawValue: output)
        }
        if attribute == .subrole, let output = output as? String {
            return ElementSubrole(rawValue: output)
        }
        return output
    }

    /// Writes a value to the specified attribute of this element.
    /// - Parameters:
    ///   - attribute: Attribute to be written.
    ///   - value: Value to write.
    func setAttribute(_ attribute: ElementAttribute, value: Any) throws {
        return try setAttribute(attribute.rawValue, value: value)
    }

    /// Retrieves the set of parameterized attributes supported by this element.
    /// - Returns: Set of parameterized attributes.
    func getParameterizedAttributeSet() throws -> Set<ElementParameterizedAttribute> {
        let attributes = try listParameterizedAttributes()
        return Set(attributes.lazy.compactMap({ ElementParameterizedAttribute(rawValue: $0) }))
    }

    /// Queries the specified parameterized attribute of this element.
    /// - Parameters:
    ///   - attribute: Parameterized attribute to query.
    ///   - input: Input value.
    /// - Returns: Output value.
    func queryParameterizedAttribute(_ attribute: ElementParameterizedAttribute, input: Any) throws -> Any? {
        return try queryParameterizedAttribute(attribute.rawValue, input: input)
    }

    /// Creates a list of all the known attributes of this element.
    /// - Returns: List of attributes.
    internal func listAttributes() throws -> [String] {
        let legacyValue = legacyValue as! AXUIElement
        var attributes: CFArray?
        let result = AXUIElementCopyAttributeNames(legacyValue, &attributes)
        let error = ElementError(from: result)
        switch error {
        case .success:
            break
        case .apiDisabled, .invalidElement, .notImplemented, .timeout:
            throw error
        default:
            fatalError("Unexpected error reading an accessibility element's attribute names: \(error)")
        }
        guard let attributes = [Any?](legacyValue: attributes as CFTypeRef) else {
            return []
        }
        return attributes.compactMap({ $0 as? String })
    }

    /// Reads the value associated with a given attribute of this element.
    /// - Parameter attribute: Attribute whose value is to be read.
    /// - Returns: Value of the attribute, if any.
    internal func getAttribute(_ attribute: String) throws -> Any? {
        let legacyValue = legacyValue as! AXUIElement
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(legacyValue, attribute as CFString, &value)
        let error = ElementError(from: result)
        switch error {
        case .success:
            break
        case .attributeUnsupported, .noValue, .systemFailure, .illegalArgument:
            return nil
        case .apiDisabled, .invalidElement, .notImplemented, .timeout:
            throw error
        default:
            fatalError("Unexpected error getting value for accessibility element attribute \(attribute): \(error)")
        }
        guard let value = value else {
            return nil
        }
        return fromLegacy(value: value)
    }

    /// Writes a value to the specified attribute of this element.
    /// - Parameters:
    ///   - attribute: Attribute to be written.
    ///   - value: Value to write.
    internal func setAttribute(_ attribute: String, value: Any) throws {
        let legacyValue = legacyValue as! AXUIElement
        guard let value = value as? any ElementLegacy else {
            throw ElementError.illegalArgument
        }
        let result = AXUIElementSetAttributeValue(legacyValue, attribute as CFString, value.legacyValue as CFTypeRef)
        let error = ElementError(from: result)
        switch error {
        case .success, .systemFailure, .attributeUnsupported, .illegalArgument:
            break
        case .apiDisabled, .invalidElement, .notEnoughPrecision, .notImplemented, .timeout:
            throw error
        default:
            fatalError("Unexpected error setting accessibility element attribute \(attribute): \(error)")
        }
    }

    /// Lists the parameterized attributes available to this element.
    /// - Returns: List of parameterized attributes.
    internal func listParameterizedAttributes() throws -> [String] {
        let legacyValue = legacyValue as! AXUIElement
        var parameterizedAttributes: CFArray?
        let result = AXUIElementCopyParameterizedAttributeNames(legacyValue, &parameterizedAttributes)
        let error = ElementError(from: result)
        switch error {
        case .success:
            break
        case .apiDisabled, .invalidElement, .notImplemented, .timeout:
            throw error
        default:
            fatalError("Unexpected error reading an accessibility element's parameterized attribute names: \(error)")
        }
        guard let parameterizedAttributes = [Any?](legacyValue: parameterizedAttributes as CFTypeRef) else {
            return []
        }
        return parameterizedAttributes.compactMap({ $0 as? String })
    }

    /// Queries the specified parameterized attribute of this element.
    /// - Parameters:
    ///   - attribute: Parameterized attribute to query.
    ///   - input: Input value.
    /// - Returns: Output value.
    internal func queryParameterizedAttribute(_ attribute: String, input: Any) throws -> Any? {
        let legacyValue = legacyValue as! AXUIElement
        guard let input = input as? any ElementLegacy else {
            throw ElementError.illegalArgument
        }
        var output: CFTypeRef?
        let result = AXUIElementCopyParameterizedAttributeValue(
            legacyValue,
            attribute as CFString,
            input.legacyValue as CFTypeRef,
            &output
        )
        let error = ElementError(from: result)
        switch error {
        case .success:
            break
        case .noValue, .parameterizedAttributeUnsupported, .systemFailure, .illegalArgument:
            return nil
        case .apiDisabled, .invalidElement, .notEnoughPrecision, .notImplemented, .timeout:
            throw error
        default:
            fatalError("""
Unrecognized error querying parameterized accessibility element attribute \(attribute): \(error)
""")
        }
        return fromLegacy(value: output)
    }
}
