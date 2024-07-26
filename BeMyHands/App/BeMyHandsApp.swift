//
//  BeMyHandsApp.swift
//  BeMyHands
//
//  Created by Kai Quan Tay on 8/7/24.
//

import SwiftUI
import Access
import HandsBot
import GoogleGenerativeAI
import OSLog

private let logger = Logger(subsystem: #file, category: "BeMyHands")

@main
struct BeMyHandsApp: App {
    @State var handsBot: HandsBot?
    @State var accessManager: AccessManager = .init()
    @State var overlayManager: OverlayManager = .init()

    var body: some Scene {
        MenuBarExtra {
            MenuExtraView(triggerLLM: triggerLLM)
        } label: {
            Image(systemName: "hand.wave.fill")
                .task {
                    accessManager.uiDelegate = overlayManager
                    await accessManager.setup()
                }
        }
    }

    func triggerLLM() {
        // create the hands bot if it doesn't exist
        guard handsBot == nil else { return }

        Task {
            let goal = await overlayManager.requestGoal()

            guard let goal else {
                // TODO: inform the user that the goal is empty
                return
            }

            let llmManager = HandsBot()
            self.handsBot = llmManager
            llmManager.discoveryContentProviders = [accessManager]
            llmManager.stepCapabilityProviders = [accessManager, AppOpen.global]
            llmManager.uiDelegate = overlayManager
            llmManager.llmProvider = GeminiLLMProvider.global

            await llmManager.requestLLMAction(goal: goal)
            // remove the manager
            self.handsBot = nil
        }
    }
}

class GeminiLLMProvider: LLMProvider {
    func generateResponse(
        prompt: String,
        functions: [any LLMFuncDecl]?
    ) async throws -> LLMResponse {
        guard let functions = functions as? [FunctionDeclaration] else {
            throw LLMCommunicationError.invalidFunctionCall
        }

        let model = GenerativeModel(
            name: "gemini-1.5-flash",
            apiKey: Secrets.geminiKey,
            // Specify the function declaration.
            tools: [Tool(functionDeclarations: functions)],
            toolConfig: functions.isEmpty ? nil : .init(
                functionCallingConfig: .init(
                    mode: .any
                )
            )
        )

        let rawResponse: GenerateContentResponse
        do {
            rawResponse = try await model.generateContent(prompt)
        } catch {
            if let error = error as? GenerateContentError {
                switch error {
                case let .responseStoppedEarly(reason, response):
                    let errorMsg = "Response stopped early: \(reason), \(response)"
                    logger.error("\(errorMsg)")
                default:
                    logger.error("Other google error: \(error)")
                }
            } else {
                logger.error("Other error: \(error)")
            }

            throw error
        }

        return .init(text: rawResponse.text, functionCalls: rawResponse.functionCalls)
    }

    static let global = GeminiLLMProvider()
}

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

extension FunctionCall: @retroactive LLMFuncCall {}
extension FunctionDeclaration: @retroactive LLMFuncDecl {}
