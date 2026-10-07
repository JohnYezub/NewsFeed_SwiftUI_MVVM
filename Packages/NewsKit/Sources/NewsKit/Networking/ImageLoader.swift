//
//  ImageLoader.swift
//  NewsKit
//

#if canImport(UIKit)
import Foundation
import UIKit

public enum ImageLoader {

    /// `@concurrent` keeps image decoding off the caller's actor (usually the main actor).
    /// Returns `nil` on any failure; a missing thumbnail is not worth surfacing to the user.
    @concurrent
    public static func image(at url: URL, session: URLSession = .shared) async -> UIImage? {
        guard let (data, _) = try? await session.data(from: url) else { return nil }
        return UIImage(data: data)
    }
}
#endif
