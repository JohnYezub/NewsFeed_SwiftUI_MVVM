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
4. Open `NewsFeed.xcodeproj` (Xcode 16+) and run the `NewsFeed` scheme. If the key is empty the console shows `NewsAPI key is missing` and the list stays empty.

How it works: `Secrets.xcconfig` → build setting `NEWS_API_KEY` → Info.plist `NewsAPIKey` (app, widget and watch extension) → `NewsAPIConfiguration`, which sends it in the `X-Api-Key` header.

### Tests:
```bash
xcodebuild test -project NewsFeed.xcodeproj -scheme NewsFeed -destination 'platform=iOS Simulator,name=iPhone 17'
```
