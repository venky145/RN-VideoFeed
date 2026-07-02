//
//  VideoFeedManagerBridge.m
//  App
//
//  Created by Venkatesh Mandapati on 16/05/2025.
//

#import <React/RCTViewManager.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTUIManager.h>
#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(VideoFeedViewManager, RCTViewManager)

RCT_EXTERN_METHOD(setVideos:(nonnull NSNumber *)reactTag videos:(NSArray *)videos)
RCT_EXTERN_METHOD(appendVideos:(nonnull NSNumber *)reactTag videos:(NSArray *)videos)
RCT_EXTERN_METHOD(setFeedActive:(nonnull NSNumber *)reactTag isActive:(BOOL)active)

RCT_EXTERN_METHOD(pauseVideo:(nonnull NSNumber *)reactTag)
RCT_EXTERN_METHOD(playVideo:(nonnull NSNumber *)reactTag)
RCT_EXTERN_METHOD(togglePlayPause:(nonnull NSNumber *)reactTag)
RCT_EXTERN_METHOD(isVideoPlaying:(nonnull NSNumber *)reactTag)

RCT_EXTERN_METHOD(addEventListener:(NSString *)eventName)
RCT_EXTERN_METHOD(removeEventListener:(NSString *)eventName)

@end

// Event Emitter for video feed events
@interface RCT_EXTERN_MODULE(VideoFeedEventEmitter, RCTEventEmitter)
@end
