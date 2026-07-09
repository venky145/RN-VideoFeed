//
//  VideoFeedView.swift
//  App
//
//  Created by Venkatesh Mandapati on 15/05/2025.
//

import AVFoundation
import UIKit

class VideoFeedView: UIView {
  private var collectionView: UICollectionView!
  private var videos: [VideoData] = []
  private var currentPlayer: AVPlayer?
  private let playerPool = VideoFeedPlayerPool(maxSize: 8)
  private var preloadTasks: [String: AVAsset] = [:]
  private var feedIsActive = true
  private var shouldPlayFirstVideo = false
  private var isManuallyPaused = false // Track if user manually paused
  weak var eventEmitter: VideoFeedEventEmitter?

  var onEndReached: (() -> Void)?
  var onVideoChange: ((String) -> Void)?

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupAppLifecycleObservers()
    setupCollectionView()
    setupTapGesture()
  }

  //Not required, only for storyboard or xib included
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupAppLifecycleObservers() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(appDidEnterBackground),
      name: UIApplication.didEnterBackgroundNotification,
      object: nil
    )

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(appDidBecomeActive),
      name: UIApplication.didBecomeActiveNotification,
      object: nil
    )
  }

  @objc private func appDidEnterBackground() {
    currentPlayer?.pause()
  }

  @objc private func appDidBecomeActive() {
    if feedIsActive && !isManuallyPaused {
      currentPlayer?.play()
    } else if isManuallyPaused {
      print("App became active but video was manually paused — staying paused")
    }
  }

  private func setupCollectionView() {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .vertical
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    // Initial size - will be updated in layoutSubviews with correct bounds
    layout.itemSize = CGSize(
      width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)

    collectionView = UICollectionView(
      frame: .zero, collectionViewLayout: layout)
    collectionView.isPagingEnabled = true
    collectionView.showsVerticalScrollIndicator = false
    collectionView.backgroundColor = .black
    collectionView.contentInsetAdjustmentBehavior = .never // Prevent safe area adjustments
    collectionView.register(
      VideoFeedCell.self, forCellWithReuseIdentifier: "VideoFeedCell")
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.prefetchDataSource = self
    collectionView.isPrefetchingEnabled = true

    addSubview(collectionView)
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      collectionView.topAnchor.constraint(equalTo: topAnchor),
      collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
      collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
    ])

  }

  override func layoutSubviews() {
    super.layoutSubviews()

    if let layout = collectionView.collectionViewLayout
      as? UICollectionViewFlowLayout
    {
      let fullScreenSize = CGSize(width: bounds.width, height: bounds.height)
      if layout.itemSize != fullScreenSize {
        layout.itemSize = fullScreenSize
        layout.invalidateLayout()
      }
    }
  }

  override func willMove(toWindow newWindow: UIWindow?) {
    super.willMove(toWindow: newWindow)
    if newWindow == nil {
      playerPool.releaseAll()
    }
  }

  func setVideos(_ videos: [[String: Any]]) {
    self.videos = videos.compactMap { dict -> VideoData? in
      guard let id = dict["id"] as? String,
            let url = dict["videoUrl"] as? String
      else {
        print("Failed to map video data - missing id or url")
        return nil
      }
      let thumbnail = dict["thumbnailUrl"] as? String
      let viewCount: Int? = {
        if let count = dict["viewCount"] as? Int {
          return count
        }
        return nil
      }()
      return VideoData(
        id: id, videoUrl: url, thumbnailUrl: thumbnail, viewCount: viewCount)
    }
    collectionView.reloadData()
    preloadNextVideos()

    // willDisplay may not run for already-visible cells after reloadData (e.g. app relaunch).
    if !videos.isEmpty {
      shouldPlayFirstVideo = true
      DispatchQueue.main.async { [weak self] in
        guard let self = self, !self.videos.isEmpty else { return }
        self.shouldPlayFirstVideo = false
        self.playVideo(at: self.getCurrentIndex())
      }
    }
  }

  func appendVideos(_ videos: [[String: Any]]) {
    let newVideos = videos.compactMap { dict -> VideoData? in
      guard let id = dict["id"] as? String,
            let url = dict["videoUrl"] as? String
      else { return nil }
      let thumbnail = dict["thumbnailUrl"] as? String
      let duration: Int? = {
        if let duration = dict["viewCount"] as? Int {
          return duration
        }
        return nil
      }()
      return VideoData(
        id: id, videoUrl: url, thumbnailUrl: thumbnail, viewCount: duration)
    }

    let startIndex = self.videos.count
    self.videos.append(contentsOf: newVideos)

    // Insert new cells instead of reloading all
    let indexPaths = (startIndex..<self.videos.count).map {
      IndexPath(item: $0, section: 0)
    }
    collectionView.insertItems(at: indexPaths)
    preloadNextVideos()
  }

  func setFeedActive(_ isActive: Bool) {
    self.feedIsActive = isActive
    
    if isActive {
      // When becoming active, try to play the current video
      if !isManuallyPaused {
        if let player = currentPlayer {
          player.play()
          eventEmitter?.sendEvent(withName: "onPlayStateChanged", body: ["isPlaying": true])
        } else {
          let currentIndex = getCurrentIndex()
          if currentIndex >= 0 && currentIndex < videos.count {
            playVideo(at: currentIndex)
          }
        }
      } else {
        print("setFeedActive: Video was manually paused, not resuming")
      }
    } else {
      if let player = currentPlayer {
        player.pause()
      } else {
        print("setFeedActive: No current player to pause")
      }
    }
  }

  private func preloadNextVideos() {
    let visibleIndex = getCurrentIndex()
    let start = visibleIndex + 1
    let end = min(visibleIndex + 2, videos.count - 1)

    guard start <= end else { return }  // avoid invalid range

    let preloadRange = start...end
    for index in preloadRange {
      let video = videos[index]
      guard preloadTasks[video.videoUrl] == nil,
            let url = URL(string: video.videoUrl)
      else { continue }

      let asset = AVAsset(url: url)
      preloadTasks[video.videoUrl] = asset

      asset.loadValuesAsynchronously(forKeys: ["playable"]) { [weak self] in
        DispatchQueue.main.async {
          self?.preloadTasks[video.videoUrl] = nil
        }
      }
    }
  }

  private func getCurrentIndex() -> Int {
    let visibleRect = CGRect(
      x: collectionView.contentOffset.x,
      y: collectionView.contentOffset.y,
      width: collectionView.bounds.width,
      height: collectionView.bounds.height
    )
    let center = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
    if let indexPath = collectionView.indexPathForItem(at: center) {
      return indexPath.item
    }

    let height = collectionView.bounds.height
    guard height > 0 else { return 0 }
    let index = Int(round(collectionView.contentOffset.y / height))
    return max(0, min(videos.count - 1, index))
  }

  private func handleScrollEnd() {
    let index = getCurrentIndex()
    for cell in collectionView.visibleCells as! [VideoFeedCell] {
      cell.feedPlayer.isVisible = false
    }

    // Reset manual pause state for new video
    isManuallyPaused = false

    playVideo(at: index)

    if index < videos.count {
      let videoId = videos[index].id
      eventEmitter?.sendEvent("onVideoChange", body: ["videoId": videoId])
    }
  }

  private func playVideo(at index: Int) {
    print("Attempting to play video at index:", index)

    guard feedIsActive else {
      print("Feed inactive, skipping playVideo at index:", index)
      return
    }

    guard index >= 0, index < videos.count else {
      print("Index out of bounds:", index)
      return
    }

    currentPlayer?.pause()

    if let cell = collectionView.cellForItem(
      at: IndexPath(item: index, section: 0)) as? VideoFeedCell
    {
      setupVideoForPlayback(cell, at: index)
    } else {
      print("No cell found for index: \(index), scheduling retry...")
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
        self?.playVideoWithRetry(at: index, retriesLeft: 8)
      }
    }
  }

  private func playVideoWithRetry(at index: Int, retriesLeft: Int) {
    guard feedIsActive, index >= 0, index < videos.count else {
      return
    }

    if let cell = collectionView.cellForItem(
      at: IndexPath(item: index, section: 0)) as? VideoFeedCell
    {
      print("Found cell for index \(index) after retry")
      setupVideoForPlayback(cell, at: index)
    } else if retriesLeft > 0 {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
        self?.playVideoWithRetry(at: index, retriesLeft: retriesLeft - 1)
      }
    } else {
      print("❌ Failed to find cell for index \(index) after retries")
    }
  }

  private func setupVideoForPlayback(_ cell: VideoFeedCell, at index: Int) {
    let video = videos[index]
    print("Found cell for index:", index)

    if cell.feedPlayer.videoId != video.id || cell.feedPlayer.player == nil {
      cell.configure(
        with: video,
        playerPool: playerPool,
        index: index,
        total: videos.count
      )
    }

    cell.feedPlayer.onVideoStartedPlaying = { [weak cell] in
      cell?.showVideoPlaying()
    }

    let resuming = playerPool.hasPlayer(videoId: video.id, videoUrl: video.videoUrl)
      && (playerPool.getPlaybackPosition(videoId: video.id) > 0.3
        || cell.feedPlayer.hasPlaybackPosition())

    if resuming {
      cell.hideThumbnailImmediately()
    } else {
      cell.showThumbnail()
    }

    currentPlayer = cell.feedPlayer.player
    currentPlayer?.isMuted = false

    if !isManuallyPaused {
      cell.feedPlayer.isVisible = true
      currentPlayer?.play()
      syncPlaybackUI(for: cell)
      print("▶️ Auto-playing new video at index: \(index)")
    } else {
      cell.feedPlayer.isVisible = false
      print("⏸️ New video at index: \(index) but staying paused (manually paused)")
    }

    onVideoChange?(video.id)
  }

  private func syncPlaybackUI(for cell: VideoFeedCell) {
    guard let player = cell.feedPlayer.player else { return }
    if player.timeControlStatus == .playing {
      cell.showVideoPlaying()
      return
    }
    if player.currentItem?.status == .readyToPlay {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak cell] in
        guard let cell = cell else { return }
        if cell.feedPlayer.player?.timeControlStatus == .playing {
          cell.showVideoPlaying()
        }
      }
    }
  }

  // MARK: - Tap Gesture Setup
  
  private func setupTapGesture() {
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
    tapGesture.numberOfTapsRequired = 1
    // Allow tap gesture to work alongside collection view gestures
    tapGesture.cancelsTouchesInView = false
    addGestureRecognizer(tapGesture)
    print("🔥 Tap gesture recognizer added to VideoFeedView")
  }
  
  @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
    print("🔥 Tap detected in native VideoFeedView")
    
    // Toggle play/pause and get the new state
    let isNowPlaying = togglePlayPause()
    
    // Emit event to React Native for UI feedback
    eventEmitter?.sendEvent("onVideoTapped", body: ["isPlaying": isNowPlaying])
  }

  // MARK: - Play/Pause Control Methods
  
  /// Gets the current visible index based on scroll position
  private func getCurrentVisibleIndex() -> Int? {
    let visibleIndexPaths = collectionView.indexPathsForVisibleItems
    guard let firstVisibleIndexPath = visibleIndexPaths.first else { return nil }
    return firstVisibleIndexPath.item
  }
  
  /// Gets the current visible cell
  private func getCurrentCell(at index: Int) -> VideoFeedCell? {
    let indexPath = IndexPath(item: index, section: 0)
    return collectionView.cellForItem(at: indexPath) as? VideoFeedCell
  }
  
  /// Pauses the currently playing video
  func pauseCurrentVideo() {
    guard let currentIndex = getCurrentVisibleIndex(),
          let cell = getCurrentCell(at: currentIndex) else {
      print("Failed to get current video for pause")
      return
    }
    
    isManuallyPaused = true
    cell.feedPlayer.isVisible = false
  }
  
  /// Plays the currently visible video
  func playCurrentVideo() {
    guard let currentIndex = getCurrentVisibleIndex(),
          let cell = getCurrentCell(at: currentIndex) else {
      print("Failed to get current video for play")
      return
    }
    
    isManuallyPaused = false
    cell.feedPlayer.isVisible = true
  }
  
  /// Toggles play/pause state of current video
  /// Returns the new playing state (true = playing, false = paused)
  func togglePlayPause() -> Bool {
    guard let currentIndex = getCurrentVisibleIndex(),
          let cell = getCurrentCell(at: currentIndex) else {
      print("Failed to get current video for toggle")
      return false
    }
    
    let wasPlaying = cell.feedPlayer.isVisible
    let newPlayingState = !wasPlaying
    isManuallyPaused = !newPlayingState // Update manual pause state
    
    cell.feedPlayer.isVisible = newPlayingState
    
    return newPlayingState
  }
  
  /// Gets the current playing state
  func isCurrentVideoPlaying() -> Bool {
    guard let currentIndex = getCurrentVisibleIndex(),
          let cell = getCurrentCell(at: currentIndex) else {
      return false
    }
    
    return cell.feedPlayer.isVisible
  }
  
  // Handle removing notificationcenter listners for app states
  deinit {
    NotificationCenter.default.removeObserver(self)
    playerPool.releaseAll()
  }
}

extension VideoFeedView: UICollectionViewDataSource {
  func collectionView(
    _ collectionView: UICollectionView, numberOfItemsInSection section: Int
  ) -> Int {
    return videos.count
  }
  
  func collectionView(
    _ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath
  ) -> UICollectionViewCell {
    let cell =
    collectionView.dequeueReusableCell(
      withReuseIdentifier: "VideoFeedCell", for: indexPath) as! VideoFeedCell
    cell.playerPool = playerPool
    let video = videos[indexPath.item]
    cell.configure(
      with: video,
      playerPool: playerPool,
      index: indexPath.item,
      total: videos.count
    )
    return cell
  }

  func collectionView(
    _ collectionView: UICollectionView,
    didEndDisplaying cell: UICollectionViewCell,
    forItemAt indexPath: IndexPath
  ) {
    guard let videoCell = cell as? VideoFeedCell else { return }
    if !videoCell.feedPlayer.videoId.isEmpty {
      playerPool.pause(videoId: videoCell.feedPlayer.videoId)
    }
    videoCell.feedPlayer.detachPlayer()
  }
}

extension VideoFeedView: UICollectionViewDelegate {
  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    handleScrollEnd()
  }

  func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
    handleScrollEnd()
  }

  func scrollViewDidEndDragging(
    _ scrollView: UIScrollView, willDecelerate decelerate: Bool
  ) {
    // Slow drags that snap without momentum never call didEndDecelerating.
    if !decelerate {
      handleScrollEnd()
    }
  }
  
  func collectionView(
    _ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell,
    forItemAt indexPath: IndexPath
  ) {
    // Play first video when it becomes available
    if shouldPlayFirstVideo && indexPath.item == 0 {
      shouldPlayFirstVideo = false
      // Use a small delay to ensure the cell is fully configured
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
        self?.playVideo(at: 0)
      }
    }
    
    if indexPath.item >= videos.count - 3 {
      onEndReached?()
    }
  }
}

extension VideoFeedView: UICollectionViewDataSourcePrefetching {
  func collectionView(
    _ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]
  ) {
    preloadNextVideos()
  }
}

struct VideoData {
  let id: String
  let videoUrl: String
  let thumbnailUrl: String?
  let viewCount: Int?
}
