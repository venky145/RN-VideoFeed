package com.rnvideofeed

import android.content.Context
import android.util.AttributeSet
import android.util.Log
import android.util.Xml
import android.view.View.MeasureSpec
import android.widget.FrameLayout
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.VideoSize
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.PlayerView
import androidx.media3.ui.AspectRatioFrameLayout

class FeedPlayer @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : FrameLayout(context, attrs, defStyleAttr) {

    var player: ExoPlayer? = null
        private set
    private val playerView: PlayerView
    private val TAG = "FeedPlayer"

    var videoUrl: String? = null
        private set

    var videoId: String = ""
        private set

    var isVisible: Boolean = true
        set(value) {
            field = value
            if (value) {
                player?.play()
            } else {
                player?.pause()
                hasNotifiedVideoStarted = false
                if (!isManualPause) {
                    onVideoPaused?.invoke()
                }
            }
        }

    private var currentAppliedResizeMode: Int = AspectRatioFrameLayout.RESIZE_MODE_FIT

    private val layoutRunnable = Runnable {
        if (isAttachedToWindow) {
            measure(
                MeasureSpec.makeMeasureSpec(width, MeasureSpec.EXACTLY),
                MeasureSpec.makeMeasureSpec(height, MeasureSpec.EXACTLY)
            )
            layout(left, top, right, bottom)
        }
    }

    private var isManualPause: Boolean = false
    private var hasNotifiedVideoStarted: Boolean = false
    private var playerListener: Player.Listener? = null

    fun setManualPause(manual: Boolean) {
        isManualPause = manual
    }

    var onVideoStarted: (() -> Unit)? = null
    var onVideoPaused: (() -> Unit)? = null

    init {
        playerView = createTexturePlayerView(context)
        playerView.apply {
            useController = false
            setShutterBackgroundColor(android.R.color.black)
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
            resizeMode = currentAppliedResizeMode
        }

        addView(playerView)
        setBackgroundColor(context.getColor(android.R.color.black))
    }

    fun bindFromPool(pool: VideoFeedPlayerPool, id: String, url: String) {
        if (videoId == id && player != null && pool.hasPlayer(id, url)) {
            return
        }

        detachPlayer()

        videoId = id
        videoUrl = url
        hasNotifiedVideoStarted = false

        val exoPlayer = pool.acquire(id, url)
        attachPlayer(exoPlayer)
    }

    fun hasPlaybackPosition(): Boolean {
        return (player?.currentPosition ?: 0L) > 300L
    }

    private fun attachPlayer(exoPlayer: ExoPlayer) {
        playerListener?.let { exoPlayer.removeListener(it) }

        val listener = createPlayerListener()
        playerListener = listener
        exoPlayer.addListener(listener)

        player = exoPlayer
        playerView.player = exoPlayer
        playerView.resizeMode = currentAppliedResizeMode
    }

    private fun createPlayerListener(): Player.Listener {
        return object : Player.Listener {
            override fun onVideoSizeChanged(videoSize: VideoSize) {
                currentAppliedResizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT
                playerView.resizeMode = currentAppliedResizeMode
                playerView.requestLayout()
                requestLayout()
                player?.videoScalingMode = androidx.media3.common.C.VIDEO_SCALING_MODE_SCALE_TO_FIT
            }

            override fun onPlaybackStateChanged(playbackState: Int) {
                if (playbackState == Player.STATE_READY) {
                    val videoFormat = player?.videoFormat
                    if (videoFormat != null && videoFormat.width > 0 && videoFormat.height > 0) {
                        onVideoSizeChanged(VideoSize(videoFormat.width, videoFormat.height))
                    }
                    notifyVideoStartedIfPlaying()
                }
            }

            override fun onIsPlayingChanged(isPlaying: Boolean) {
                if (isPlaying) {
                    notifyVideoStartedIfPlaying()
                }
            }

            override fun onPlayerError(error: PlaybackException) {
                Log.e(TAG, "Playback error: ${error.message}")
                hasNotifiedVideoStarted = false
                onVideoPaused?.invoke()
            }
        }
    }

    private fun notifyVideoStartedIfPlaying() {
        val p = player ?: return
        if (isVisible && p.isPlaying && p.playbackState == Player.STATE_READY && !hasNotifiedVideoStarted) {
            hasNotifiedVideoStarted = true
            Log.d(TAG, "Video ready and playing — notifying listeners")
            onVideoStarted?.invoke()
        }
    }

    private fun createTexturePlayerView(context: Context): PlayerView {
        val parser = context.resources.getXml(R.xml.player_view_texture)
        parser.next()
        parser.nextTag()
        val attrs: AttributeSet = Xml.asAttributeSet(parser)
        return PlayerView(context, attrs)
    }

    /** Detach from the view without releasing the pooled ExoPlayer instance. */
    fun detachPlayer() {
        playerListener?.let { listener ->
            player?.removeListener(listener)
        }
        playerListener = null
        player?.pause()
        playerView.player = null
        player = null
        hasNotifiedVideoStarted = false
    }

    fun reset() {
        detachPlayer()
        videoId = ""
        videoUrl = null
        isVisible = false
    }

    override fun requestLayout() {
        super.requestLayout()
        removeCallbacks(layoutRunnable)
        post(layoutRunnable)
    }

    override fun onLayout(changed: Boolean, left: Int, top: Int, right: Int, bottom: Int) {
        super.onLayout(changed, left, top, right, bottom)
        if (changed) {
            playerView.resizeMode = currentAppliedResizeMode
            playerView.requestLayout()
        }
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        detachPlayer()
    }
}
