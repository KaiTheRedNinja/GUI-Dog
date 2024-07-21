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
            llmManager.apiKeyProvider = APIKey.global

            await llmManager.requestLLMAction(goal: goal)
            // remove the manager
            self.handsBot = nil
        }
    }
}

class APIKey: APIKeyProvider {
    func getKey() -> String {
        Secrets.geminiKey
    }

    static let global: APIKey = .init()
}

class AppOpen: StepCapabilityProvider {
    var name: String { "openApp" }

    var description: String { "Open an app with a specified name" }

    var instructions: String {
        """
        Call appOpen with the name of the app you want to open
        """
    }

    var functionDeclaration: GoogleGenerativeAI.FunctionDeclaration {
        .init(
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

    func execute(function: FunctionCall) async throws {
        guard function.name == name, case let .string(appName) = function.args["appName"] else {
            throw LLMCommunicationError.invalidFunctionCall
        }

        if focusApp(named: appName) == false {
            throw AppOpenError.couldNotOpen
        }
    }

    func functionFailed() {}

    func focusApp(named appName: String) -> Bool {
        guard let appPath = FileManager.default.urls(
            for: .applicationDirectory,
            in: .systemDomainMask
        ).first?.appendingPathComponent("\(appName).app") else {
            return false
        }

        return NSWorkspace.shared.open(appPath)
    }

    static let global: AppOpen = .init()
}

enum AppOpenError: Error {
    case couldNotOpen
}
