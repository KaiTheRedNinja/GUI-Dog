//
//  GoogleGenerativeAI+Private.swift
//  GUIDog
//
//  Created by Kai Quan Tay on 29/7/24.
//

@testable import GoogleGenerativeAI
import HandsBot

typealias RPCError = GoogleGenerativeAI.RPCError

extension RPCError {
    var httpResponseCodePublic: Int { self.httpResponseCode }
    var messagePublic: String { self.message }
    var statusPublic: RPCStatus { self.status }
    var detailsPublic: [ErrorDetails] { self.details }
}

extension GenerateContentError: @retroactive LLMOtherError {
    public var description: String {
        switch self {
        case .promptImageContentError(let underlying):
            switch underlying {
            case .invalidUnderlyingImage:
                "An image passed to the LLM was invalid"
            case .couldNotAllocateDestination:
                "A valid image destination could not be located"
            case .couldNotConvertToJPEG:
                "Could not convert an image to JPEG"
            }
        case .internalError(let underlying):
            if let underlying = underlying as? RPCError {
                "The LLM failed due to an internal error: \(underlying.message)"
            } else {
                "The LLM failed due to an internal error"
            }
        case .promptBlocked(let response):
            if let safetyRatings = response.candidates.first?.safetyRatings {
                "The prompt was blocked by the LLM due to possible " + safetyRatings.compactMap { (rating) -> String? in
                    rating.probability != .negligible
                        ? {
                            switch rating.category {
                            case .unknown: nil
                            case .unspecified: nil
                            case .harassment: "harassment"
                            case .hateSpeech: "hate speech"
                            case .sexuallyExplicit: "sexual"
                            case .dangerousContent: "dangerous"
                            }
                        }()
                        : nil
                }
                .joinedWithOxfordComma(term: "or") + " content"
            } else {
                "The prompt was blocked by the LLM"
            }
        case .responseStoppedEarly(let reason, _):
            "The LLM stopped early due to " + {
                switch reason {
                case .unknown: "an unknown reason"
                case .unspecified, .other: "an unspecified reason"
                case .stop: "reaching a stop point"
                case .maxTokens: "exceeding the maximum output length"
                case .safety: "safety concerns"
                case .recitation: "copyright concerns"
                }
            }()
        case .invalidAPIKey:
            "The LLM stopped early due to invalid credentials"
        case .unsupportedUserLocation:
            "The LLM could not generate content as you are in an unsupported location"
        }
    }
}

extension Array where Element == String {
    func joinedWithOxfordComma(term: String) -> String {
        switch self.count {
        case 0: ""
        case 1, 2: self.map { $0.description }.joined(separator: " \(term) ")
        default:
            self
                .dropLast()
                .map { $0.description }
                .joined(separator: ", ") + ", \(term) " +
            self.last!.description
        }
    }
}
