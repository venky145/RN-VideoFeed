//
//  VideoFeedEventEmitter.swift
//  App
//
//  Created by Venkatesh Mandapati on 15/05/2025.
//

import Foundation
import React

@objc(VideoFeedEventEmitter)
class VideoFeedEventEmitter: RCTEventEmitter {
    override func supportedEvents() -> [String]! {
        return ["onEndReached", "onVideoChange", "onVideoTapped", "onPlayStateChanged"]
    }
    
    override static func requiresMainQueueSetup() -> Bool {
        return true
    }
    
    @objc func sendEvent(_ event: String, body: Any?) {
        sendEvent(withName: event, body: body)
    }
}
