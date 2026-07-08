import AVFoundation
import Foundation

/// LRU pool of AVPlayer instances keyed by video id — keeps players warm so
/// scrolling back resumes where the user left off (Reels-style behaviour).
class VideoFeedPlayerPool {
  private struct PooledEntry {
    let player: AVPlayer
    var videoUrl: String
    var lastAccessTime: Date = Date()
  }

  private let maxSize: Int
  private var entries: [String: PooledEntry] = [:]
  private var order: [String] = []

  init(maxSize: Int = 8) {
    self.maxSize = maxSize
  }

  func acquire(videoId: String, videoUrl: String) -> AVPlayer {
    if let entry = entries[videoId], entry.videoUrl == videoUrl {
      touch(videoId)
      print("VideoFeedPlayerPool - Reusing pooled player for \(videoId)")
      return entry.player
    }

    if entries[videoId] != nil {
      removeEntry(videoId)
    }

    while order.count >= maxSize, let oldest = order.first {
      print("VideoFeedPlayerPool - Evicting oldest player: \(oldest)")
      removeEntry(oldest)
    }

    guard let url = URL(string: videoUrl) else {
      fatalError("Invalid video URL: \(videoUrl)")
    }

    let item = AVPlayerItem(url: url)
    let player = AVPlayer(playerItem: item)
    player.isMuted = false

    entries[videoId] = PooledEntry(player: player, videoUrl: videoUrl)
    order.append(videoId)
    print("VideoFeedPlayerPool - Created pooled player for \(videoId) (pool size=\(order.count))")
    return player
  }

  func pause(videoId: String) {
    entries[videoId]?.player.pause()
  }

  func hasPlayer(videoId: String, videoUrl: String) -> Bool {
    guard let entry = entries[videoId] else { return false }
    return entry.videoUrl == videoUrl
  }

  func getPlaybackPosition(videoId: String) -> TimeInterval {
    guard let player = entries[videoId]?.player else { return 0 }
    let seconds = player.currentTime().seconds
    return seconds.isFinite ? seconds : 0
  }

  func releaseAll() {
    print("VideoFeedPlayerPool - Releasing all \(order.count) pooled players")
    for key in order {
      entries[key]?.player.pause()
    }
    entries.removeAll()
    order.removeAll()
  }

  private func touch(_ videoId: String) {
    entries[videoId]?.lastAccessTime = Date()
    order.removeAll { $0 == videoId }
    order.append(videoId)
  }

  private func removeEntry(_ videoId: String) {
    entries.removeValue(forKey: videoId)?.player.pause()
    order.removeAll { $0 == videoId }
  }
}
