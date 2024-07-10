import ApplicationServices

/// Swift wrapper for a legacy ``AXUIElement``.
@ElementActor
public struct Element {
    /// Legacy value.
    let legacyValue: CFTypeRef

    /// Creates a system-wide element.
    public init() {
        legacyValue = AXUIElementCreateSystemWide()
    }

    /// Creates an application element for the specified PID.
    /// - Parameter processIdentifier: PID of the application.
    public init(processIdentifier: pid_t) {
        legacyValue = AXUIElementCreateApplication(processIdentifier)
    }

    /// Wraps a legacy ``AXUIElement``.
    /// - Parameter value: Legacy value to wrap.
    nonisolated init?(legacyValue value: CFTypeRef) {
        guard CFGetTypeID(value) == AXUIElementGetTypeID() else {
            return nil
        }
        legacyValue = unsafeBitCast(value, to: AXUIElement.self)
    }

    /// Sets the timeout of requests made to this element.
    /// - Parameter seconds: Timeout in seconds.
    public func setTimeout(seconds: Float) throws {
        let legacyValue = legacyValue as! AXUIElement
        let result = AXUIElementSetMessagingTimeout(legacyValue, seconds)
        let error = ElementError(from: result)
        switch error {
        case .success:
            break
        case .apiDisabled, .invalidElement, .notImplemented, .timeout:
            throw error
        default:
            fatalError("Unexpected error setting an accessibility element's request timeout: \(error)")
        }
    }

    /// Dumps this element to a data structure suitable to be encoded and serialized.
    /// - Parameters:
    ///   - recursiveParents: Whether to recursively dump this element's parents.
    ///   - recursiveChildren: Whether to recursively dump this element's children.
    /// - Returns: Serializable element structure.
    public func dump(recursiveParents: Bool = true, recursiveChildren: Bool = true) async throws -> [String: Any]? {
        do {
            var root = [String: Any]()
            let attributes = try listAttributes()
            var attributeValues = [String: Any]()
            for attribute in attributes {
                guard let value = try getAttribute(attribute) else {
                    continue
                }
                attributeValues[attribute] = encode(value: value)
            }
            root["attributes"] = attributeValues
            guard legacyValue as! AXUIElement != AXUIElementCreateSystemWide() else {
                return root
            }
            let parameterizedAttributes = try listParameterizedAttributes()
            root["parameterizedAttributes"] = parameterizedAttributes
            root["actions"] = try listActions()
            if recursiveParents, let parent = try getAttribute("AXParent") as? Element {
                root["parent"] = try await parent.dump(recursiveParents: true, recursiveChildren: false)
            }
            if recursiveChildren, let children = try getAttribute("AXChildren") as? [Any?] {
                var resultingChildren = [Any]()
                for child in children.lazy.compactMap({ $0 as? Element }) {
                    guard let child = try await child.dump(recursiveParents: false, recursiveChildren: true) else {
                        continue
                    }
                    resultingChildren.append(child)
                }
                root["children"] = resultingChildren
            }
            return root
        } catch ElementError.invalidElement {
            return nil
        } catch {
            throw error
        }
    }

    /// Encodes a value into a format suitable to be serialized.
    /// - Parameter value: Value to encode.
    /// - Returns: Data structure suitable to be serialized.
    internal func encode(value: Any) -> Any? {
        switch value {
        case is Bool, is Int64, is Double, is String:
            return value
        case let array as [Any?]:
            var resultArray = [Any]()
            resultArray.reserveCapacity(array.count)
            for element in array {
                guard let element = element, let element = encode(value: element) else {
                    continue
                }
                resultArray.append(element)
            }
            return resultArray
        case let dictionary as [String: Any]:
            var resultDictionary = [String: Any]()
            resultDictionary.reserveCapacity(dictionary.count)
            for pair in dictionary {
                guard let value = encode(value: pair.value) else {
                    continue
                }
                resultDictionary[pair.key] = value
            }
            return resultDictionary
        case let url as URL:
            return url.absoluteString
        case let attributedString as AttributedString:
            return String(attributedString.characters)
        case let point as CGPoint:
            return ["x": point.x, "y": point.y]
        case let size as CGSize:
            return ["width": size.width, "height": size.height]
        case let rect as CGRect:
            return ["x": rect.origin.x, "y": rect.origin.y, "width": rect.size.width, "height": rect.size.height]
        case let element as Element:
            return String(describing: element.legacyValue)
        case let error as ElementError:
            return "Error: \(error.localizedDescription)"
        default:
            return nil
        }
    }

    /// Checks whether this process is trusted and prompts the user to grant it accessibility privileges if it isn't.
    /// - Returns: Whether this process has accessibility privileges.
    @MainActor
    public static func confirmProcessTrustedStatus() -> Bool {
        return AXIsProcessTrustedWithOptions(
            [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        )
    }
}

extension Element: Hashable {
    public nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(legacyValue as! AXUIElement)
    }

    public static nonisolated func == (_ lhs: Element, _ rhs: Element) -> Bool {
        let lhs = lhs.legacyValue as! AXUIElement
        let rhs = rhs.legacyValue as! AXUIElement
        return lhs == rhs
    }
}
