//
//  KeyboardProvider.swift
//  GUIDog
//
//  Created by Kai Quan Tay on 29/7/24.
//

import HandsBot
import Cocoa
import GoogleGenerativeAI

@available(swift, deprecated: 5.0, obsoleted: 5.0, message: "KeyboardProvider is nonfunctional")
class KeyboardProvider: StepCapabilityProvider {
    var name: String { "keyboardType" }

    var description: String {
        """
        Simulate typing a given text using the keyboard. Can only be called if the focused \
        element is a text field. Before selecting this action, make sure `executeAction` is called \
        to focus the text field.
        """
    }

    var instructions: String {
        """
        Call keyboardType with the contents of the text you want to type
        """
    }

    var functionDeclaration: any LLMFuncDecl {
        FunctionDeclaration(
            name: self.name,
            description: self.description,
            parameters: [
                "text": .init(type: .string, description: "The text you want to type")
            ],
            requiredParameters: ["text"]
        )
    }

    func execute(function: any LLMFuncCall) async throws {
        guard let function = function as? FunctionCall,
              function.name == name, case let .string(text) = function.args["text"] else {
            throw LLMCommunicationError.invalidFunctionCall
        }

        write(text: text)
    }

    func write(text: String) {
        let utf16Chars = Array(text.utf16)

        // keydown
        let event1 = CGEvent(keyboardEventSource: nil, virtualKey: 0x31, keyDown: true)
        event1?.flags = .maskNonCoalesced
        event1?.keyboardSetUnicodeString(stringLength: utf16Chars.count, unicodeString: utf16Chars)
        event1?.post(tap: .cghidEventTap)

        // keyup
        let event2 = CGEvent(keyboardEventSource: nil, virtualKey: 0x31, keyDown: false)
        event2?.flags = .maskNonCoalesced
        event2?.post(tap: .cghidEventTap)
    }

    // excluded functions
    func updateContext() async throws {}
    func getContext() async throws -> String? { nil }
    func functionFailed() {}

//    static let global: KeyboardProvider = .init()
}
