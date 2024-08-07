//
//  Providers.swift
//  GUIDogKit
//
//  Created by Kai Quan Tay on 28/7/24.
//

import Foundation

/// Provides context to the LLM when deciding the steps to execute in phase one.
public protocol DiscoveryContextProvider {
    /// Called before ``getContext()`` to inform the provider to update the context
    func updateDiscoveryContext() async throws
    /// Get the context. Nil if context is unavailable.
    func getDiscoveryContext() async throws -> String?
}

/// Provides a capability to the LLM while executing a step.
///
/// The LLM can decide to use a capability when executing a step.
/// 1. ``name`` and ``description`` are retrieved for each capability and given to theLLM
/// 2. The LLM chooses a capability, or exits if none match the task
/// 3. ``instructions`` and ``getContext()`` are used to provide instructions to the LLM
/// for how to use the capability, and any context if the capability requires options.
public protocol StepCapabilityProvider {
    /// The name of the capability. Should be IDENTICAL to the ``functionDeclaration``'s `name`
    var name: String { get }
    /// A description of the capability. Should be a verb, eg. "Click on on-screen buttons"
    var description: String { get }
    /// The instructions for how to use the capability. Will be given verbatim to the LLM.
    var instructions: String { get }
    /// The function for the LLM to call to execute the step
    var functionDeclaration: any LLMFuncDecl { get }

    /// Called before ``getContext()`` to inform the provider to update the context
    func updateContext() async throws
    /// The context for using the capability, such as the currently open app. Nil if context is not
    /// needed.
    func getContext() async throws -> String?
    /// Called whenever the LLM responds with a function declaration with the correct name. Note
    /// that this DOES NOT guarentee that the function call is actually correct; this function should
    /// validate parameters before execution.
    func execute(function: any LLMFuncCall) async throws
    /// Called whenever the LLM responds but does not call the given function
    func functionFailed()
}

/// Provides the LLM
public protocol LLMProvider: AnyObject {
    /// Generates a response with a prompt and optional functions.
    ///
    /// Note that `functions` is an array of functions defined by the various capabilities'
    /// ``StepCapabilityProvider/functionDeclaration``s.
    ///
    /// The response's ``LLMFuncDecl`` property are not used by HandsBot, and are instead passed directly to
    /// the capability provider's ``StepCapabilityProvider/execute(function:)`` protocol method.
    func generateResponse(prompt: String, functions: [any LLMFuncDecl]?) async throws -> LLMResponse
}

/// A function call
public protocol LLMFuncCall {
    /// The name of the function
    var name: String { get }
}

/// A function declaration. This is empty because usually function requests are private
public protocol LLMFuncDecl {
}

/// LLM response
public struct LLMResponse {
    /// The text response
    public var text: String?
    /// The function call response
    public var functionCalls: [any LLMFuncCall]

    /// Creates an LLM response
    public init(text: String?, functionCalls: [any LLMFuncCall]) {
        self.text = text
        self.functionCalls = functionCalls
    }
}

/// Provides a UI to the ``HandsBot``.
///
/// Note that the `HandsBot` only informs the display delegate about changes in the LLM
/// communication state. The ``AccessibilityItemProvider`` is responsible for updating
/// the UI directly about actionable elements.
public protocol LLMDisplayDelegate: AnyObject {
    /// Shows the display UI
    func show() async
    /// Hides the display UI
    func hide() async
    /// Updates the display UI with a new state
    func update(state: LLMState) async
}
