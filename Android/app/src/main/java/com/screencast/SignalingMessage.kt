package com.screencast

import com.google.gson.annotations.SerializedName

sealed class SignalingMessage {
    @SerializedName("type")
    abstract val type: String

    data class Offer(
        @SerializedName("sdp") val sdp: String,
        @SerializedName("type") override val type: String = "offer"
    ) : SignalingMessage()

    data class Answer(
        @SerializedName("sdp") val sdp: String,
        @SerializedName("type") override val type: String = "answer"
    ) : SignalingMessage()

    data class IceCandidate(
        @SerializedName("candidate") val candidate: String,
        @SerializedName("sdpMid") val sdpMid: String,
        @SerializedName("sdpMLineIndex") val sdpMLineIndex: Int,
        @SerializedName("type") override val type: String = "ice-candidate"
    ) : SignalingMessage()

    data class Ready(
        @SerializedName("type") override val type: String = "ready",
        @SerializedName("width") val width: Int,
        @SerializedName("height") val height: Int,
        @SerializedName("dpi") val dpi: Int
    ) : SignalingMessage()

    data class Error(
        @SerializedName("message") val message: String,
        @SerializedName("type") override val type: String = "error"
    ) : SignalingMessage()

    companion object {
        fun fromJson(json: String): SignalingMessage? {
            return try {
                com.google.gson.Gson().fromJson(json, SignalingMessage::class.java)
            } catch (e: Exception) {
                null
            }
        }
    }
}