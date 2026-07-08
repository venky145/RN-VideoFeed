# Changelog

All notable changes to this project are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2026-07-08

### Added
- **iOS player pool** (`VideoFeedPlayerPool`) — keeps ~8 warm `AVPlayer` instances so
  scrolling back resumes where you left off (parity with Android’s ExoPlayer pool).
- Loading **spinner** while a clip buffers (iOS + Android).
- Per-cell **position label** (`n / total · id`) so scroll progress is clear even on
  black / buffering frames.

### Fixed
- iOS: scrolling to the next video sometimes never started playback (slow drags that
  skip `scrollViewDidEndDecelerating`; missing cell-ready retry).
- iOS: cells destroyed players on reuse — scroll-back to earlier clips often stayed black.
- iOS: `VideoFeedViewManager` crash on Old Architecture
  (`view(forReactTag:)` called off the UIManager queue).
- Sample app: clearer badges, three reliable sample clips, longer `setVideos` mount delay.

### Changed
- `VideoFeedSample` is the **one** demo app in this repo (linked to `file:../rn-videofeed`).
  Real apps should `npm install rn-videofeed` — same API as the sample.

## [0.1.0] - 2026-07-02

### Added
- Initial release of **rn-videofeed** — native vertical full-screen video feed for React Native.
- iOS implementation using AVPlayer + `UICollectionView`.
- Android implementation using Media3 ExoPlayer + `RecyclerView`.
- Reels-style **resume where you left off**: a warm ExoPlayer pool (~8 players) keeps
  playback position on scroll instead of restarting from the beginning.
- Thumbnail placeholder shown until the video is ready; skipped when resuming a warm player.
- Tap to play/pause, auto-pause on scroll and when the app is backgrounded.
- Imperative API via `VideoFeedManagerNative` (`setVideos`, `appendVideos`, `setFeedActive`,
  `playVideo`, `pauseVideo`, `togglePlayPause`, `isVideoPlaying`).
- Events: `onVideoChange`, `onVideoTapped`, `onEndReached`.
- `VideoFeedSample` React Native 0.77 example app.
- GitHub Actions CI (typecheck, lint, Android library build).

[0.1.1]: https://github.com/venky145/RN-VideoFeed/releases/tag/v0.1.1
[0.1.0]: https://github.com/venky145/RN-VideoFeed/releases/tag/v0.1.0
