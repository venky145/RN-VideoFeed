//
//  FeedPlayer.swift
//  App
//
//  Created by Venkatesh Mandapati on 15/05/2025.
//

import AVFoundation
import Foundation

class FeedPlayer: UIView {
  private(set) var player: AVPlayer?
  private var playerLayer: AVPlayerLayer?
  var onVideoStartedPlaying: (() -> Void)?

  private var timeControlStatusObserver: NSKeyValueObservation?
  private var statusObservedItem: AVPlayerItem?
  private var endTimeObserver: NSObjectProtocol?

  private(set) var videoId: String = ""
  private(set) var videoUrl: String?

  @objc var isVisible: Bool = false {
    didSet {
      if isVisible {
        player?.play()
      } else {
        player?.pause()
      }
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func bindFromPool(_ pool: VideoFeedPlayerPool, id: String, url: String) {
    if videoId == id, player != nil, pool.hasPlayer(videoId: id, videoUrl: url) {
      return
    }

    detachPlayer()

    videoId = id
    videoUrl = url
    attachPlayer(pool.acquire(videoId: id, videoUrl: url))
  }

  func hasPlaybackPosition() -> Bool {
    guard let player = player else { return false }
    let seconds = player.currentTime().seconds
    return seconds.isFinite && seconds > 0.3
  }

  private func attachPlayer(_ avPlayer: AVPlayer) {
    tearDownObservers()

    player = avPlayer
    player?.isMuted = false

    playerLayer = AVPlayerLayer(player: avPlayer)
    playerLayer?.frame = bounds
    playerLayer?.videoGravity = .resizeAspect
    if let playerLayer = playerLayer {
      layer.addSublayer(playerLayer)
    }

    if let item = avPlayer.currentItem {
      item.addObserver(self, forKeyPath: "status", options: [.new], context: nil)
      statusObservedItem = item

      endTimeObserver = NotificationCenter.default.addObserver(
        forName: .AVPlayerItemDidPlayToEndTime,
        object: item,
        queue: .main
      ) { [weak avPlayer] _ in
        avPlayer?.seek(to: .zero)
        avPlayer?.play()
      }
    }

    timeControlStatusObserver = avPlayer.observe(\.timeControlStatus, options: [.new]) {
      [weak self] player, _ in
      if player.timeControlStatus == .playing {
        DispatchQueue.main.async {
          self?.onVideoStartedPlaying?()
        }
      }
    }

    if avPlayer.currentItem?.status == .readyToPlay {
      if isVisible {
        avPlayer.play()
      }
      if avPlayer.timeControlStatus == .playing {
        onVideoStartedPlaying?()
      }
    } else if isVisible {
      avPlayer.play()
    }
  }

  /// Detach from the view without releasing the pooled AVPlayer instance.
  func detachPlayer() {
    player?.pause()
    tearDownObservers()
    playerLayer?.removeFromSuperlayer()
    playerLayer = nil
    player = nil
  }

  func reset() {
    detachPlayer()
    videoId = ""
    videoUrl = nil
    onVideoStartedPlaying = nil
    isVisible = false
  }

  private func tearDownObservers() {
    timeControlStatusObserver?.invalidate()
    timeControlStatusObserver = nil

    if let endTimeObserver = endTimeObserver {
      NotificationCenter.default.removeObserver(endTimeObserver)
      self.endTimeObserver = nil
    }

    if let statusObservedItem = statusObservedItem {
      statusObservedItem.removeObserver(self, forKeyPath: "status")
      self.statusObservedItem = nil
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    playerLayer?.frame = bounds
  }

  override func observeValue(
    forKeyPath keyPath: String?,
    of object: Any?,
    change: [NSKeyValueChangeKey: Any]?,
    context: UnsafeMutableRawPointer?
  ) {
    guard keyPath == "status", let item = object as? AVPlayerItem else { return }

    switch item.status {
    case .readyToPlay:
      if isVisible {
        player?.play()
      }
      if player?.timeControlStatus == .playing {
        onVideoStartedPlaying?()
      }
    case .failed:
      if let error = item.error {
        print("❌ FeedPlayer - Player item failed: \(error.localizedDescription)")
      }
    case .unknown:
      break
    @unknown default:
      break
    }
  }

  deinit {
    detachPlayer()
  }
}
