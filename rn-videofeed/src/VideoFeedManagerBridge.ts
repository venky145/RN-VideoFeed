import { NativeEventEmitter, NativeModules } from 'react-native'

import type { FeedPlayerNativeProps } from './VideoFeedView.native'
import type { NativeModule } from 'react-native'

interface VideoFeedManager extends NativeModule {
  setVideos: (reactTag: number, videos: FeedPlayerNativeProps[]) => void
  appendVideos: (reactTag: number, videos: FeedPlayerNativeProps[]) => void
  setFeedActive: (reactTag: number, isActive: boolean) => void
  addEventListener: (eventName: string) => void
  removeEventListener: (eventName: string) => void
  pauseVideo: (reactTag: number) => void
  playVideo: (reactTag: number) => void
  togglePlayPause: (reactTag: number) => void
  isVideoPlaying: (reactTag: number) => void
}

const VideoFeedManagerNative = NativeModules.VideoFeedViewManager as VideoFeedManager

const VideoFeedEventEmitterNative = (NativeModules.VideoFeedEventEmitter ||
  VideoFeedManagerNative) as VideoFeedManager
const VideoFeedEmitter = new NativeEventEmitter(VideoFeedEventEmitterNative)

export { VideoFeedManagerNative, VideoFeedEmitter, type VideoFeedManager }
