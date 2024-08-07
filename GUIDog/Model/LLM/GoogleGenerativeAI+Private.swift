//
//  GoogleGenerativeAI+Private.swift
//  GUIDog
//
//  Created by Kai Quan Tay on 29/7/24.
//

@testable import GoogleGenerativeAI

typealias RPCError = GoogleGenerativeAI.RPCError

extension RPCError {
    var httpResponseCodePublic: Int { self.httpResponseCode }
    var messagePublic: String { self.message }
    var statusPublic: RPCStatus { self.status }
    var detailsPublic: [ErrorDetails] { self.details }
}
