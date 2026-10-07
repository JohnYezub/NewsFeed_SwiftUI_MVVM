//
//  NetworkService.swift
//  NewsFeed
//
//  Created by   admin on 17.11.2020.
//
import Foundation
import UIKit
class NetworkService {
    
    /// Loads top headlines. `completion` is always called exactly once, on the main queue;
    /// `nil` means the request failed (missing key, transport/HTTP error or undecodable body).
    static func loadData(completion: @escaping ([Article]?) -> ()) {
        
        let completeOnMain: ([Article]?) -> () = { articles in
            DispatchQueue.main.async { completion(articles) }
        }
        
        guard let configuration = NewsAPIConfiguration.main else {
            print("NewsAPI key is missing: get your own key at https://newsapi.org/register, copy Config/Secrets.example.xcconfig to Config/Secrets.xcconfig and set NEWS_API_KEY = <your key>")
            completeOnMain(nil)
            return
        }

        let task = URLSession.shared.dataTask(with: configuration.topHeadlinesRequest) { data, response, error in
            completeOnMain(articles(from: data, response: response, error: error))
        }
        task.resume()
    }
    
    static func articles(from data: Data?, response: URLResponse?, error: Error?) -> [Article]? {
        if let error = error {
            print("Failed to load news: \(error.localizedDescription)")
            return nil
        }
        if let httpResponse = response as? HTTPURLResponse, !(200..<300).contains(httpResponse.statusCode) {
            print("NewsAPI responded with HTTP \(httpResponse.statusCode)")
            return nil
        }
        guard let data = data else { return nil }
        do {
            return try JSONDecoder().decode(JSONModel.self, from: data).articles
        } catch {
            print("Failed to decode news: \(error)")
            return nil
        }
    }
    
}

final class ImageStore {

    static func downloadImageBy(url: String, completion: @escaping (UIImage)->Void) {
        
        guard let url = URL(string: url) else {
            print("failed to produce URL for image")
            return }
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, error == nil {
                if let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    completion(image)
                }
                } else {
                    print("failed to get Image from data")
                }
            } else {
                if error != nil {
                    print(error?.localizedDescription as Any)
                }
                if data == nil {
                    print("no data for Image")
                }
            }
        }
        task.resume()
    }
}
