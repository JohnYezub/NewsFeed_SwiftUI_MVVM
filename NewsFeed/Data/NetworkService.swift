//
//  NetworkService.swift
//  NewsFeed
//
//  Created by   admin on 17.11.2020.
//

import Foundation
import UIKit

nonisolated enum NetworkService {

    /// Loads top headlines; `nil` means the request failed
    /// (missing key, transport/HTTP error or undecodable body).
    /// `@concurrent` keeps JSON decoding off the caller's actor (usually the main actor).
    @concurrent
    static func loadArticles(configuration: NewsAPIConfiguration? = .main,
                             session: URLSession = .shared) async -> [Article]? {
        guard let configuration else {
            print("NewsAPI key is missing: get your own key at https://newsapi.org/register, copy Config/Secrets.example.xcconfig to Config/Secrets.xcconfig and set NEWS_API_KEY = <your key>")
            return nil
        }

        do {
            let (data, response) = try await session.data(for: configuration.topHeadlinesRequest)
            return articles(from: data, response: response)
        } catch {
            if !error.isCancellation {
                print("Failed to load news: \(error.localizedDescription)")
            }
            return nil
        }
    }

    static func articles(from data: Data, response: URLResponse) -> [Article]? {
        if let httpResponse = response as? HTTPURLResponse, !(200..<300).contains(httpResponse.statusCode) {
            print("NewsAPI responded with HTTP \(httpResponse.statusCode)")
            return nil
        }
        do {
            return try JSONDecoder().decode(JSONModel.self, from: data).articles
        } catch {
            print("Failed to decode news: \(error)")
            return nil
        }
    }
}

nonisolated enum ImageStore {

    /// `@concurrent` keeps image decoding off the caller's actor (usually the main actor).
    @concurrent
    static func image(from urlString: String, session: URLSession = .shared) async -> UIImage? {
        guard let url = URL(string: urlString) else {
            print("failed to produce URL for image")
            return nil
        }
        do {
            let (data, _) = try await session.data(from: url)
            return UIImage(data: data)
        } catch {
            if !error.isCancellation {
                print("failed to load image: \(error.localizedDescription)")
            }
            return nil
        }
    }
}

private nonisolated extension Error {
    var isCancellation: Bool {
        self is CancellationError || (self as? URLError)?.code == .cancelled
    }
}
