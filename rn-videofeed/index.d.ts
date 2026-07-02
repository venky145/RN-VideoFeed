import type { ComponentType, RefAttributes } from 'react'
import type { LayoutChangeEvent, NativeEventEmitter, NativeModule, ViewStyle } from 'react-native'

export type FeedPlayerNativeProps = {
  id?: string
  videoUrl?: string
  thumbnailUrl?: string
  createdAt?: boolean
  viewCount?: number
  style?: ViewStyle
  onLayout?: (event: LayoutChangeEvent) => void
}

export declare const VideoFeedView: ComponentType<FeedPlayerNativeProps & RefAttributes<unknown>>
export default VideoFeedView

export interface VideoFeedManager extends NativeModule {
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

export declare const VideoFeedManagerNative: VideoFeedManager
export declare const VideoFeedEmitter: NativeEventEmitter
