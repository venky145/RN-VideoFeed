package com.rnvideofeed

import android.util.Log
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.WritableMap
import com.facebook.react.bridge.WritableNativeMap
import com.facebook.react.common.MapBuilder
import com.facebook.react.modules.core.DeviceEventManagerModule
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext

class VideoFeedViewManager : SimpleViewManager<VideoFeedView>() {
    
    private val TAG = "VideoFeedViewManager"
    
    override fun getName(): String {
        return "VideoFeedView"
    }
    
    override fun createViewInstance(reactContext: ThemedReactContext): VideoFeedView {
        Log.d(TAG, "Creating new VideoFeedView")
        
        val view = VideoFeedView(reactContext)
        // Set the React context for event emission
        view.setReactContext(reactContext)
        
        // Set up event handlers using DeviceEventManagerModule for global events
        view.onEndReached = {
            Log.d(TAG, "End reached")
            reactContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
                .emit("onEndReached", null)
        }
        
        view.onVideoChange = { videoId ->
            Log.d(TAG, "Video changed: $videoId")
            val event: WritableMap = WritableNativeMap().apply {
                putString("videoId", videoId)
            }
            reactContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
                .emit("onVideoChange", event)
        }
        
        // Set up tap event handler
        view.onVideoTapped = { isPlaying ->
            Log.d(TAG, "Video tapped, isPlaying: $isPlaying")
            val event: WritableMap = WritableNativeMap().apply {
                putBoolean("isPlaying", isPlaying)
            }
            reactContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
                .emit("onVideoTapped", event)
        }
        
        Log.d(TAG, "VideoFeedView created")
        return view
    }
    

    
    // Method to be called from React Native
    fun setVideos(view: VideoFeedView, videos: ReadableArray) {
        Log.d(TAG, "Setting videos for view")
        
        val videoList = mutableListOf<Map<String, Any>>()
        
        for (i in 0 until videos.size()) {
            val videoMap = videos.getMap(i)
            if (videoMap != null) {
                val videoData = mutableMapOf<String, Any>()
                
                if (videoMap.hasKey("id")) {
                    videoData["id"] = videoMap.getString("id") ?: ""
                }
                if (videoMap.hasKey("videoUrl")) {
                    videoData["videoUrl"] = videoMap.getString("videoUrl") ?: ""
                }
                if (videoMap.hasKey("thumbnailUrl")) {
                    videoData["thumbnailUrl"] = videoMap.getString("thumbnailUrl") ?: ""
                }
                if (videoMap.hasKey("viewCount")) {
                    videoData["viewCount"] = videoMap.getInt("viewCount")
                }
                
                videoList.add(videoData)
            }
        }
        
        Log.d(TAG, "Found view, setting videos: ${videoList.size}")
        view.setVideos(videoList)
    }
    
    fun appendVideos(view: VideoFeedView, videos: ReadableArray) {
        Log.d(TAG, "Appending videos for view")
        
        val videoList = mutableListOf<Map<String, Any>>()
        
        for (i in 0 until videos.size()) {
            val videoMap = videos.getMap(i)
            if (videoMap != null) {
                val videoData = mutableMapOf<String, Any>()
                
                if (videoMap.hasKey("id")) {
                    videoData["id"] = videoMap.getString("id") ?: ""
                }
                if (videoMap.hasKey("videoUrl")) {
                    videoData["videoUrl"] = videoMap.getString("videoUrl") ?: ""
                }
                if (videoMap.hasKey("thumbnailUrl")) {
                    videoData["thumbnailUrl"] = videoMap.getString("thumbnailUrl") ?: ""
                }
                if (videoMap.hasKey("viewCount")) {
                    videoData["viewCount"] = videoMap.getInt("viewCount")
                }
                
                videoList.add(videoData)
            }
        }
        
        Log.d(TAG, "Found view, appending videos: ${videoList.size}")
        view.appendVideos(videoList)
    }
    
    fun setFeedActive(view: VideoFeedView, isActive: Boolean) {
        Log.d(TAG, "setFeedActive: isActive = $isActive")
        view.setFeedActive(isActive)
    }
} 