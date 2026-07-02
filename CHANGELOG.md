# Changelog

All notable changes to this project are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[0.1.0]: https://github.com/venky145/RN-VideoFeed/releases/tag/v0.1.0
