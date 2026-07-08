# rn-videofeed

Native vertical full-screen video feed for React Native — Reels / TikTok / Shorts style.
Playback is powered by **AVPlayer** on iOS and **Media3 ExoPlayer** on Android, driven by a
native `UICollectionView` / `RecyclerView` for smooth scrolling with many videos.

- Full-page vertical paging (snap-to-page)
- Seamless resume — scrolling back continues **where you left off** instead of restarting
- Warm player pool (keeps ~8 videos ready) on **iOS and Android**
- Thumbnail + loading spinner until ready; position label on each cell
- Tap to play/pause; auto-pause on scroll/background
- Pagination hook (`onEndReached`) and per-video change events

## Requirements

- React Native >= 0.76
- iOS 16.0+
- Android — **Old Architecture** (`newArchEnabled=false`); the component is a legacy `SimpleViewManager`
- iOS — prefer Old Architecture (`RCT_NEW_ARCH_ENABLED=0` for `pod install`)

## Install

```bash
npm install rn-videofeed
# iOS
cd ios && RCT_NEW_ARCH_ENABLED=0 pod install
```

Ensure `android/gradle.properties` has `newArchEnabled=false`.

For a full runnable example, clone the repo and open **`VideoFeedSample/`**
(linked to the library via `file:../rn-videofeed`).

## Usage

```tsx
import React, { useEffect, useRef } from 'react'
import { View, StyleSheet, findNodeHandle } from 'react-native'
import VideoFeedView, { VideoFeedManagerNative, VideoFeedEmitter } from 'rn-videofeed'

const VIDEOS = [
  { id: '1', videoUrl: 'https://.../clip.mp4', thumbnailUrl: 'https://.../clip.jpg' },
]

export default function Feed() {
  const feedRef = useRef(null)

  useEffect(() => {
    const sub = VideoFeedEmitter.addListener('onVideoChange', e => console.log(e?.videoId))
    return () => sub.remove()
  }, [])

  useEffect(() => {
    const handle = findNodeHandle(feedRef.current)
    if (handle != null) VideoFeedManagerNative.setVideos(handle, VIDEOS)
  }, [])

  return (
    <View style={{ flex: 1, backgroundColor: 'black' }}>
      <VideoFeedView ref={feedRef} style={StyleSheet.absoluteFill} />
    </View>
  )
}
```

## API

Drive the native view imperatively via `VideoFeedManagerNative` using `findNodeHandle(ref.current)`:

| Method | Description |
|--------|-------------|
| `setVideos(reactTag, videos)` | Replace the feed contents |
| `appendVideos(reactTag, videos)` | Append more videos (pagination) |
| `setFeedActive(reactTag, isActive)` | Pause/resume the whole feed |
| `pauseVideo(reactTag)` / `playVideo(reactTag)` | Control the current video |
| `togglePlayPause(reactTag)` | Toggle current video |
| `isVideoPlaying(reactTag)` | Query playing state |

Video item shape:

```ts
type FeedPlayerNativeProps = {
  id?: string
  videoUrl?: string
  thumbnailUrl?: string
  viewCount?: number
}
```

Events (`VideoFeedEmitter` / `DeviceEventEmitter`): `onVideoChange` `{ videoId }`,
`onVideoTapped` `{ isPlaying }`, `onEndReached`.

## License

MIT © Venkatesh Mandapati

Full docs, the sample app, and source: https://github.com/venky145/RN-VideoFeed
