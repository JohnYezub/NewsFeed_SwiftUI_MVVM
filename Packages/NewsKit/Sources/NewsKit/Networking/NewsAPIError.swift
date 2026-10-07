//
//  NewsAPIError.swift
//  NewsKit
//

import Foundation

public enum NewsAPIError: Error, Equatable, Sendable {
    /// No API key in Info.plist; see `NewsAPIConfiguration`.
    case missingAPIKey
    /// The request did not complete (offline, timeout, TLS, ...).
    case transport(URLError.Code)
    /// The server answered with a non-2xx status. `code` and `message` come from newsapi.org's error body.
    case http(statusCode: Int, code: String?, message: String?)
    /// The body could not be decoded.
    case invalidResponse
    /// The calling task was cancelled.
    case cancelled
}
