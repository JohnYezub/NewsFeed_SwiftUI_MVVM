//
//  NewsAPIConfiguration.swift
//  NewsFeed
//

import Foundation

/// Endpoint and credentials for newsapi.org.
///
/// The API key is never stored in source code. It is injected at build time:
/// `Config/Secrets.xcconfig` → `NEWS_API_KEY` → Info.plist `NewsAPIKey`.
struct NewsAPIConfiguration {

    static let infoPlistKey = "NewsAPIKey"

    let apiKey: String
    let country: String

    init?(apiKey: String?, country: String = "us") {
        guard let apiKey = apiKey?.trimmingCharacters(in: .whitespacesAndNewlines),
              !apiKey.isEmpty else { return nil }
        self.apiKey = apiKey
        self.country = country
    }

    init?(infoDictionary: [String: Any]?) {
        self.init(apiKey: infoDictionary?[Self.infoPlistKey] as? String)
    }

    /// Configuration of the running app or extension, `nil` if the key is not set.
    static var main: NewsAPIConfiguration? {
        NewsAPIConfiguration(infoDictionary: Bundle.main.infoDictionary)
    }

    var topHeadlinesURL: URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "newsapi.org"
        components.path = "/v2/top-headlines"
        components.queryItems = [URLQueryItem(name: "country", value: country)]
        // Scheme, host and path are valid literals, so the URL is always constructible.
        return components.url!
    }

    /// The key goes in a header rather than the query string so it does not end up in URL logs and caches.
    var topHeadlinesRequest: URLRequest {
        var request = URLRequest(url: topHeadlinesURL)
        request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")
        return request
    }
}
