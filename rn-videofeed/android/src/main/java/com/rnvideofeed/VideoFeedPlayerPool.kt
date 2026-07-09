package com.rnvideofeed

import android.content.Context
import android.net.Uri
import android.util.Log
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer

/**
 * Keeps a small LRU pool of ExoPlayer instances keyed by video id so scrolling
 * back resumes playback where the user left off (Reels-style behaviour).
 */
class VideoFeedPlayerPool(
    private val context: Context,
    private val maxSize: Int = 8
) {
    private val tag = "VideoFeedPlayerPool"

    private data class PooledEntry(
        val player: ExoPlayer,
        var videoUrl: String,
        var lastAccessTime: Long = System.currentTimeMillis()
    )

    private val entries = LinkedHashMap<String, PooledEntry>(maxSize, 0.75f, true)

    fun acquire(videoId: String, videoUrl: String): ExoPlayer {
        entries[videoId]?.let { entry ->
            if (entry.videoUrl == videoUrl) {
                entry.lastAccessTime = System.currentTimeMillis()
                Log.d(tag, "Reusing pooled player for $videoId at ${entry.player.currentPosition}ms")
                return entry.player
            }
            removeEntry(videoId)
        }

        while (entries.size >= maxSize) {
            val oldestKey = entries.keys.first()
            Log.d(tag, "Evicting oldest player: $oldestKey")
            removeEntry(oldestKey)
        }

        val player = ExoPlayer.Builder(context).build().apply {
            repeatMode = Player.REPEAT_MODE_ONE
            volume = 1.0f
        }
        val uri = Uri.parse(videoUrl)
        val mimeType = when {
            videoUrl.endsWith(".m3u8", ignoreCase = true) -> MimeTypes.APPLICATION_M3U8
            videoUrl.endsWith(".mp4", ignoreCase = true) -> MimeTypes.VIDEO_MP4
            else -> null
        }
        val mediaItem = MediaItem.Builder()
            .setUri(uri)
            .apply { if (mimeType != null) setMimeType(mimeType) }
            .build()
        player.setMediaItem(mediaItem)
        player.prepare()

        entries[videoId] = PooledEntry(player, videoUrl)
        Log.d(tag, "Created new pooled player for $videoId (pool size=${entries.size})")
        return player
    }

    fun pause(videoId: String) {
        entries[videoId]?.player?.pause()
    }

    fun hasPlayer(videoId: String, videoUrl: String): Boolean {
        val entry = entries[videoId] ?: return false
        return entry.videoUrl == videoUrl
    }

    fun getPlaybackPosition(videoId: String): Long {
        return entries[videoId]?.player?.currentPosition ?: 0L
    }

    fun releaseAll() {
        Log.d(tag, "Releasing all ${entries.size} pooled players")
        entries.values.forEach { it.player.release() }
        entries.clear()
    }

    private fun removeEntry(videoId: String) {
        entries.remove(videoId)?.player?.release()
    }
}
