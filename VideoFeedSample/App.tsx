/**
 * RN-VideoFeed sample — uses the local `rn-videofeed` package (`file:../rn-videofeed`).
 * For a real app, install from npm: `npm install rn-videofeed` (same API).
 */

import React, {useEffect, useRef, useState} from 'react';
import {
  ActivityIndicator,
  AppState,
  DeviceEventEmitter,
  findNodeHandle,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import VideoFeedView, {
  VideoFeedManagerNative,
  VideoFeedEmitter,
} from 'rn-videofeed';
import {PAGE_SIZE, SAMPLE_VIDEOS as SAMPLE_VIDEOS_SILENT} from './src/data/sampleVideos';
import {SAMPLE_VIDEOS_WITH_AUDIO} from './src/data/sampleVideosWithAudio';

/**
 * Flip this to switch demo feeds:
 * - false → Mixkit lifestyle clips (look great, no audio tracks)
 * - true  → Real footage (Pexels/W3C) with ambient audio, streamable MP4s
 */
const USE_AUDIO_FEED = false;

const SAMPLE_VIDEOS = USE_AUDIO_FEED
  ? SAMPLE_VIDEOS_WITH_AUDIO
  : SAMPLE_VIDEOS_SILENT;

type LoadState = 'loading' | 'ready' | 'error' | 'empty';

function formatViews(count: number): string {
  if (count >= 1_000_000) {
    return `${(count / 1_000_000).toFixed(1)}M`;
  }
  if (count >= 1_000) {
    return `${(count / 1_000).toFixed(count >= 10_000 ? 0 : 1)}K`;
  }
  return String(count);
}

function App(): React.JSX.Element {
  const feedRef = useRef<unknown>(null);
  const loadedCountRef = useRef(0);
  const appendingRef = useRef(false);
  const initialPushedRef = useRef(false);

  const [loadState, setLoadState] = useState<LoadState>(
    SAMPLE_VIDEOS.length === 0 ? 'empty' : 'loading',
  );
  const [loadedCount, setLoadedCount] = useState(0);
  const [currentIndex, setCurrentIndex] = useState(0);

  const getHandle = (): number | null => {
    if (feedRef.current == null) {
      return null;
    }
    return findNodeHandle(
      feedRef.current as Parameters<typeof findNodeHandle>[0],
    );
  };

  const pushInitialPage = (): boolean => {
    if (SAMPLE_VIDEOS.length === 0) {
      setLoadState('empty');
      return true;
    }
    const handle = getHandle();
    if (handle == null) {
      return false;
    }
    const firstPage = SAMPLE_VIDEOS.slice(0, PAGE_SIZE);
    try {
      VideoFeedManagerNative.setVideos(handle, firstPage);
      VideoFeedManagerNative.setFeedActive(handle, true);
      loadedCountRef.current = firstPage.length;
      initialPushedRef.current = true;
      setLoadedCount(firstPage.length);
      setCurrentIndex(0);
      setLoadState('ready');
      return true;
    } catch (e) {
      console.warn('Failed to setVideos', e);
      setLoadState('error');
      return true;
    }
  };

  useEffect(() => {
    const appendNextPage = () => {
      if (appendingRef.current) {
        return;
      }
      const already = loadedCountRef.current;
      if (already >= SAMPLE_VIDEOS.length) {
        return;
      }
      const handle = getHandle();
      if (handle == null) {
        return;
      }
      const nextPage = SAMPLE_VIDEOS.slice(already, already + PAGE_SIZE);
      if (nextPage.length === 0) {
        return;
      }
      appendingRef.current = true;
      try {
        VideoFeedManagerNative.appendVideos(handle, nextPage);
        loadedCountRef.current = already + nextPage.length;
        setLoadedCount(already + nextPage.length);
      } catch (e) {
        console.warn('Failed to appendVideos', e);
      }
      setTimeout(() => {
        appendingRef.current = false;
      }, 400);
    };

    const sub = VideoFeedEmitter.addListener(
      'onVideoChange',
      (e: {videoId?: string}) => {
        const id = e?.videoId ?? '';
        const idx = SAMPLE_VIDEOS.findIndex(v => v.id === id);
        if (idx >= 0) {
          setCurrentIndex(idx);
        }
      },
    );
    const end = DeviceEventEmitter.addListener('onEndReached', appendNextPage);
    return () => {
      sub.remove();
      end.remove();
    };
  }, []);

  useEffect(() => {
    if (SAMPLE_VIDEOS.length === 0) {
      setLoadState('empty');
      return;
    }

    let cancelled = false;
    let retryTimeout: ReturnType<typeof setTimeout> | null = null;
    let attempts = 0;
    const maxAttempts = 60;

    const loadVideos = () => {
      if (cancelled || initialPushedRef.current) {
        return;
      }
      if (pushInitialPage()) {
        return;
      }
      attempts += 1;
      if (attempts >= maxAttempts) {
        setLoadState('error');
        return;
      }
      retryTimeout = setTimeout(loadVideos, 100);
    };

    setLoadState('loading');
    retryTimeout = setTimeout(loadVideos, 200);

    const appStateSub = AppState.addEventListener('change', state => {
      if (state === 'active' && !initialPushedRef.current) {
        pushInitialPage();
      } else if (state === 'active') {
        const handle = getHandle();
        if (handle != null) {
          VideoFeedManagerNative.setFeedActive(handle, true);
        }
      }
    });

    return () => {
      cancelled = true;
      appStateSub.remove();
      if (retryTimeout != null) {
        clearTimeout(retryTimeout);
      }
    };
  }, []);

  const current = SAMPLE_VIDEOS[currentIndex];

  return (
    <View style={styles.root}>
      <VideoFeedView
        ref={feedRef}
        style={styles.feed}
        {...({collapsable: false} as object)}
        onLayout={e => {
          const {height} = e.nativeEvent.layout;
          if (height > 1 && !initialPushedRef.current) {
            pushInitialPage();
          }
        }}
      />

      {loadState === 'ready' && (
        <View style={styles.badge} pointerEvents="none">
          <Text style={styles.badgeText}>
            RN-VideoFeed sample
            {USE_AUDIO_FEED ? ' · audio feed' : ' · silent Mixkit'}
          </Text>
          <Text style={styles.positionText}>
            {currentIndex + 1} / {SAMPLE_VIDEOS.length} ·{' '}
            {formatViews(current?.viewCount ?? 0)} views
          </Text>
          <Text style={styles.hintText}>
            Swipe up / down · loaded {loadedCount}/{SAMPLE_VIDEOS.length}
          </Text>
        </View>
      )}

      {loadState === 'loading' && (
        <View style={styles.overlay} pointerEvents="none">
          <ActivityIndicator size="large" color="#FFFFFF" />
          <Text style={styles.overlayTitle}>Loading feed…</Text>
        </View>
      )}

      {loadState === 'error' && (
        <View style={styles.overlay} pointerEvents="none">
          <Text style={styles.overlayTitle}>Couldn’t start the video feed</Text>
          <Text style={styles.overlayBody}>
            Allow Local Network for this app, keep Metro running on your Mac,
            then rebuild.
          </Text>
        </View>
      )}

      {loadState === 'empty' && (
        <View style={styles.overlay} pointerEvents="none">
          <Text style={styles.overlayTitle}>No demo videos</Text>
          <Text style={styles.overlayBody}>
            Add entries to src/data/sampleVideos.ts to populate the feed.
          </Text>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  root: {flex: 1, backgroundColor: 'black'},
  feed: {
    ...StyleSheet.absoluteFillObject,
  },
  badge: {
    position: 'absolute',
    top: 56,
    left: 16,
    right: 16,
    padding: 12,
    backgroundColor: 'rgba(0,0,0,0.65)',
    borderRadius: 10,
    zIndex: 10,
  },
  badgeText: {color: '#A0A0A0', fontSize: 11, marginBottom: 4},
  positionText: {color: 'white', fontSize: 18, fontWeight: '700'},
  hintText: {color: '#C0C0C0', fontSize: 12, marginTop: 6},
  overlay: {
    ...StyleSheet.absoluteFillObject,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'rgba(0,0,0,0.72)',
    paddingHorizontal: 32,
  },
  overlayTitle: {
    color: 'white',
    fontSize: 18,
    fontWeight: '700',
    marginTop: 16,
    textAlign: 'center',
  },
  overlayBody: {
    color: '#C0C0C0',
    fontSize: 14,
    marginTop: 8,
    textAlign: 'center',
    lineHeight: 20,
  },
});

export default App;
