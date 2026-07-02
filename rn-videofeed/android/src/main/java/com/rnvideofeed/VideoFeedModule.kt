package com.rnvideofeed

import android.util.Log
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.WritableNativeMap
import com.facebook.react.modules.core.DeviceEventManagerModule
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.bridge.UiThreadUtil

class VideoFeedModule(private val reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {
    
    private val TAG = "VideoFeedModule"
    
    override fun getName(): String {
        return "VideoFeedViewManager"
    }
    
    /**
     * Safely resolves a VideoFeedView by reactTag, handling cases where the view no longer exists
     * @param reactTag The React tag of the view to resolve
     * @return The VideoFeedView if found and valid, null otherwise
     */
    private fun safeResolveVideoFeedView(reactTag: Int): VideoFeedView? {
        return try {
            val uiManager = UIManagerHelper.getUIManagerForReactTag(reactContext, reactTag)
            uiManager?.resolveView(reactTag) as? VideoFeedView
        } catch (e: Exception) {
            Log.e(TAG, "Error resolving view for tag $reactTag: ${e.message}")
            null
        }
    }
    
    @ReactMethod
    fun setVideos(reactTag: Double, videos: ReadableArray) {
        Log.d(TAG, "=== setVideos called for tag: $reactTag, videos count: ${videos.size()} ===")
        UiThreadUtil.runOnUiThread {
            val view = safeResolveVideoFeedView(reactTag.toInt())
            if (view != null) {
                Log.d(TAG, "Found VideoFeedView, setting videos")
                val viewManager = VideoFeedViewManager()
                viewManager.setVideos(view, videos)
            } else {
                Log.e(TAG, "Failed to find VideoFeedView for tag: $reactTag")
            }
        }
    }
    
    @ReactMethod
    fun appendVideos(reactTag: Double, videos: ReadableArray) {
        Log.d(TAG, "Appending videos for tag: $reactTag")
        UiThreadUtil.runOnUiThread {
            val view = safeResolveVideoFeedView(reactTag.toInt())
            if (view != null) {
                Log.d(TAG, "Found view, appending videos")
                val viewManager = VideoFeedViewManager()
                viewManager.appendVideos(view, videos)
            } else {
                Log.d(TAG, "Failed to find view for tag: $reactTag")
            }
        }
    }
    
    @ReactMethod
    fun setFeedActive(reactTag: Double, isActive: Boolean) {
        Log.d(TAG, "setFeedActive for tag: $reactTag, isActive: $isActive")
        UiThreadUtil.runOnUiThread {
            val view = safeResolveVideoFeedView(reactTag.toInt())
            if (view != null) {
                Log.d(TAG, "Found view, setting feed active: $isActive")
                val viewManager = VideoFeedViewManager()
                viewManager.setFeedActive(view, isActive)
            } else {
                Log.d(TAG, "setFeedActive: View not found for tag $reactTag")
            }
        }
    }
    
    @ReactMethod
    fun addListener(eventName: String) {
        // Keep: Required for RN built in Event Emitter Calls.
        Log.d(TAG, "addListener: $eventName")
    }
    
    @ReactMethod
    fun pauseVideo(reactTag: Double) {
        Log.d(TAG, "=== pauseVideo called for tag: $reactTag ===")
        UiThreadUtil.runOnUiThread {
            val view = safeResolveVideoFeedView(reactTag.toInt())
            if (view != null) {
                Log.d(TAG, "Found VideoFeedView, pausing video")
                view.pauseCurrentVideo()
            } else {
                Log.e(TAG, "Failed to find VideoFeedView for tag: $reactTag")
            }
        }
    }
    
    @ReactMethod
    fun playVideo(reactTag: Double) {
        Log.d(TAG, "=== playVideo called for tag: $reactTag ===")
        UiThreadUtil.runOnUiThread {
            val view = safeResolveVideoFeedView(reactTag.toInt())
            if (view != null) {
                Log.d(TAG, "Found VideoFeedView, playing video")
                view.playCurrentVideo()
            } else {
                Log.e(TAG, "Failed to find VideoFeedView for tag: $reactTag")
            }
        }
    }
    
    @ReactMethod
    fun togglePlayPause(reactTag: Double) {
        Log.d(TAG, "=== togglePlayPause called for tag: $reactTag ===")
        UiThreadUtil.runOnUiThread {
            val view = safeResolveVideoFeedView(reactTag.toInt())
            if (view != null) {
                Log.d(TAG, "Found VideoFeedView, toggling play/pause")
                val isNowPlaying = view.togglePlayPause()
                
                // Emit event back to React Native
                val event = WritableNativeMap().apply {
                    putBoolean("isPlaying", isNowPlaying)
                }
                reactContext
                    .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
                    .emit("onPlayStateChanged", event)
            } else {
                Log.e(TAG, "Failed to find VideoFeedView for tag: $reactTag")
            }
        }
    }
    
    @ReactMethod
    fun isVideoPlaying(reactTag: Double) {
        Log.d(TAG, "=== isVideoPlaying called for tag: $reactTag ===")
        UiThreadUtil.runOnUiThread {
            val view = safeResolveVideoFeedView(reactTag.toInt())
            if (view != null) {
                Log.d(TAG, "Found VideoFeedView, checking playing state")
                val isPlaying = view.isCurrentVideoPlaying()
                
                // Emit event back to React Native
                val event = WritableNativeMap().apply {
                    putBoolean("isPlaying", isPlaying)
                }
                reactContext
                    .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
                    .emit("onPlayStateChecked", event)
            } else {
                Log.e(TAG, "Failed to find VideoFeedView for tag: $reactTag")
            }
        }
    }
    
    @ReactMethod
    fun removeListeners(count: Double) {
        // Keep: Required for RN built in Event Emitter Calls.
        Log.d(TAG, "removeListeners: $count")
    }
    
    @ReactMethod
    fun addEventListener(eventName: String) {
        // Legacy support
        Log.d(TAG, "addEventListener: $eventName")
    }
    
    @ReactMethod
    fun removeEventListener(eventName: String) {
        // Legacy support
        Log.d(TAG, "removeEventListener: $eventName")
    }
} 