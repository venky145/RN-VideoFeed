//
//  VideoFeedViewManager.swift
//  App
//
//  Created by Venkatesh Mandapati on 05/06/2025.
//

import Foundation
import React
import UIKit

@objc(VideoFeedViewManager)
class VideoFeedViewManager: RCTViewManager {
  
    override func view() -> UIView! {
      let view = VideoFeedView()
      
      // Connect the event emitter
      if let eventEmitter = bridge?.module(forName: "VideoFeedEventEmitter") as? VideoFeedEventEmitter {
        view.eventEmitter = eventEmitter
        print("🔥 Connected VideoFeedEventEmitter to VideoFeedView")
      } else {
        print("⚠️ Failed to connect VideoFeedEventEmitter")
      }
      
      // Set up event handlers
      view.onEndReached = { [weak self] in
        self?.bridge?.eventDispatcher()?.sendAppEvent(withName: "onEndReached", body: nil)
      }
      view.onVideoChange = { videoId in
        self.bridge?.eventDispatcher()?.sendAppEvent(withName: "onVideoChange", body: ["videoId": videoId])
      }
      return view
    }

  override static func requiresMainQueueSetup() -> Bool {
    return true
  }

  // Safely resolve the VideoFeedView for a reactTag on both the legacy and new
  // architectures. The view registry lookup runs inside `addUIBlock`, which is
  // the only queue-safe way to read it. If the view is not yet registered
  // (command dispatched before mount completes) we retry a few times instead of
  // calling `uiManager.view(forReactTag:)`, which asserts it must run on the
  // UIManager queue and would crash when invoked from the UI block.
  private func withVideoFeedView(
    _ reactTag: NSNumber,
    operation: String,
    retriesLeft: Int = 40,
    action: @escaping (VideoFeedView) -> Void
  ) {
    guard let uiManager = bridge?.uiManager else {
      return
    }

    uiManager.addUIBlock { [weak self] _, viewRegistry in
      if let view = viewRegistry?[reactTag] as? VideoFeedView {
        action(view)
      } else if retriesLeft > 0 {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          self?.withVideoFeedView(
            reactTag,
            operation: operation,
            retriesLeft: retriesLeft - 1,
            action: action
          )
        }
      } else {
        print("⚠️ VideoFeedView not found for tag \(reactTag) during \(operation)")
      }
    }
  }

  @objc func setVideos(_ reactTag: NSNumber, videos: [[String: Any]]) {
    withVideoFeedView(reactTag, operation: "Setting videos") { view in
      view.setVideos(videos)
    }
  }

  @objc func appendVideos(_ reactTag: NSNumber, videos: [[String: Any]]) {
    withVideoFeedView(reactTag, operation: "Appending videos") { view in
      view.appendVideos(videos)
    }
  }

  @objc func setFeedActive(_ reactTag: NSNumber, isActive: Bool) {
    withVideoFeedView(reactTag, operation: "Setting feed active") { view in
      view.setFeedActive(isActive)
    }
  }

  @objc func pauseVideo(_ reactTag: NSNumber) {
    withVideoFeedView(reactTag, operation: "Pause video") { view in
      view.pauseCurrentVideo()
    }
  }

  @objc func playVideo(_ reactTag: NSNumber) {
    withVideoFeedView(reactTag, operation: "Play video") { view in
      view.playCurrentVideo()
    }
  }

  @objc func togglePlayPause(_ reactTag: NSNumber) {
    withVideoFeedView(reactTag, operation: "Toggle play/pause") { view in
      let isNowPlaying = view.togglePlayPause()
      // Emit event back to React Native
      self.bridge?.eventDispatcher()?.sendAppEvent(
        withName: "onPlayStateChanged", 
        body: ["isPlaying": isNowPlaying]
      )
    }
  }
  
  @objc func isVideoPlaying(_ reactTag: NSNumber) {
    withVideoFeedView(reactTag, operation: "Check playing state") { view in
      let isPlaying = view.isCurrentVideoPlaying()
      self.bridge?.eventDispatcher()?.sendAppEvent(
        withName: "onPlayStateChecked", 
        body: ["isPlaying": isPlaying]
      )
    }
  }

  @objc func addEventListener(_ eventName: String) {
    // No-op: Handled by RCTEventEmitter
  }

  @objc func removeEventListener(_ eventName: String) {
    // No-op: Handled by RCTEventEmitter
  }
}
