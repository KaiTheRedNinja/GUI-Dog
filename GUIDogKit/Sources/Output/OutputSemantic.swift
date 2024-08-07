// swiftlint:disable missing_docs

/// Semantic Accessibility descriptions.
public enum OutputSemantic {
    case application(String)
    case window(String)
    case boundary
    case selectedChildrenCount(Int)
    case rowCount(Int)
    case columnCount(Int)
    case label(String)
    case role(String)
    case boolValue(Bool)
    case intValue(Int64)
    case floatValue(Double)
    case stringValue(String)
    case urlValue(String)
    case placeholderValue(String)
    case selectedText(String)
    case selectedTextGrew(String)
    case selectedTextShrank(String)
    case insertedText(String)
    case removedText(String)
    case help(String)
    case updatedLabel(String)
    case edited
    case selected
    case disabled
    case entering
    case exiting
    case next
    case previous
    case noFocus
    case capsLockStatusChanged(Bool)
    case apiDisabled
    case notAccessible
    case timeout

    public var description: String {
        switch self {
        case .apiDisabled:
            "Accessibility interface disabled"
        case let .application(label):
            label
        case let .boolValue(bool):
            bool ? "On" : "Off"
        case .boundary:
            ""
        case let .capsLockStatusChanged(status):
            "CapsLock \(status ? "On" : "Off")"
        case let .columnCount(count):
            "\(count) columns"
        case .disabled:
            "Disabled"
        case .edited:
            "Edited"
        case .entering:
            "Entering"
        case .exiting:
            "Exiting"
        case let .floatValue(float):
            String(format: "%.01.02f", arguments: [float])
        case let .help(help):
            help
        case let .insertedText(text):
            text
        case let .intValue(int):
            String(int)
        case let .label(label):
            label
        case .next:
            ""
        case .noFocus:
            "Nothing in focus"
        case .notAccessible:
            "Application not accessible"
        case let .placeholderValue(value):
            value
        case .previous:
            ""
        case let .removedText(text):
            text
        case let .role(role):
            role
        case let .rowCount(count):
            "\(count) rows"
        case .selected:
            "Selected"
        case let .selectedChildrenCount(count):
            "\(count) selected \(count == 1 ? "child" : "children")"
        case let .selectedText(text):
            text
        case let .selectedTextGrew(text):
            text
        case let .selectedTextShrank(text):
            text
        case let .stringValue(string):
            string
        case .timeout:
            "Application is not responding"
        case let .updatedLabel(label):
            label
        case let .urlValue(url):
            url
        case let .window(label):
            label
        }
    }
}

// swiftlint:enable missing_docs
