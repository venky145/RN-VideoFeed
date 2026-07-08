package com.rnvideofeed

import android.app.Activity
import android.content.Context
import android.util.AttributeSet
import android.util.Log
import android.view.GestureDetector
import android.view.MotionEvent
import android.view.View
import android.view.View.MeasureSpec
import android.view.ViewGroup
import android.view.WindowManager
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.ProcessLifecycleOwner
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.PagerSnapHelper
import androidx.recyclerview.widget.RecyclerView
import androidx.core.content.ContextCompat
import androidx.media3.exoplayer.ExoPlayer
import com.facebook.react.bridge.WritableNativeMap
import com.facebook.react.modules.core.DeviceEventManagerModule

class VideoFeedView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : RecyclerView(context, attrs, defStyleAttr), DefaultLifecycleObserver {

    private val TAG = "VideoFeedView"
    private val playerPool = VideoFeedPlayerPool(context, 8)
    private val feedAdapter: VideoFeedAdapter
    private val feedLayoutManager: FullPageLinearLayoutManager
    private val snapHelper: PagerSnapHelper

    private var videos: MutableList<VideoData> = mutableListOf()
    private var currentPlayer: ExoPlayer? = null
    private var feedIsActive = true
    private var keepScreenOn = false
    private var appIsInBackground = false
    private var isManuallyPaused = false // Track if user manually paused
    
    // Gesture detector for tap handling
    private lateinit var gestureDetector: GestureDetector
    
    // React context for event emission
    private var reactContext: Context? = null

    // Callbacks
    var onEndReached: (() -> Unit)? = null
    var onVideoChange: ((String) -> Unit)? = null
    var onVideoTapped: ((Boolean) -> Unit)? = null

    init {
        Log.d(TAG, "Initializing VideoFeedView")

//        setBackgroundColor(ContextCompat.getColor(android.R.color.black))
      setBackgroundColor(ContextCompat.getColor(context, android.R.color.black))

        feedLayoutManager = FullPageLinearLayoutManager(context)
        feedAdapter = VideoFeedAdapter(context, playerPool) { position ->
            preloadNextVideos(position)
        }

        layoutManager = feedLayoutManager
        adapter = feedAdapter
        itemAnimator = null
        setHasFixedSize(false)
        setItemViewCacheSize(8)
        recycledViewPool.setMaxRecycledViews(0, 8)

        feedAdapter.registerAdapterDataObserver(object : AdapterDataObserver() {
            override fun onChanged() {
                Log.d(TAG, "Adapter onChanged — requesting layout")
                post { requestLayout() }
            }

            override fun onItemRangeInserted(positionStart: Int, itemCount: Int) {
                Log.d(TAG, "Adapter inserted $itemCount at $positionStart — requesting layout")
                post { requestLayout() }
            }
        })

        snapHelper = PagerSnapHelper()
        snapHelper.attachToRecyclerView(this)

        addOnScrollListener(object : OnScrollListener() {
            override fun onScrollStateChanged(recyclerView: RecyclerView, newState: Int) {
                super.onScrollStateChanged(recyclerView, newState)

                if (newState == SCROLL_STATE_IDLE) {
                    handleScrollEnd()
                }
            }
        })

        ProcessLifecycleOwner.get().lifecycle.addObserver(this)
        setupTapGesture()

        Log.d(TAG, "VideoFeedView initialized")
    }

    override fun onLayout(changed: Boolean, left: Int, top: Int, right: Int, bottom: Int) {
        super.onLayout(changed, left, top, right, bottom)
        val width = right - left
        val height = bottom - top
        Log.d(
            TAG,
            "VideoFeedView onLayout: ${width}x${height}, childCount=$childCount, itemCount=${feedAdapter.itemCount}"
        )

        if (width == 0 || height == 0) {
            Log.w(TAG, "⚠️ VideoFeedView has zero dimensions!")
        }
    }

    private fun handleScrollEnd() {
        val currentIndex = getCurrentIndex()
        Log.d(TAG, "📍 Scroll ended at index: $currentIndex")

        if (currentIndex < 0 || currentIndex >= videos.size) {
            Log.w(TAG, "⚠️ Invalid scroll position: $currentIndex (total: ${videos.size})")
            return
        }

        // Pause all videos first
        pauseAllVideos()

        // Small delay to ensure RecyclerView has settled
        postDelayed({
            if (feedIsActive && !appIsInBackground) {
                Log.d(TAG, "▶️ Starting video playback for settled position: $currentIndex")
                
                // Reset manual pause state for new video
                isManuallyPaused = false
                Log.d(TAG, "🔄 Video changed to index: $currentIndex, resetting manual pause state")
                
                playVideo(currentIndex)

                // Emit video change event
                val videoId = videos[currentIndex].id
                onVideoChange?.invoke(videoId)

                // Check if we're near the end for pagination
                val remainingVideos = videos.size - currentIndex - 1
                Log.d(TAG, "📊 Stats: Index=$currentIndex, Total=${videos.size}, Remaining=$remainingVideos")

                if (currentIndex >= videos.size - 3) {
                    Log.d(TAG, "🔥 Triggering onEndReached! (threshold reached)")
                    onEndReached?.invoke()
                }
            }
        }, 150) // Give RecyclerView time to settle
    }

    private fun getCurrentIndex(): Int {
        val snapView = snapHelper.findSnapView(feedLayoutManager)
        if (snapView != null) {
            val position = feedLayoutManager.getPosition(snapView)
            Log.d(TAG, "Snap helper found position: $position")
            return position
        }

        val fallbackPosition = feedLayoutManager.findFirstVisibleItemPosition()
        if (fallbackPosition != NO_POSITION) {
            Log.d(TAG, "Using fallback position: $fallbackPosition")
            return fallbackPosition
        }
        return if (videos.isNotEmpty()) 0 else -1
    }

    private fun playVideo(index: Int) {
        Log.d(TAG, "🎬 Attempting to play video at index: $index")

        if (!feedIsActive) {
            Log.d(TAG, "Feed inactive, skipping playVideo at index: $index")
            return
        }

        if (appIsInBackground) {
            Log.d(TAG, "App in background, skipping playVideo at index: $index")
            return
        }

        if (index < 0 || index >= videos.size) {
            Log.d(TAG, "Index out of bounds: $index")
            return
        }

        // Try to find ViewHolder, with retry mechanism
        var viewHolder = findViewHolderForAdapterPosition(index) as? VideoFeedCell

        if (viewHolder == null) {
            Log.d(TAG, "ViewHolder not found immediately, posting delayed retry...")
            post {
                playVideoWithRetry(index, 0)
            }
            return
        }

        Log.d(TAG, "✅ Found ViewHolder for index: $index")
        setupVideoForPlayback(viewHolder, index)
    }

    private fun playVideoWithRetry(index: Int, retryCount: Int) {
        if (retryCount >= 3) {
            Log.e(TAG, "❌ Failed to find ViewHolder after 3 retries for index: $index")
            return
        }

        if (!feedIsActive || index < 0 || index >= videos.size) {
            return
        }

        val viewHolder = findViewHolderForAdapterPosition(index) as? VideoFeedCell
        if (viewHolder != null) {
            Log.d(TAG, "✅ Found ViewHolder on retry $retryCount for index: $index")
            setupVideoForPlayback(viewHolder, index)
        } else {
            Log.d(TAG, "Retry $retryCount failed, scheduling another attempt...")
            postDelayed({
                playVideoWithRetry(index, retryCount + 1)
            }, 100)
        }
    }

    private fun setupVideoForPlayback(viewHolder: VideoFeedCell, index: Int) {
        Log.d(TAG, "🎯 Setting up video playback for index: $index, videoId: ${videos[index].id}")

        val video = videos[index]
        if (viewHolder.feedPlayer.videoId != video.id || viewHolder.feedPlayer.player == null) {
            viewHolder.configure(video, playerPool, index, videos.size)
        }

        currentPlayer = viewHolder.feedPlayer.player

        val resuming = playerPool.hasPlayer(video.id, video.videoUrl) &&
            playerPool.getPlaybackPosition(video.id) > 300L

        if (resuming || viewHolder.feedPlayer.hasPlaybackPosition()) {
            Log.d(TAG, "▶️ Resuming from ${playerPool.getPlaybackPosition(video.id)}ms")
            viewHolder.hideThumbnailImmediately()
        } else {
            Log.d(TAG, "🖼️ Ensuring thumbnail is visible before starting video")
            viewHolder.showThumbnail()
        }

        Log.d(TAG, "📹 Starting video - callbacks will handle thumbnail")

        if (!isManuallyPaused) {
            viewHolder.feedPlayer.isVisible = true
            Log.d(TAG, "▶️ Auto-playing new video at index: $index")
        } else {
            viewHolder.feedPlayer.isVisible = false
            Log.d(TAG, "⏸️ New video at index: $index but staying paused (manually paused)")
        }

        setVideoKeepScreenOn(true)

        Log.d(TAG, "✅ Video setup complete for index: $index")
    }

    private fun pauseAllVideos() {
        Log.d(TAG, "Pausing all videos")
        for (i in 0 until feedAdapter.itemCount) {
            val viewHolder = findViewHolderForAdapterPosition(i) as? VideoFeedCell
            if (viewHolder != null) {
                // This will trigger the onVideoPaused callback which will show the thumbnail
                viewHolder.feedPlayer.isVisible = false
            }
        }

        // Allow screen to sleep when all videos are paused
        setVideoKeepScreenOn(false)
    }

    private fun preloadNextVideos(currentIndex: Int) {
        val start = currentIndex + 1
        val end = minOf(currentIndex + 2, videos.size - 1)

        if (start <= end) {
            Log.d(TAG, "Preloading videos from index $start to $end")
            // Preloading logic can be implemented here if needed
            // For now, ExoPlayer handles some caching automatically
        }
    }

    fun setVideos(videoList: List<Map<String, Any>>) {
        Log.d(TAG, "=== Setting videos: ${videoList.size} ===")

        // Debug: Print first few videos
        videoList.take(2).forEachIndexed { index, video ->
            Log.d(TAG, "Video $index: id=${video["id"]}, url=${video["videoUrl"]}")
        }

        videos.clear()
        videos.addAll(videoList.mapNotNull { dict ->
            val id = dict["id"] as? String
            val url = dict["videoUrl"] as? String

            if (id != null && url != null) {
                VideoData(
                    id = id,
                    videoUrl = url,
                    thumbnailUrl = dict["thumbnailUrl"] as? String,
                    viewCount = dict["viewCount"] as? Int
                )
            } else {
                Log.w(TAG, "Failed to map video data - missing id or url: $dict")
                null
            }
        })

        Log.d(TAG, "Mapped videos count: ${videos.size}")
        feedAdapter.updateVideos(videos)
        adapter = feedAdapter
        post {
            Log.d(
                TAG,
                "Post-update: ${width}x${height}, lm=${feedLayoutManager.width}x${feedLayoutManager.height}, " +
                    "itemCount=${feedAdapter.itemCount}, childCount=$childCount, " +
                    "attached=$isAttachedToWindow, layoutSuppressed=$isLayoutSuppressed"
            )
            feedLayoutManager.scrollToPositionWithOffset(0, 0)
            if (width > 0 && height > 0) {
                measure(
                    MeasureSpec.makeMeasureSpec(width, MeasureSpec.EXACTLY),
                    MeasureSpec.makeMeasureSpec(height, MeasureSpec.EXACTLY)
                )
                layout(left, top, right, bottom)
            }
            requestLayout()
        }

        // Play first video if we have videos
        if (videos.isNotEmpty()) {
            Log.d(TAG, "Scheduling first video playback")
            post {
                Log.d(TAG, "Ensuring RecyclerView is positioned at index 0")
                scrollToPosition(0)
                postDelayed({
                    playVideo(0)
                }, 100)
            }
        } else {
            Log.w(TAG, "No videos to play!")
        }
    }

    fun appendVideos(videoList: List<Map<String, Any>>) {
        Log.d(TAG, "Appending videos: ${videoList.size}")

        val newVideos = videoList.mapNotNull { dict ->
            val id = dict["id"] as? String
            val url = dict["videoUrl"] as? String

            if (id != null && url != null) {
                VideoData(
                    id = id,
                    videoUrl = url,
                    thumbnailUrl = dict["thumbnailUrl"] as? String,
                    viewCount = dict["viewCount"] as? Int
                )
            } else {
                null
            }
        }

        videos.addAll(newVideos)
        feedAdapter.updateVideos(videos)
    }

    fun setFeedActive(isActive: Boolean) {
        Log.d(TAG, "📱 setFeedActive called with isActive: $isActive, current feedIsActive: $feedIsActive, appIsInBackground: $appIsInBackground")
        feedIsActive = isActive

        if (isActive) {
            Log.d(TAG, "🔥 setFeedActive: Resuming video")
            val currentIndex = getCurrentIndex()
            Log.d(TAG, "🎯 Current index for resume: $currentIndex")
            // Small delay to ensure view is ready before playing
            postDelayed({
                if (feedIsActive && !appIsInBackground) {
                    Log.d(TAG, "▶️ Actually playing video after delay")
                    playVideo(currentIndex)
                } else {
                    Log.d(TAG, "⏸️ Not playing video - feedIsActive: $feedIsActive, appIsInBackground: $appIsInBackground")
                }
            }, 100)
        } else {
            Log.d(TAG, "⏸️ setFeedActive: Pausing video")
            pauseAllVideos()
            setVideoKeepScreenOn(false) // Allow screen to sleep when not active
        }
    }

    private fun setVideoKeepScreenOn(keepOn: Boolean) {
        if (keepScreenOn == keepOn) return

        keepScreenOn = keepOn
        Log.d(TAG, "Setting keep screen on: $keepOn")

        try {
            val activity = context as? Activity
            activity?.runOnUiThread {
                if (keepOn) {
                    activity.window?.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    Log.d(TAG, "✅ Screen will stay awake during video playback")
                } else {
                    activity.window?.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    Log.d(TAG, "💤 Screen can now sleep")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set keep screen on: ${e.message}")
        }
    }

    // App lifecycle callbacks
    override fun onStart(owner: LifecycleOwner) {
        super.onStart(owner)
        Log.d(TAG, "📱 App became active")
        appIsInBackground = false

        // Resume video if feed is active and not manually paused
        if (feedIsActive && !isManuallyPaused) {
            Log.d(TAG, "App became active & feed is active & not manually paused — resuming current video")
            val currentIndex = getCurrentIndex()
            playVideo(currentIndex)
        } else if (isManuallyPaused) {
            Log.d(TAG, "App became active but video was manually paused — staying paused")
        }
    }

    override fun onStop(owner: LifecycleOwner) {
        super.onStop(owner)
        Log.d(TAG, "📱 App entered background — pausing ALL videos")
        appIsInBackground = true

        // Pause all videos when app goes to background
        pauseAllVideos()
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        Log.d(TAG, "VideoFeedView detached from window")

        // Unregister lifecycle observer
        ProcessLifecycleOwner.get().lifecycle.removeObserver(this)

        // Clean up all players
        playerPool.releaseAll()
        for (i in 0 until feedAdapter.itemCount) {
            val viewHolder = findViewHolderForAdapterPosition(i) as? VideoFeedCell
            viewHolder?.cleanup()
        }

        // Release screen wake lock
        setVideoKeepScreenOn(false)
    }

    // Set React context for event emission
    fun setReactContext(context: Context) {
        this.reactContext = context
    }
    
    // MARK: - Tap Gesture Setup
    
    private fun setupTapGesture() {
        gestureDetector = GestureDetector(context, object : GestureDetector.SimpleOnGestureListener() {
            override fun onSingleTapConfirmed(e: MotionEvent): Boolean {
                Log.d(TAG, "🔥 Tap detected in native VideoFeedView")
                handleTap()
                return true
            }
            
            override fun onDown(e: MotionEvent): Boolean {
                Log.d(TAG, "🔥 Touch down detected")
                return false // Let other gestures handle it
            }
            
            // Don't interfere with scroll gestures
            override fun onScroll(
                e1: MotionEvent?,
                e2: MotionEvent,
                distanceX: Float,
                distanceY: Float
            ): Boolean {
                Log.d(TAG, "🔥 Scroll detected - letting RecyclerView handle")
                // Let RecyclerView handle scroll
                return false
            }
        })
        Log.d(TAG, "🔥 Tap gesture detector setup complete")
    }
    
    override fun onInterceptTouchEvent(event: MotionEvent): Boolean {
        // Let gesture detector handle taps
        gestureDetector.onTouchEvent(event)
        // Don't intercept - let RecyclerView handle touches (for scrolling)
        return false
    }
    
    private fun handleTap() {
        Log.d(TAG, "🔥 Processing tap - toggling play/pause")
        
        // Toggle play/pause and get the new state
        val isNowPlaying = togglePlayPause()
        
        // Use callback to emit event to React Native for UI feedback
        onVideoTapped?.invoke(isNowPlaying)
    }

    // MARK: - Play/Pause Control Methods
    
    /**
     * Gets the current visible index based on scroll position
     */
    private fun getCurrentVisibleIndex(): Int? {
        return feedLayoutManager.findFirstCompletelyVisibleItemPosition()
            .takeIf { it != NO_POSITION }
    }
    
    /**
     * Gets the current visible ViewHolder
     */
    private fun getCurrentCell(index: Int): VideoFeedCell? {
        return findViewHolderForAdapterPosition(index) as? VideoFeedCell
    }
    
    /**
     * Pauses the currently playing video
     */
    fun pauseCurrentVideo() {
        val currentIndex = getCurrentVisibleIndex()
        if (currentIndex == null) {
            Log.d(TAG, "Failed to get current video for pause")
            return
        }
        
        val cell = getCurrentCell(currentIndex)
        if (cell == null) {
            Log.d(TAG, "Failed to get current cell for pause")
            return
        }
        
        Log.d(TAG, "⏸️ Manually pausing video at index: $currentIndex")
        isManuallyPaused = true
        cell.feedPlayer.isVisible = false
    }
    
    /**
     * Plays the currently visible video
     */
    fun playCurrentVideo() {
        val currentIndex = getCurrentVisibleIndex()
        if (currentIndex == null) {
            Log.d(TAG, "Failed to get current video for play")
            return
        }
        
        val cell = getCurrentCell(currentIndex)
        if (cell == null) {
            Log.d(TAG, "Failed to get current cell for play")
            return
        }
        
        Log.d(TAG, "▶️ Manually playing video at index: $currentIndex")
        isManuallyPaused = false
        cell.feedPlayer.isVisible = true
    }
    
    /**
     * Toggles play/pause state of current video
     * Returns the new playing state (true = playing, false = paused)
     */
    fun togglePlayPause(): Boolean {
        val currentIndex = getCurrentVisibleIndex()
        if (currentIndex == null) {
            Log.d(TAG, "Failed to get current video for toggle")
            return false
        }
        
        val cell = getCurrentCell(currentIndex)
        if (cell == null) {
            Log.d(TAG, "Failed to get current cell for toggle")
            return false
        }
        
        val wasPlaying = cell.feedPlayer.isVisible
        val newPlayingState = !wasPlaying
        isManuallyPaused = !newPlayingState // Update manual pause state
        
        Log.d(TAG, "🔄 Toggling video at index: $currentIndex, was playing: $wasPlaying, now playing: $newPlayingState, manually paused: $isManuallyPaused")
        Log.d(TAG, "🔄 Setting feedPlayer.isVisible to: $newPlayingState")
        
        // Set the manual pause flag on the FeedPlayer
        cell.feedPlayer.setManualPause(!newPlayingState)
        
        // Set the visibility which will trigger play/pause
        cell.feedPlayer.isVisible = newPlayingState
        
        // Verify the state was set correctly
        Log.d(TAG, "🔄 After setting, feedPlayer.isVisible is: ${cell.feedPlayer.isVisible}")
        
        return newPlayingState
    }
    
    /**
     * Gets the current playing state
     */
    fun isCurrentVideoPlaying(): Boolean {
        val currentIndex = getCurrentVisibleIndex() ?: return false
        val cell = getCurrentCell(currentIndex) ?: return false
        return cell.feedPlayer.isVisible
    }
    
    /**
     * Gets the manual pause state
     */
    fun isManuallyPaused(): Boolean {
        return isManuallyPaused
    }
}

// Each feed page fills the RecyclerView viewport (required for vertical paging).
private class FullPageLinearLayoutManager(context: Context) :
    LinearLayoutManager(context, VERTICAL, false) {

    override fun measureChildWithMargins(child: View, widthUsed: Int, heightUsed: Int) {
        val widthSpec = MeasureSpec.makeMeasureSpec(
            width - paddingLeft - paddingRight,
            MeasureSpec.EXACTLY
        )
        val heightSpec = MeasureSpec.makeMeasureSpec(
            height - paddingTop - paddingBottom,
            MeasureSpec.EXACTLY
        )
        child.measure(widthSpec, heightSpec)
    }
}

// RecyclerView Adapter
class VideoFeedAdapter(
    private val context: Context,
    private val playerPool: VideoFeedPlayerPool,
    private val onItemVisible: (Int) -> Unit
) : RecyclerView.Adapter<VideoFeedCell>() {

    private val TAG = "VideoFeedAdapter"
    private var videos: List<VideoData> = emptyList()

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): VideoFeedCell {
        val itemHeight = when {
            parent.height > 0 -> parent.height
            parent.measuredHeight > 0 -> parent.measuredHeight
            else -> parent.context.resources.displayMetrics.heightPixels
        }
        Log.d(TAG, "Creating ViewHolder, itemHeight=$itemHeight")
        val cell = VideoFeedCell(parent.context)
        cell.itemView.layoutParams = RecyclerView.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            itemHeight
        )
        return cell
    }

    override fun onBindViewHolder(holder: VideoFeedCell, position: Int) {
        Log.d(TAG, "Binding ViewHolder at position: $position")
        holder.configure(videos[position], playerPool, position, videos.size)
        onItemVisible(position)
    }

    override fun onViewRecycled(holder: VideoFeedCell) {
        super.onViewRecycled(holder)
        Log.d(TAG, "♻️ Recycling ViewHolder")
        holder.prepareForReuse(playerPool)
    }

    override fun onViewAttachedToWindow(holder: VideoFeedCell) {
        super.onViewAttachedToWindow(holder)
        Log.d(TAG, "📎 ViewHolder attached to window")
    }

    override fun onViewDetachedFromWindow(holder: VideoFeedCell) {
        super.onViewDetachedFromWindow(holder)
        Log.d(TAG, "📎 ViewHolder detached from window")
        holder.feedPlayer.isVisible = false // Ensure video stops playing
    }

    override fun getItemCount(): Int {
        Log.d(TAG, "Item count: ${videos.size}")
        return videos.size
    }

    fun updateVideos(newVideos: List<VideoData>) {
        val previousCount = videos.size
        videos = newVideos
        Log.d(TAG, "updateVideos: ${newVideos.size} (was $previousCount)")
        when {
            previousCount == 0 && newVideos.isNotEmpty() -> notifyItemRangeInserted(0, newVideos.size)
            newVideos.isEmpty() && previousCount > 0 -> notifyItemRangeRemoved(0, previousCount)
            else -> notifyDataSetChanged()
        }
    }
}
