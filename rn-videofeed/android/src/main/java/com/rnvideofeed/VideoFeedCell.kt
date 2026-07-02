package com.rnvideofeed

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import androidx.recyclerview.widget.RecyclerView
import com.bumptech.glide.Glide
import com.bumptech.glide.load.engine.DiskCacheStrategy

class VideoFeedCell(context: Context) : RecyclerView.ViewHolder(
    FrameLayout(context).apply {
        layoutParams = RecyclerView.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        )
    }
) {

    private val TAG = "VideoFeedCell"
    private val container = itemView as FrameLayout

    val feedPlayer: FeedPlayer = FeedPlayer(context)
    private val thumbnailImageView: ImageView = ImageView(context)

    private var hideThumbnailHandler: Handler? = null
    private var hideThumbnailRunnable: Runnable? = null

    init {
        container.setBackgroundColor(context.getColor(android.R.color.black))

        // Setup thumbnail image view
        thumbnailImageView.apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
            // FIT_CENTER to match video behavior - shows full content with letterboxing
            scaleType = ImageView.ScaleType.FIT_CENTER
            adjustViewBounds = true
            setBackgroundColor(android.graphics.Color.BLACK)
        }

        // Setup feed player
        feedPlayer.apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }

        // Add views to container (order matters - thumbnail should be on top initially)
        container.addView(feedPlayer)
        container.addView(thumbnailImageView)

        hideThumbnailHandler = Handler(Looper.getMainLooper())

        // Set up video start/pause callbacks
        feedPlayer.onVideoStarted = {
            Log.d(TAG, "🎬 Video actually started - hiding thumbnail with delay")
            // Give video a moment to start, then hide thumbnail
            hideThumbnailRunnable?.let { hideThumbnailHandler?.removeCallbacks(it) }
            hideThumbnailRunnable = Runnable {
                Log.d(TAG, "🚫 Hiding thumbnail due to video start")
                thumbnailImageView.animate()
                    .alpha(0f)
                    .setDuration(300)
                    .withEndAction {
                        thumbnailImageView.visibility = View.GONE
                        thumbnailImageView.alpha = 1f
                        Log.d(TAG, "✅ Thumbnail hidden after video start")
                    }
                    .start()
            }
            hideThumbnailHandler?.postDelayed(hideThumbnailRunnable!!, 300)
        }

        feedPlayer.onVideoPaused = {
            Log.d(TAG, "⏸️ Video paused - checking if manual pause")
            showThumbnail()
        }
    }

    fun configure(video: VideoData, playerPool: VideoFeedPlayerPool) {
        Log.d(TAG, "Configuring cell with video: ${video.id}")

        val resuming = playerPool.hasPlayer(video.id, video.videoUrl) &&
            playerPool.getPlaybackPosition(video.id) > 300L

        if (resuming) {
            hideThumbnailImmediately()
        } else {
            thumbnailImageView.visibility = View.VISIBLE
        }

        if (!video.thumbnailUrl.isNullOrEmpty()) {
            Glide.with(container.context)
                .load(video.thumbnailUrl)
                .diskCacheStrategy(DiskCacheStrategy.ALL)
                .fitCenter()
                .into(thumbnailImageView)
            Log.d(TAG, "🖼️ Loading thumbnail: ${video.thumbnailUrl}")
        } else {
            thumbnailImageView.scaleType = ImageView.ScaleType.FIT_CENTER
            thumbnailImageView.setImageDrawable(null)
            Log.d(TAG, "🖼️ No thumbnail URL — showing black placeholder")
        }

        feedPlayer.bindFromPool(playerPool, video.id, video.videoUrl)
        feedPlayer.isVisible = false
    }

    fun showVideoPlaying() {
        Log.d(TAG, "🎬 Video playing requested - thumbnail will hide when video actually starts")
        // The actual thumbnail hiding is now handled by the video start callback
        // This method is kept for compatibility but the real work is done in the callback
    }

    fun showThumbnail() {
        Log.d(TAG, "🖼️ Showing thumbnail (video paused) - current visibility: ${thumbnailImageView.visibility}, alpha: ${thumbnailImageView.alpha}")

        // Cancel any pending hide thumbnail task
        hideThumbnailRunnable?.let {
            hideThumbnailHandler?.removeCallbacks(it)
            Log.d(TAG, "❌ Cancelled pending thumbnail hide task")
        }
        hideThumbnailRunnable = null

        // Show thumbnail immediately when video is paused
        thumbnailImageView.clearAnimation()
        thumbnailImageView.alpha = 1f
        thumbnailImageView.visibility = View.VISIBLE

        Log.d(TAG, "✅ Thumbnail now visible - final visibility: ${thumbnailImageView.visibility}, alpha: ${thumbnailImageView.alpha}")
    }

    fun hideThumbnailImmediately() {
        Log.d(TAG, "🚫 Hiding thumbnail immediately")

        // Cancel any pending hide thumbnail task
        hideThumbnailRunnable?.let { hideThumbnailHandler?.removeCallbacks(it) }
        hideThumbnailRunnable = null

        // Hide thumbnail immediately
        thumbnailImageView.clearAnimation()
        thumbnailImageView.visibility = View.GONE
        thumbnailImageView.alpha = 1f // Reset for next use

        Log.d(TAG, "✅ Thumbnail hidden immediately")
    }

    fun prepareForReuse(playerPool: VideoFeedPlayerPool) {
        Log.d(TAG, "🔄 Preparing for reuse")

        hideThumbnailRunnable?.let { hideThumbnailHandler?.removeCallbacks(it) }
        hideThumbnailRunnable = null

        val id = feedPlayer.videoId
        if (id.isNotEmpty()) {
            playerPool.pause(id)
        }
        feedPlayer.detachPlayer()
        feedPlayer.isVisible = false

        thumbnailImageView.visibility = View.VISIBLE
        thumbnailImageView.alpha = 1f
        thumbnailImageView.clearAnimation()

        Glide.with(container.context).clear(thumbnailImageView)

        Log.d(TAG, "✅ Cell detached — player kept in pool")
    }

    fun cleanup() {
        hideThumbnailHandler?.removeCallbacksAndMessages(null)
        hideThumbnailHandler = null
        feedPlayer.onVideoStarted = null
        feedPlayer.onVideoPaused = null
        feedPlayer.detachPlayer()
    }
}
