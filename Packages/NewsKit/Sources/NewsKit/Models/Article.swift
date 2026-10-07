//
//  Article.swift
//  NewsKit
//

import Foundation

/// A news article from newsapi.org.
///
/// Identified by its URL, which stays the same across reloads (unlike a generated UUID).
public struct Article: Hashable, Identifiable, Sendable {

    public struct Source: Hashable, Sendable, Codable {
        public let id: String?
        public let name: String

        public init(id: String? = nil, name: String) {
            self.id = id
            self.name = name
        }
    }

    public let source: Source
    public let author: String?
    public let title: String
    public let description: String?
    public let url: URL
    public let urlToImage: URL?
    /// `nil` when the API sends a date in a format we cannot parse.
    public let publishedAt: Date?

    public var id: URL { url }

    public init(
        source: Source,
        author: String? = nil,
        title: String,
        description: String? = nil,
        url: URL,
        urlToImage: URL? = nil,
        publishedAt: Date? = nil
    ) {
        self.source = source
        self.author = author
        self.title = title
        self.description = description
        self.url = url
        self.urlToImage = urlToImage
        self.publishedAt = publishedAt
    }
}

extension Article: Codable {

    private enum CodingKeys: String, CodingKey {
        case source, author, title, description, url, urlToImage, publishedAt
    }

    /// Only `source`, `title` and a valid `url` are required; malformed optional fields become `nil`
    /// instead of failing the whole response.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        source = try container.decode(Source.self, forKey: .source)
        title = try container.decode(String.self, forKey: .title)

        let urlString = try container.decode(String.self, forKey: .url)
        // Only web links: the app opens them in SFSafariViewController, which rejects other schemes.
        guard let url = URL(string: urlString), url.isWebLink else {
            throw DecodingError.dataCorruptedError(forKey: .url, in: container, debugDescription: "Invalid article URL: \(urlString)")
        }
        self.url = url

        author = try container.decodeIfPresent(String.self, forKey: .author)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        urlToImage = try container.decodeIfPresent(String.self, forKey: .urlToImage).flatMap { URL(string: $0) }.flatMap {
            $0.isWebLink ? $0 : nil
        }
        publishedAt = try container.decodeIfPresent(String.self, forKey: .publishedAt).flatMap(Self.parseDate)
    }

    /// Writes the same shape the API sends, so cached articles go through the same decoder.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(source, forKey: .source)
        try container.encodeIfPresent(author, forKey: .author)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(url.absoluteString, forKey: .url)
        try container.encodeIfPresent(urlToImage?.absoluteString, forKey: .urlToImage)
        try container.encodeIfPresent(
            publishedAt?.formatted(Date.ISO8601FormatStyle(includingFractionalSeconds: true)),
            forKey: .publishedAt)
    }

    /// newsapi.org sends ISO 8601 dates, sometimes with fractional seconds.
    static func parseDate(_ string: String) -> Date? {
        if let date = try? Date(string, strategy: .iso8601) {
            return date
        }
        return try? Date(string, strategy: Date.ISO8601FormatStyle(includingFractionalSeconds: true))
    }
}

extension URL {
    /// An absolute `http` or `https` URL with a host.
    var isWebLink: Bool {
        guard let scheme = scheme?.lowercased(), scheme == "https" || scheme == "http" else { return false }
        return host?.isEmpty == false
    }
}
