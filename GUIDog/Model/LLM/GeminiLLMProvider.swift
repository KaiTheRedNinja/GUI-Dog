//
//  GeminiLLMProvider.swift
//  GUIDog
//
//  Created by Kai Quan Tay on 26/7/24.
//

import HandsBot
import OSLog
import GoogleGenerativeAI

private let logger = Logger(subsystem: #fileID, category: "GUIDog")

class GeminiLLMProvider: LLMProvider {
    func generateResponse(
        prompt: String,
        functions: [any LLMFuncDecl]?
    ) async throws -> LLMResponse {
        logger.info("Prompt: \(prompt)")
        logger.info("Prompt has \(functions?.count ?? 0) functions.")

        // if functions exists, isn't empty, but isn't a [FunctionDeclaration], error
        if let functions, !functions.isEmpty, !(functions is [FunctionDeclaration]) {
            throw LLMCommunicationError.invalidFunctionCall
        }

        // typecast functions properly
        let functions = (functions as? [FunctionDeclaration]) ?? []

        let model = GenerativeModel(
            name: "gemini-1.5-flash-latest",
            apiKey: Secrets.geminiKey,
            safetySettings: [
                // The API has a habit of saying that actions are harmful. We just ignore that.
                .init(harmCategory: .sexuallyExplicit, threshold: .blockNone),
                .init(harmCategory: .hateSpeech, threshold: .blockNone),
                .init(harmCategory: .harassment, threshold: .blockNone),
                .init(harmCategory: .dangerousContent, threshold: .blockNone)
            ],
            // Specify the function declaration.
            tools: functions.map { Tool(functionDeclarations: [$0]) }
        )

        var rawResponse: GenerateContentResponse?
        var failedAttempts = 0
        // allow up to 3 failed attempts due to internal 500 errors
        while failedAttempts < 3 && rawResponse == nil {
            do {
                rawResponse = try await model.generateContent(prompt)
            } catch {
                guard let error = error as? GenerateContentError else {
                    logger.error("Other error: \(error)")
                    throw error
                }

                switch error {
                case .internalError(let underlying):
                    if let underlying = underlying as? RPCError, underlying.httpResponseCodePublic == 500 {
                        failedAttempts += 1
                        logger.warning("Internal server error, retrying...")
                        // wait for a while before retrying.
                        // 1, 2, 3 seconds between each wait
                        try await Task.sleep(for: .seconds(failedAttempts + 1))
                        continue
                    }
                case let .responseStoppedEarly(reason, response):
                    let errorMsg = "Response stopped early: \(reason), \(response)"
                    logger.error("\(errorMsg)")
                default:
                    logger.error("Other google error: \(error)")
                }

                throw error
            }
        }

        guard let rawResponse else {
            throw LLMCommunicationError.emptyResponse
        }

        let rawResponseDesc = "Raw response: \(dumpDescription(of: rawResponse))"
        logger.info("\(rawResponseDesc)")

        return .init(text: rawResponse.text, functionCalls: rawResponse.functionCalls)

    }

    static let global = GeminiLLMProvider()
}

#if hasFeature(RetroactiveAttribute)
extension FunctionCall: @retroactive LLMFuncCall {}
extension FunctionDeclaration: @retroactive LLMFuncDecl {}
#else
extension FunctionCall: LLMFuncCall {}
extension FunctionDeclaration: LLMFuncDecl {}
#endif
