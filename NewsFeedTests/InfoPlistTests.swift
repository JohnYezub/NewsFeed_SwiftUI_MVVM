//
//  InfoPlistTests.swift
//  NewsFeedTests
//

import Foundation
import NewsKit
import Testing

/// The API key reaches NewsKit only through Info.plist, so every target must forward the build setting.
struct InfoPlistTests {

    @Test func appInfoPlistDeclaresAPIKeyEntry() {
        // The value comes from the git-ignored Secrets.xcconfig and may be empty on CI,
        // but the Info.plist entry must exist so the build setting reaches the app.
        #expect(Bundle.main.object(forInfoDictionaryKey: NewsAPIConfiguration.infoPlistKey) is String)
    }

    @Test(arguments: ["NewsFeed/Info.plist", "NewsWidget/Info.plist", "NewsFeedWatch/Info.plist"])
    func everyTargetInfoPlistForwardsAPIKeyBuildSetting(path: String) throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: repositoryRoot.appendingPathComponent(path))
        let plist = try #require(PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any])
        #expect(plist[NewsAPIConfiguration.infoPlistKey] as? String == "$(NEWS_API_KEY)")
    }
}
