package com.rnvideofeed

data class VideoData(
    val id: String,
    val videoUrl: String,
    val thumbnailUrl: String?,
    val viewCount: Int?
) 