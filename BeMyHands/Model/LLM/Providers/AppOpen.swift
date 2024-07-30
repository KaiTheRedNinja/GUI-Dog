//
//  AppOpen.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 26/7/24.
//

import AppKit
import GoogleGenerativeAI
import HandsBot

class AppOpen: StepCapabilityProvider {
    var name: String { "openApp" }

    var description: String { "Open an app with a specified name" }

    var instructions: String {
        """
        Call appOpen with the name of the app you want to open
        """
    }

    var functionDeclaration: LLMFuncDecl {
        FunctionDeclaration(
            name: self.name,
            description: self.description,
            parameters: [
                "appName": .init(type: .string, description: "The name of the app to open, without the .app suffix")
            ],
            requiredParameters: ["appName"]
        )
    }

    // Context not needed
    func updateContext() async throws {}
    func getContext() async throws -> String? { nil }

    func execute(function: any LLMFuncCall) async throws {
        guard let function = function as? FunctionCall,
              function.name == name, case let .string(appName) = function.args["appName"] else {
            throw LLMCommunicationError.invalidFunctionCall
        }

        if focusApp(named: appName) == false {
            throw AppOpenError.couldNotOpen
        }

        // wait for the app to open
        try await Task.sleep(for: .seconds(1))
    }

    func functionFailed() {}

    func focusApp(named appName: String) -> Bool {
        NSWorkspace.shared.launchApplication(appName)
    }

    static let global: AppOpen = .init()
}

enum AppOpenError: Error {
    case couldNotOpen
}
