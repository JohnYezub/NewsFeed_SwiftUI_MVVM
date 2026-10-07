# SwiftUI with MVVM

[![CI](https://github.com/JohnYezub/NewsFeed_SwiftUI_MVVM/actions/workflows/ci.yml/badge.svg)](https://github.com/JohnYezub/NewsFeed_SwiftUI_MVVM/actions/workflows/ci.yml)

Simple SwiftUI App demonstrates lists of US news (thanks https://newsapi.org/).
UPDT: Add WidgetKit and deeplinks. Add WatchOS support.

![NewsFeed](./news2.gif "SwiftUI with MVVM")



### Usage:
* `SwiftUI`
* `WidgetKit`
* `WatchOS`
* `MVVM pattern`
* `Network services`


### Requirements:
* Xcode 26+ (Swift 6.2, strict concurrency, MainActor by default)
* iOS 18+ (app and widget), watchOS 11+ (standalone SwiftUI watch app)

### Setup: your own NewsAPI key
The app needs a [newsapi.org](https://newsapi.org) API key. **Please use your own key** — it is free:

1. Register at https://newsapi.org/register and copy your API key.
2. Create a local secrets file from the template (the copy is git-ignored, so your key never gets committed):
   ```bash
   cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig
   ```
3. Open `Config/Secrets.xcconfig` and paste the key after `=` (no quotes):
   ```
   NEWS_API_KEY = 0123456789abcdef0123456789abcdef
   ```
4. Open `NewsFeed.xcodeproj` (Xcode 26+) and run the `NewsFeed` scheme. If the key is empty the console shows `NewsAPI key is missing` and the list stays empty.

Signing: the targets use the App Group `group.EvgenyEzub.NewsFeed`. With automatic signing Xcode registers it for your team; if you use your own team, change the group in `Config/Entitlements/*.entitlements` and `FileHeadlinesStore.appGroupIdentifier`.

How it works: `Secrets.xcconfig` → build setting `NEWS_API_KEY` → Info.plist `NewsAPIKey` (iOS app and widget, watch app and widget) → `NewsAPIConfiguration`, which sends it in the `X-Api-Key` header.

### Project structure:
* `Packages/NewsKit` — local Swift package shared by every target: `Article` model, `LiveNewsAPIClient` (async/await, typed `NewsAPIError`), `NewsRepository` (memory and shared on-disk cache, request coalescing, de-duplication), `DeepLink`, date formatting and the widget's `HeadlineSchedule`.
* `NewsFeed` — iOS app (SwiftUI, MVVM with `@Observable`): `App/`, `Features/NewsList`, `Features/ArticleDetail`; `Shared/` (view model, error texts, sample data) is also compiled into the watch app.
* `NewsWidget` — WidgetKit extension (small/medium/large, Lock Screen). Its sources are shared with `NewsFeedWatchWidget` (watch complications). Tapping a headline opens `newsfeed://article?url=<article URL>` (see `DeepLink` in NewsKit).
* App and widgets share the last downloaded headlines through the App Group `group.EvgenyEzub.NewsFeed` (`Config/Entitlements`), so they show the same stories and keep working offline.
* `NewsFeedWatch` — standalone SwiftUI watchOS app.
* `NewsFeedTests` — app tests; `Packages/NewsKit/Tests` — package tests (Swift Testing).

### Tests:
All tests (app + NewsKit) via the `NewsFeed` scheme and its test plan:
```bash
xcodebuild test -project NewsFeed.xcodeproj -scheme NewsFeed -destination 'platform=iOS Simulator,name=iPhone 17'
```
NewsKit only, on macOS in about a second:
```bash
swift test --package-path Packages/NewsKit
```

### Code style

Use Xcode 26.3's toolchain formatter (`swift format`) and SwiftLint 0.57.1, the version pinned in CI. SwiftLint can be installed with Homebrew (`brew install swiftlint`); check `swiftlint version` when comparing local results with CI.

Check lint rules and formatting without changing files:
```bash
scripts/lint.sh
```
Format Swift sources in place (4 spaces, 140-character lines):
```bash
scripts/format.sh
```
Both scripts cover the app, widgets, watch app and all tests, including NewsKit. SwiftLint runs outside Xcode build phases, so it works with user script sandboxing enabled. Keep formatting changes separate from behavior changes when committing.

`implicit_return` is disabled to preserve explicit returns. Nesting up to two levels keeps models such as `HeadlineSchedule.Plan.Item`. `force_unwrapping` remains enabled, with documented local exceptions for fixed URL literals and validated URL components. `unused_import` requires SwiftLint's separate analyzer and a compiler log, so it is not part of the lint-only script.

### CI

GitHub Actions runs on pushes to `main`, pull requests and manual dispatches. All five jobs run independently on `macos-26` with **Xcode 26.3**, explicitly selected at `/Applications/Xcode_26.3.app` and printed in each job's log. The runner and Xcode path are listed in [actions/runner-images](https://github.com/actions/runner-images/blob/main/images/macos/macos-26-arm64-Readme.md).

- **lint** — strict SwiftLint and toolchain formatting checks.
- **newskit** — NewsKit tests on macOS.
- **ios** — the `NewsFeed` test plan (`NewsFeedTests` and `NewsKitTests`), using the first available iPhone on the latest installed iOS runtime.
- **watch** — the watchOS app and widget simulator build.
- **release-build** — the iOS app and widget Release simulator build.

The test plan enables coverage; the iOS job adds `xccov` target coverage to the job summary and uploads `.xcresult` on failure. There is no coverage threshold yet. Nothing is cached: NewsKit is a local package without remote dependencies, and DerivedData caches are fragile. New runs cancel older runs for the same branch, and every job has a timeout. Dependabot checks GitHub Actions dependencies weekly.

CI requires no NewsAPI key or repository secrets: the optional `Config/Secrets.xcconfig` include can be absent, and tests use stubs and mocks.
