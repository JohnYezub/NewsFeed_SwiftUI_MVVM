# SwiftUI with MVVM

Simple SwiftUI App demonstrates lists of US news (thanks https://newsapi.org/).
UPDT: Add WidgetKit and deeplinks. Add WatchOS support.

![NewsFeed](./news2.gif "SwiftUI with MVVM")



### Usage:
* `SwiftUI`
* `WidgetKit`
* `WatchOS`
* `MVVM pattern`
* `Network services`


### Setup:
1. Get a free API key at https://newsapi.org/register
2. Create a local secrets file (it is git-ignored) and put the key there:
   ```bash
   cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig
   ```
3. Open `NewsFeed.xcodeproj` (Xcode 16+) and run the `NewsFeed` scheme.

The key flows `Secrets.xcconfig` → `NEWS_API_KEY` → Info.plist `NewsAPIKey` and is sent in the `X-Api-Key` header.

### Tests:
```bash
xcodebuild test -project NewsFeed.xcodeproj -scheme NewsFeed -destination 'platform=iOS Simulator,name=iPhone 17'
```
