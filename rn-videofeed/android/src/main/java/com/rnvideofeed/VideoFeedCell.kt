package com.rnvideofeed

import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.ProgressBar
import android.widget.TextView
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
    private val loadingIndicator: ProgressBar = ProgressBar(context)
    private val indexLabel: TextView = TextView(context)

    private var hideThumbnailHandler: Handler? = null
    private var hideThumbnailRunnable: Runnable? = null

    init {
        container.setBackgroundColor(context.getColor(android.R.color.black))

        thumbnailImageView.apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
            scaleType = ImageView.ScaleType.FIT_CENTER
            adjustViewBounds = true
            setBackgroundColor(Color.parseColor("#141414"))
        }

        feedPlayer.apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }

        val spinnerSize = TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP, 48f, context.resources.displayMetrics
        ).toInt()
        loadingIndicator.apply {
            layoutParams = FrameLayout.LayoutParams(spinnerSize, spinnerSize, Gravity.CENTER)
            visibility = View.GONE
        }

        val padH = TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP, 12f, context.resources.displayMetrics
        ).toInt()
        val padV = TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP, 8f, context.resources.displayMetrics
        ).toInt()
        val margin = TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP, 16f, context.resources.displayMetrics
        ).toInt()
        val bottomMargin = TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP, 48f, context.resources.displayMetrics
        ).toInt()
        indexLabel.apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.WRAP_CONTENT,
                FrameLayout.LayoutParams.WRAP_CONTENT,
                Gravity.BOTTOM or Gravity.START
            ).apply {
                setMargins(margin, 0, 0, bottomMargin)
            }
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            typeface = Typeface.DEFAULT_BOLD
            setBackgroundColor(Color.parseColor("#8C000000"))
            setPadding(padH, padV, padH, padV)
        }

        container.addView(feedPlayer)
        container.addView(thumbnailImageView)
        container.addView(loadingIndicator)
        container.addView(indexLabel)

        hideThumbnailHandler = Handler(Looper.getMainLooper())

        feedPlayer.onVideoStarted = {
            Log.d(TAG, "Video started - hiding thumbnail")
            hideThumbnailRunnable?.let { hideThumbnailHandler?.removeCallbacks(it) }
            hideThumbnailRunnable = Runnable {
                thumbnailImageView.animate()
                    .alpha(0f)
                    .setDuration(300)
                    .withEndAction {
                        thumbnailImageView.visibility = View.GONE
                        thumbnailImageView.alpha = 1f
                        stopLoading()
                    }
                    .start()
            }
            hideThumbnailHandler?.postDelayed(hideThumbnailRunnable!!, 300)
        }

        feedPlayer.onVideoPaused = {
            showThumbnail()
        }
    }

    fun configure(
        video: VideoData,
        playerPool: VideoFeedPlayerPool,
        index: Int = 0,
        total: Int = 1
    ) {
        Log.d(TAG, "Configuring cell with video: ${video.id}")
        indexLabel.text = "${index + 1} / ${maxOf(total, 1)} · ${video.id}"
        indexLabel.visibility = View.VISIBLE

        val resuming = playerPool.hasPlayer(video.id, video.videoUrl) &&
            playerPool.getPlaybackPosition(video.id) > 300L

        if (resuming) {
            hideThumbnailImmediately()
            stopLoading()
        } else {
            thumbnailImageView.visibility = View.VISIBLE
            startLoading()
        }

        if (!video.thumbnailUrl.isNullOrEmpty()) {
            Glide.with(container.context)
                .load(video.thumbnailUrl)
                .diskCacheStrategy(DiskCacheStrategy.ALL)
                .fitCenter()
                .into(thumbnailImageView)
        } else {
            thumbnailImageView.scaleType = ImageView.ScaleType.FIT_CENTER
            thumbnailImageView.setImageDrawable(null)
        }

        feedPlayer.bindFromPool(playerPool, video.id, video.videoUrl)
        feedPlayer.isVisible = false
    }

    fun showVideoPlaying() {
        // thumbnail hide handled by onVideoStarted callback
    }

    fun showThumbnail() {
        hideThumbnailRunnable?.let { hideThumbnailHandler?.removeCallbacks(it) }
        hideThumbnailRunnable = null
        thumbnailImageView.clearAnimation()
        thumbnailImageView.alpha = 1f
        thumbnailImageView.visibility = View.VISIBLE
        startLoading()
    }

    fun hideThumbnailImmediately() {
        hideThumbnailRunnable?.let { hideThumbnailHandler?.removeCallbacks(it) }
        hideThumbnailRunnable = null
        thumbnailImageView.clearAnimation()
        thumbnailImageView.visibility = View.GONE
        thumbnailImageView.alpha = 1f
        stopLoading()
    }

    private fun startLoading() {
        loadingIndicator.visibility = View.VISIBLE
    }

    private fun stopLoading() {
        loadingIndicator.visibility = View.GONE
    }

    fun prepareForReuse(playerPool: VideoFeedPlayerPool) {
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
        stopLoading()
        indexLabel.text = ""

        Glide.with(container.context).clear(thumbnailImageView)
    }

    fun cleanup() {
        hideThumbnailHandler?.removeCallbacksAndMessages(null)
        hideThumbnailHandler = null
        feedPlayer.onVideoStarted = null
        feedPlayer.onVideoPaused = null
        feedPlayer.detachPlayer()
    }
}
