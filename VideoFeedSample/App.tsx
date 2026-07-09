/**
 * RN-VideoFeed sample — uses the local `rn-videofeed` package (`file:../rn-videofeed`).
 * For a real app, install from npm: `npm install rn-videofeed` (same API).
 */

import React, {useEffect, useRef, useState} from 'react';
import {
  AppState,
  findNodeHandle,
  Platform,
  StyleSheet,
  Text,
  View,
  useWindowDimensions,
  DeviceEventEmitter,
} from 'react-native';
import VideoFeedView, {
  VideoFeedManagerNative,
  VideoFeedEmitter,
} from 'rn-videofeed';

const IOS_HLS_VIDEOS = [
  {
    id: 'bipbop-1',
    title: 'Apple HLS (gear1)',
    videoUrl:
      'https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/gear1/prog_index.m3u8',
    thumbnailUrl: '',
    viewCount: 1200,
  },
  {
    id: 'bipbop-2',
    title: 'Apple HLS (gear2)',
    videoUrl:
      'https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/gear2/prog_index.m3u8',
    thumbnailUrl: '',
    viewCount: 500,
  },
  {
    id: 'bipbop-3',
    title: 'Apple HLS (gear3)',
    videoUrl:
      'https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/gear3/prog_index.m3u8',
    thumbnailUrl: '',
    viewCount: 900,
  },
];

// Android build currently only bundles the core ExoPlayer module. HLS playback
// requires adding the Media3 HLS extension; until then, use MP4 sources on
// Android so the sample runs out-of-the-box.
const ANDROID_MP4_VIDEOS = [
  {
    id: 'bunny',
    title: 'Big Buck Bunny',
    videoUrl:
      'https://storage.googleapis.com/exoplayer-test-media-0/BigBuckBunny_320x180.mp4',
    thumbnailUrl:
      'https://storage.googleapis.com/exoplayer-test-media-0/BigBuckBunny_320x180.jpeg',
    viewCount: 1200,
  },
  {
    id: 'screens',
    title: 'Android Screens',
    videoUrl:
      'https://storage.googleapis.com/exoplayer-test-media-1/mp4/android-screens-10s.mp4',
    thumbnailUrl:
      'https://storage.googleapis.com/exoplayer-test-media-0/BigBuckBunny_320x180.jpeg',
    viewCount: 500,
  },
  {
    id: 'bars',
    title: 'Color Bars',
    videoUrl:
      'https://storage.googleapis.com/exoplayer-test-media-1/gen-3/screens/dash-vod-single-segment/video-avc-baseline-480.mp4',
    thumbnailUrl:
      'https://storage.googleapis.com/exoplayer-test-media-0/BigBuckBunny_320x180.jpeg',
    viewCount: 900,
  },
];

const SAMPLE_VIDEOS = Platform.OS === 'android' ? ANDROID_MP4_VIDEOS : IOS_HLS_VIDEOS;

function App(): React.JSX.Element {
  const {width, height} = useWindowDimensions();
  const feedRef = useRef<unknown>(null);
  const [currentId, setCurrentId] = useState('bunny');
  const [currentIndex, setCurrentIndex] = useState(0);

  useEffect(() => {
    const sub = VideoFeedEmitter.addListener(
      'onVideoChange',
      (e: {videoId?: string}) => {
        const id = e?.videoId ?? '';
        const idx = SAMPLE_VIDEOS.findIndex(v => v.id === id);
        if (idx >= 0) {
          setCurrentId(id);
          setCurrentIndex(idx);
        }
        console.log('onVideoChange', id);
      },
    );
    const end = DeviceEventEmitter.addListener('onEndReached', () => {
      console.log('onEndReached');
    });
    return () => {
      sub.remove();
      end.remove();
    };
  }, []);

  useEffect(() => {
    let cancelled = false;
    let retryTimeout: ReturnType<typeof setTimeout> | null = null;

    const pushVideos = () => {
      if (cancelled) {
        return false;
      }
      const handle =
        feedRef.current != null
          ? findNodeHandle(
              feedRef.current as Parameters<typeof findNodeHandle>[0],
            )
          : null;
      if (handle != null) {
        VideoFeedManagerNative.setVideos(handle, SAMPLE_VIDEOS);
        VideoFeedManagerNative.setFeedActive(handle, true);
        return true;
      }
      return false;
    };

    const loadVideos = () => {
      if (!pushVideos()) {
        retryTimeout = setTimeout(loadVideos, 100);
      }
    };

    retryTimeout = setTimeout(loadVideos, 500);

    const appStateSub = AppState.addEventListener('change', state => {
      if (state === 'active') {
        pushVideos();
      }
    });

    return () => {
      cancelled = true;
      appStateSub.remove();
      if (retryTimeout != null) {
        clearTimeout(retryTimeout);
      }
    };
  }, [width, height]);

  const current = SAMPLE_VIDEOS[currentIndex];

  return (
    <View style={styles.root}>
      <VideoFeedView ref={feedRef} style={styles.feed} />
      <View style={styles.badge} pointerEvents="none">
        <Text style={styles.badgeText}>RN-VideoFeed sample</Text>
        <Text style={styles.positionText}>
          {currentIndex + 1} / {SAMPLE_VIDEOS.length} ·{' '}
          {current?.title ?? currentId}
        </Text>
        <Text style={styles.hintText}>
          Swipe up / down · spinner = buffering
        </Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {flex: 1, backgroundColor: 'black'},
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
    padding: 12,
    backgroundColor: 'rgba(0,0,0,0.65)',
    borderRadius: 10,
  },
  badgeText: {color: '#A0A0A0', fontSize: 11, marginBottom: 4},
  positionText: {color: 'white', fontSize: 18, fontWeight: '700'},
  hintText: {color: '#C0C0C0', fontSize: 12, marginTop: 6},
});

export default App;
