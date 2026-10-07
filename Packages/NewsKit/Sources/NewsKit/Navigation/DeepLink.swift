//
//  DeepLink.swift
//  NewsKit
//

import Foundation

/// URLs the widget uses to open the app, e.g. `newsfeed://article?url=https%3A%2F%2Fexample.com%2Fstory`.
///
/// Articles are referenced by their URL (their stable id), not by position, so a link keeps
/// pointing at the same story even if the app's list is newer than the widget's.
public enum DeepLink: Hashable, Sendable {
    case headlines
    case article(URL)

    /// Must match `CFBundleURLSchemes` in the app's Info.plist.
    public static let scheme = "newsfeed"

    public init?(url: URL) {
        guard url.scheme?.lowercased() == Self.scheme,
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { return nil }
        switch components.host {
        case "headlines":
            self = .headlines
        case "article":
            guard let value = components.queryItems?.first(where: { $0.name == "url" })?.value,
                let articleURL = URL(string: value),
                articleURL.isWebLink
            else { return nil }
            self = .article(articleURL)
        default:
            return nil
        }
    }

    public var url: URL {
        var components = URLComponents()
        components.scheme = Self.scheme
        switch self {
        case .headlines:
            components.host = "headlines"
        case .article(let articleURL):
            components.host = "article"
            components.queryItems = [URLQueryItem(name: "url", value: articleURL.absoluteString)]
        }
        // Scheme and host are fixed literals and query values are percent-encoded, so this cannot fail.
        // swiftlint:disable:next force_unwrapping
        return components.url!
    }
}
