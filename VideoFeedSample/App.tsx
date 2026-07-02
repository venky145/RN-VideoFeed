/**
 * RN-VideoFeed sample — uses the local `rn-videofeed` package (../rn-videofeed).
 */

import React, { useEffect, useRef } from 'react'
import {
  findNodeHandle,
  StyleSheet,
  Text,
  View,
  useWindowDimensions,
  DeviceEventEmitter,
} from 'react-native'
import VideoFeedView, { VideoFeedManagerNative, VideoFeedEmitter } from 'rn-videofeed'

const SAMPLE_VIDEOS = [
  {
    id: '1',
    videoUrl:
      'https://storage.googleapis.com/exoplayer-test-media-0/BigBuckBunny_320x180.mp4',
    thumbnailUrl:
      'https://storage.googleapis.com/exoplayer-test-media-0/BigBuckBunny_320x180.jpeg',
    viewCount: 1200,
  },
  {
    id: '2',
    videoUrl:
      'https://storage.googleapis.com/exoplayer-test-media-1/mp4/android-screens-10s.mp4',
    thumbnailUrl: '',
    viewCount: 500,
  },
]

function App(): React.JSX.Element {
  const { width, height } = useWindowDimensions()
  const feedRef = useRef<unknown>(null)

  useEffect(() => {
    const sub = VideoFeedEmitter.addListener('onVideoChange', (e: { videoId?: string }) => {
      console.log('onVideoChange', e?.videoId)
    })
    const end = DeviceEventEmitter.addListener('onEndReached', () => {
      console.log('onEndReached')
    })
    return () => {
      sub.remove()
      end.remove()
    }
  }, [])

  useEffect(() => {
    let cancelled = false
    let retryTimeout: ReturnType<typeof setTimeout> | null = null

    const loadVideos = () => {
      if (cancelled) return
      const handle = feedRef.current != null
        ? findNodeHandle(feedRef.current as Parameters<typeof findNodeHandle>[0])
        : null
      if (handle != null) {
        VideoFeedManagerNative.setVideos(handle, SAMPLE_VIDEOS)
      } else {
        retryTimeout = setTimeout(loadVideos, 100)
      }
    }

    retryTimeout = setTimeout(loadVideos, 300)
    return () => {
      cancelled = true
      if (retryTimeout != null) clearTimeout(retryTimeout)
    }
  }, [width, height])

  return (
    <View style={styles.root}>
      <VideoFeedView ref={feedRef} style={styles.feed} />
      <View style={styles.badge} pointerEvents="none">
        <Text style={styles.badgeText}>RN-VideoFeed sample</Text>
      </View>
    </View>
  )
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: 'black' },
  feed: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
  },
  badge: {
    position: 'absolute',
    top: 56,
    left: 16,
    right: 16,
    padding: 8,
    backgroundColor: 'rgba(0,0,0,0.5)',
    borderRadius: 8,
  },
  badgeText: { color: 'white', fontSize: 12 },
})

export default App
