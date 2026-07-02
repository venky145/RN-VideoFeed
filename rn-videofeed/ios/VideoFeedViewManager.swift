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

  // Common function to safely access VideoFeedView using the working approach
  private func withVideoFeedView(_ reactTag: NSNumber, operation: String, action: @escaping (VideoFeedView) -> Void) {
    
    // Add a small delay to ensure view is properly registered
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
      guard let uiManager = self?.bridge?.uiManager else {
        return
      }
      
      // Use the modern approach for New Architecture
      uiManager.addUIBlock { _, viewRegistry in
        
        // Try to get the view from the registry
        if let view = viewRegistry?[reactTag] as? VideoFeedView {
          action(view)
        } else {
          
          // Alternative approach: try to get view directly
          if let directView = uiManager.view(forReactTag: reactTag) as? VideoFeedView {
            action(directView)
          } else {
            
            // Last resort: try to enumerate all views
            for (tag, view) in viewRegistry ?? [:] {
              if let videoView = view as? VideoFeedView {
              }
            }
          }
        }
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
