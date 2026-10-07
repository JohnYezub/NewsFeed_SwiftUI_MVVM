//
//  NewsAPIError+Presentation.swift
//  NewsFeed
//

import Foundation
import NewsKit

/// User-facing texts for load failures.
extension NewsAPIError {

    var title: String {
        switch self {
        case .missingAPIKey:
            "API key missing"
        case .transport(let code) where Self.offlineCodes.contains(code):
            "You're offline"
        case .transport:
            "Can't reach the server"
        case .http(statusCode: 401, _, _):
            "Invalid API key"
        case .http(statusCode: 429, _, _):
            "Too many requests"
        case .http:
            "Server error"
        case .invalidResponse:
            "Unexpected response"
        case .cancelled:
            "Cancelled"
        }
    }

    var message: String {
        switch self {
        case .missingAPIKey:
            "Add your own newsapi.org key to Config/Secrets.xcconfig and rebuild the app."
        case .transport(let code) where Self.offlineCodes.contains(code):
            "Check your internet connection and try again."
        case .transport:
            "The news service didn't respond. Try again in a moment."
        case .http(statusCode: 401, _, _):
            "newsapi.org rejected the key. Check NEWS_API_KEY in Config/Secrets.xcconfig."
        case .http(statusCode: 429, _, _):
            "The newsapi.org request limit is reached. Try again later."
        case .http(let statusCode, _, let message):
            message ?? "newsapi.org responded with HTTP \(statusCode)."
        case .invalidResponse:
            "The news service sent data the app can't read."
        case .cancelled:
            "The request was cancelled."
        }
    }

    var systemImage: String {
        switch self {
        case .missingAPIKey, .http(statusCode: 401, _, _):
            "key.slash"
        case .transport(let code) where Self.offlineCodes.contains(code):
            "wifi.slash"
        default:
            "exclamationmark.triangle"
        }
    }

    private static let offlineCodes: Set<URLError.Code> = [
        .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff
    ]
}
