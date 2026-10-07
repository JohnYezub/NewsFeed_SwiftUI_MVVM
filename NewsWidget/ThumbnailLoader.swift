//
//  ThumbnailLoader.swift
//  NewsWidget
//

#if os(iOS)
import Foundation
import ImageIO
import NewsKit
import UniformTypeIdentifiers

/// Downloads article images and shrinks them to widget size. Widgets cannot load remote images
/// while rendering and have a small memory budget, so this runs in the timeline provider.
nonisolated enum ThumbnailLoader {

    static let maxPixelSize = 300

    static func thumbnails(for articles: [Article], session: URLSession = .shared) async -> [Article.ID: Data] {
        await withTaskGroup(of: (Article.ID, Data?).self) { group in
            for article in articles {
                guard let imageURL = article.urlToImage else { continue }
                group.addTask {
                    var request = URLRequest(url: imageURL)
                    request.timeoutInterval = 5
                    guard let (data, _) = try? await session.data(for: request) else { return (article.id, nil) }
                    return (article.id, downscaled(data))
                }
            }
            var result: [Article.ID: Data] = [:]
            for await (id, data) in group {
                result[id] = data
            }
            return result
        }
    }

    /// JPEG no larger than `maxPixelSize` on its longer side, decoded without loading the full image into memory.
    static func downscaled(_ data: Data) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }

        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.8] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return output as Data
    }
}
#endif
