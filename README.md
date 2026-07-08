# RN-VideoFeed

[![CI](https://github.com/venky145/RN-VideoFeed/actions/workflows/ci.yml/badge.svg)](https://github.com/venky145/RN-VideoFeed/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

A native, vertical full-screen video feed for React Native — Reels / TikTok / Shorts style.
Playback is powered by **AVPlayer** on iOS and **Media3 ExoPlayer** on Android, driven by a
native `UICollectionView` / `RecyclerView` so scrolling stays smooth even with many videos.

## Features

- Full-page vertical paging feed (snap-to-page)
- Seamless resume — scrolling back continues **where you left off** instead of restarting
- Warm player pool (keeps ~8 videos ready) for instant playback on both platforms
- Thumbnail + loading spinner until the video is ready; position label on each cell
- Tap to play/pause, auto-pause on scroll and when the app backgrounds
- Pagination hook (`onEndReached`) and per-video change events

## Repository layout

| Path | Description |
|------|-------------|
| `rn-videofeed/` | The library — iOS (Swift/ObjC), Android (Kotlin), and the JS/TS API |
| `VideoFeedSample/` | **The** sample app (RN 0.77) — links the library via `file:../rn-videofeed` |

There is only one sample in this repo so setup stays obvious. Real apps should install
from npm (`npm install rn-videofeed`) and use the same API as `VideoFeedSample`.

## Requirements

- React Native >= 0.76
- iOS 16.0+
- Android — **Old Architecture** (`newArchEnabled=false`); the component is a legacy `SimpleViewManager`
- iOS — prefer Old Architecture for this view (`RCT_NEW_ARCH_ENABLED=0` when running `pod install`)

## Installation

```bash
npm install rn-videofeed
```

Then:

```bash
# iOS
cd ios && RCT_NEW_ARCH_ENABLED=0 pod install

# Android — ensure Old Architecture in android/gradle.properties
# newArchEnabled=false
```

You can also pin from GitHub if needed:

```json
{
  "dependencies": {
    "rn-videofeed": "github:venky145/RN-VideoFeed#main"
  }
}
```

## Usage

```tsx
import React, { useEffect, useRef } from 'react'
import { View, StyleSheet, findNodeHandle } from 'react-native'
import VideoFeedView, { VideoFeedManagerNative, VideoFeedEmitter } from 'rn-videofeed'

const VIDEOS = [
  {
    id: '1',
    videoUrl: 'https://.../BigBuckBunny_320x180.mp4',
    thumbnailUrl: 'https://.../BigBuckBunny_320x180.jpeg',
    viewCount: 1200,
  },
]

export default function Feed() {
  const feedRef = useRef(null)

  useEffect(() => {
    const sub = VideoFeedEmitter.addListener('onVideoChange', e => {
      console.log('now playing', e?.videoId)
    })
    return () => sub.remove()
  }, [])

  useEffect(() => {
    const handle = findNodeHandle(feedRef.current)
    if (handle != null) {
      VideoFeedManagerNative.setVideos(handle, VIDEOS)
    }
  }, [])

  return (
    <View style={styles.root}>
      <VideoFeedView ref={feedRef} style={StyleSheet.absoluteFill} />
    </View>
  )
}

const styles = StyleSheet.create({ root: { flex: 1, backgroundColor: 'black' } })
```

## API

### `<VideoFeedView />`

A native view. Give it a ref and drive it imperatively through `VideoFeedManagerNative`
using the view's node handle (`findNodeHandle(ref.current)`).

### `VideoFeedManagerNative`

| Method | Description |
|--------|-------------|
| `setVideos(reactTag, videos)` | Replace the feed contents |
| `appendVideos(reactTag, videos)` | Append more videos (pagination) |
| `setFeedActive(reactTag, isActive)` | Pause/resume the whole feed |
| `pauseVideo(reactTag)` / `playVideo(reactTag)` | Control the current video |
| `togglePlayPause(reactTag)` | Toggle current video |
| `isVideoPlaying(reactTag)` | Query playing state |

### Video item shape

```ts
type FeedPlayerNativeProps = {
  id?: string
  videoUrl?: string
  thumbnailUrl?: string
  viewCount?: number
}
```

### Events (`VideoFeedEmitter` / `DeviceEventEmitter`)

| Event | Payload | Fired when |
|-------|---------|-----------|
| `onVideoChange` | `{ videoId }` | The visible video changes |
| `onVideoTapped` | `{ isPlaying }` | User taps the video |
| `onEndReached` | — | Near the end of the feed (load more) |

## Running the sample

`VideoFeedSample` is the only demo app. It uses the local library so you can change
native / JS code and see it immediately.

```bash
cd VideoFeedSample
npm install
cd ios && RCT_NEW_ARCH_ENABLED=0 pod install && cd ..

npm start                 # Metro
npm run ios               # iOS
npm run android           # Android  (newArchEnabled=false)
```

## License

MIT © Venkatesh Mandapati — see [LICENSE](./LICENSE).
