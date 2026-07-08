//
//  VideoFeedCell.swift
//  App
//
//  Created by Venkatesh Mandapati on 15/05/2025.
//

import SDWebImage
import UIKit

class VideoFeedCell: UICollectionViewCell {

  let feedPlayer = FeedPlayer()
  weak var playerPool: VideoFeedPlayerPool?

  private let thumbnailImageView: UIImageView = {
    let iv = UIImageView()
    iv.contentMode = .scaleAspectFit
    iv.clipsToBounds = true
    iv.backgroundColor = UIColor(white: 0.08, alpha: 1)
    return iv
  }()

  private let loadingIndicator: UIActivityIndicatorView = {
    let spinner = UIActivityIndicatorView(style: .large)
    spinner.color = .white
    spinner.hidesWhenStopped = true
    return spinner
  }()

  private let indexLabel: UILabel = {
    let label = UILabel()
    label.textColor = .white
    label.font = .systemFont(ofSize: 14, weight: .semibold)
    label.textAlignment = .left
    label.backgroundColor = UIColor.black.withAlphaComponent(0.55)
    label.layer.cornerRadius = 8
    label.clipsToBounds = true
    label.numberOfLines = 1
    return label
  }()

  private var isShowingLoadingOverlay = false

  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.backgroundColor = .black

    contentView.addSubview(thumbnailImageView)
    thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      thumbnailImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
      thumbnailImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      thumbnailImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
    ])

    contentView.addSubview(feedPlayer)
    feedPlayer.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      feedPlayer.topAnchor.constraint(equalTo: contentView.topAnchor),
      feedPlayer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      feedPlayer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      feedPlayer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
    ])

    contentView.addSubview(loadingIndicator)
    loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      loadingIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      loadingIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
    ])

    contentView.addSubview(indexLabel)
    indexLabel.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      indexLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      indexLabel.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -24),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(
    with video: VideoData,
    playerPool: VideoFeedPlayerPool,
    index: Int,
    total: Int
  ) {
    indexLabel.text = "  \(index + 1) / \(max(total, 1)) · \(video.id)  "
    indexLabel.isHidden = false

    let resuming = playerPool.hasPlayer(videoId: video.id, videoUrl: video.videoUrl)
      && playerPool.getPlaybackPosition(videoId: video.id) > 0.3

    if resuming {
      hideThumbnailImmediately()
      stopLoading()
    } else {
      thumbnailImageView.isHidden = false
      if let thumb = video.thumbnailUrl, !thumb.isEmpty, let url = URL(string: thumb) {
        thumbnailImageView.sd_setImage(with: url, placeholderImage: nil, options: [], completed: nil)
      } else {
        thumbnailImageView.image = nil
      }
      startLoading()
    }

    feedPlayer.onVideoStartedPlaying = { [weak self] in
      self?.showVideoPlaying()
    }
    feedPlayer.bindFromPool(playerPool, id: video.id, url: video.videoUrl)
    feedPlayer.isVisible = false
  }

  func showVideoPlaying() {
    thumbnailImageView.isHidden = true
    stopLoading()
  }

  func hideThumbnailImmediately() {
    thumbnailImageView.isHidden = true
    stopLoading()
  }

  func showThumbnail() {
    thumbnailImageView.isHidden = false
    if feedPlayer.player?.timeControlStatus != .playing {
      startLoading()
    }
  }

  private func startLoading() {
    isShowingLoadingOverlay = true
    if !loadingIndicator.isAnimating {
      loadingIndicator.startAnimating()
    }
  }

  private func stopLoading() {
    isShowingLoadingOverlay = false
    loadingIndicator.stopAnimating()
  }

  func detachForReuse(using playerPool: VideoFeedPlayerPool) {
    if !feedPlayer.videoId.isEmpty {
      playerPool.pause(videoId: feedPlayer.videoId)
    }
    feedPlayer.detachPlayer()
    feedPlayer.isVisible = false
    feedPlayer.onVideoStartedPlaying = nil

    thumbnailImageView.sd_cancelCurrentImageLoad()
    thumbnailImageView.image = nil
    thumbnailImageView.isHidden = false
    stopLoading()
    indexLabel.text = nil
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    if let pool = playerPool {
      detachForReuse(using: pool)
    } else {
      feedPlayer.reset()
      thumbnailImageView.sd_cancelCurrentImageLoad()
      thumbnailImageView.image = nil
      thumbnailImageView.isHidden = false
      stopLoading()
      indexLabel.text = nil
    }
  }
}
