import { requireNativeComponent } from 'react-native'

import type { LayoutChangeEvent, ViewStyle } from 'react-native'

export type FeedPlayerNativeProps = {
  id?: string
  videoUrl?: string
  thumbnailUrl?: string
  createdAt?: boolean
  viewCount?: number
  style?: ViewStyle
  onLayout?: (event: LayoutChangeEvent) => void
}

const VideoFeedView = requireNativeComponent<FeedPlayerNativeProps>('VideoFeedView')

export default VideoFeedView
