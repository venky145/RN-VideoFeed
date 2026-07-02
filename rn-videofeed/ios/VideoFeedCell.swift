//
//  VideoFeedCell.swift
//  App
//
//  Created by Venkatesh Mandapati on 15/05/2025.
//

import UIKit
import SDWebImage

class VideoFeedCell: UICollectionViewCell {

  let feedPlayer = FeedPlayer()

  private let thumbnailImageView: UIImageView = {
    let iv = UIImageView()
    iv.contentMode = .scaleAspectFit
    iv.clipsToBounds = true
    return iv
  }()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.backgroundColor = .black

    contentView.addSubview(thumbnailImageView)
    thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      thumbnailImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
      thumbnailImageView.bottomAnchor.constraint(
        equalTo: contentView.bottomAnchor),
      thumbnailImageView.leadingAnchor.constraint(
        equalTo: contentView.leadingAnchor),
      thumbnailImageView.trailingAnchor.constraint(
        equalTo: contentView.trailingAnchor),
    ])

    contentView.addSubview(feedPlayer)
    feedPlayer.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      feedPlayer.topAnchor.constraint(equalTo: contentView.topAnchor),
      feedPlayer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      feedPlayer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      feedPlayer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(with video: VideoData) {
    // Show and start animation while loading

    thumbnailImageView.sd_setImage(
      with: URL(string: video.thumbnailUrl ?? ""),
      placeholderImage: nil,
      options: [],
      completed: nil
    )

    feedPlayer.videoUrl = video.videoUrl as NSString
    feedPlayer.id = video.id as NSString
    feedPlayer.isVisible = false
    
    // Set callback to hide thumbnail when video actually starts playing
    feedPlayer.onVideoStartedPlaying = { [weak self] in
      self?.showVideoPlaying()
    }

    thumbnailImageView.isHidden = false
  }

  func showVideoPlaying() {
    // Hide thumbnail when video is visible
    thumbnailImageView.isHidden = true
  }

  override func prepareForReuse() {
    super.prepareForReuse()

    feedPlayer.reset()
    feedPlayer.isVisible = false
    feedPlayer.onVideoStartedPlaying = nil // Clear callback

    thumbnailImageView.image = nil
    thumbnailImageView.isHidden = false

  }
  
  
  // Implement delegate methods to handle taps and communicate with RN side or native controller
//  func didTapOptions() {
//    // Show action sheet for delete/save video here
//  }
//
//  func didTapMuteToggle() {
//    // Mute/unmute toggle logic here
//  }
//
//  func didTapFlag() {
//    // Show report bottom sheet logic here
//  }
//
//  func didTapViewCount() {
//    // Show view count bottom sheet
//  }
//
//  func didTapTradingVolume() {
//    // Show trading volume bottom sheet
//  }
//
//  func didTapShare() {
//    // Trigger share logic
//  }

}
