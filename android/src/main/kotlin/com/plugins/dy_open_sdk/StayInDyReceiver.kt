package com.plugins.dy_open_sdk

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.bytedance.sdk.open.aweme.CommonConstants

/**
 * 用户留在抖音的情况下会广播通知
 * 当用户分享成功后选择留在抖音时，会收到此广播
 */
class StayInDyReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "StayInDyReceiver"
        const val SHARE_ACTION = CommonConstants.a
        const val IM_ACTION = "com.aweme.opensdk.action.stay.in.dy.im"
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        when (intent?.action) {
            SHARE_ACTION -> {
                // 分享成功，留在抖音
                Log.d(TAG, "分享成功，用户选择留在抖音")
                // 可以通过EventChannel通知Flutter端
            }
            IM_ACTION -> {
                // 分享给好友成功，留在抖音
                Log.d(TAG, "分享给好友成功，用户选择留在抖音")
                // 可以通过EventChannel通知Flutter端
            }
        }
    }
}