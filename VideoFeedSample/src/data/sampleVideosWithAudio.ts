/**
 * Audio-bearing demo feed for VideoFeedSample.
 *
 * Real footage (Pexels / W3C / MDN) with actual AAC audio — not test tones.
 * Only URLs that support Accept-Ranges (so AVPlayer can stream) and stay under
 * ~8MB so playback starts quickly on device.
 *
 * Note: free stock is usually landscape; Mixkit lifestyle set (sampleVideos.ts)
 * looks better but those files have no audio tracks.
 */

import type {SampleVideo} from './sampleVideos';

export const SAMPLE_VIDEOS_WITH_AUDIO: SampleVideo[] = [
  {
    id: 'pexels-3045163',
    videoUrl:
      'https://videos.pexels.com/video-files/3045163/3045163-sd_640_360_25fps.mp4',
    thumbnailUrl:
      'https://images.pexels.com/videos/3045163/pictures/preview-0.jpg',
    viewCount: 18400,
  },
  {
    id: 'pexels-3571264',
    videoUrl:
      'https://videos.pexels.com/video-files/3571264/3571264-sd_640_360_30fps.mp4',
    thumbnailUrl:
      'https://images.pexels.com/videos/3571264/pictures/preview-0.jpg',
    viewCount: 9200,
  },
  {
    id: 'pexels-2169880',
    videoUrl:
      'https://videos.pexels.com/video-files/2169880/2169880-sd_640_360_30fps.mp4',
    thumbnailUrl:
      'https://images.pexels.com/videos/2169880/pictures/preview-0.jpg',
    viewCount: 45100,
  },
  {
    id: 'pexels-2098989',
    videoUrl:
      'https://videos.pexels.com/video-files/2098989/2098989-sd_640_360_30fps.mp4',
    thumbnailUrl:
      'https://images.pexels.com/videos/2098989/pictures/preview-0.jpg',
    viewCount: 6700,
  },
  {
    id: 'pexels-6498490',
    videoUrl:
      'https://videos.pexels.com/video-files/6498490/6498490-sd_640_360_24fps.mp4',
    thumbnailUrl:
      'https://images.pexels.com/videos/6498490/pictures/preview-0.jpg',
    viewCount: 31200,
  },
  {
    id: 'pexels-5377684',
    videoUrl:
      'https://videos.pexels.com/video-files/5377684/5377684-sd_640_360_25fps.mp4',
    thumbnailUrl:
      'https://images.pexels.com/videos/5377684/pictures/preview-0.jpg',
    viewCount: 15800,
  },
  {
    id: 'pexels-5585939',
    videoUrl:
      'https://videos.pexels.com/video-files/5585939/5585939-sd_640_360_25fps.mp4',
    thumbnailUrl:
      'https://images.pexels.com/videos/5585939/pictures/preview-0.jpg',
    viewCount: 5400,
  },
  {
    id: 'pexels-8327402',
    videoUrl:
      'https://videos.pexels.com/video-files/8327402/8327402-sd_640_360_30fps.mp4',
    thumbnailUrl:
      'https://images.pexels.com/videos/3045163/pictures/preview-0.jpg',
    viewCount: 22100,
  },
  {
    id: 'w3-bbb',
    videoUrl: 'https://www.w3schools.com/html/mov_bbb.mp4',
    thumbnailUrl:
      'https://images.pexels.com/videos/3571264/pictures/preview-0.jpg',
    viewCount: 8900,
  },
  {
    id: 'w3-bear',
    videoUrl: 'https://www.w3schools.com/html/movie.mp4',
    thumbnailUrl:
      'https://images.pexels.com/videos/2169880/pictures/preview-0.jpg',
    viewCount: 27600,
  },
  {
    id: 'mdn-flower',
    videoUrl:
      'https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4',
    thumbnailUrl:
      'https://images.pexels.com/videos/2098989/pictures/preview-0.jpg',
    viewCount: 13400,
  },
  {
    id: 'w3c-movie-300',
    videoUrl: 'https://media.w3.org/2010/05/video/movie_300.mp4',
    thumbnailUrl:
      'https://images.pexels.com/videos/5377684/pictures/preview-0.jpg',
    viewCount: 40200,
  },
  {
    id: 'pexels-3045163-b',
    videoUrl:
      'https://videos.pexels.com/video-files/3045163/3045163-sd_640_360_25fps.mp4',
    thumbnailUrl:
      'https://images.pexels.com/videos/3045163/pictures/preview-0.jpg',
    viewCount: 7100,
  },
  {
    id: 'pexels-3571264-b',
    videoUrl:
      'https://videos.pexels.com/video-files/3571264/3571264-sd_640_360_30fps.mp4',
    thumbnailUrl:
      'https://images.pexels.com/videos/3571264/pictures/preview-0.jpg',
    viewCount: 19800,
  },
  {
    id: 'pexels-5585939-b',
    videoUrl:
      'https://videos.pexels.com/video-files/5585939/5585939-sd_640_360_25fps.mp4',
    thumbnailUrl:
      'https://images.pexels.com/videos/5585939/pictures/preview-0.jpg',
    viewCount: 5600,
  },
];
