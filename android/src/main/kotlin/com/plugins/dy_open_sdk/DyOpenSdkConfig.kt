package com.plugins.dy_open_sdk

import android.content.Context
import android.content.SharedPreferences

/**
 * 抖音开放平台SDK配置管理
 * 用于管理客户端密钥、调试模式等配置信息
 */
object DyOpenSdkConfig {
    private const val PREF_NAME = "dy_open_sdk_config"
    private const val KEY_CLIENT_KEY = "client_key"
    private const val KEY_DEBUG_MODE = "debug_mode"
    private const val KEY_INITIALIZED = "initialized"

    private var sharedPreferences: SharedPreferences? = null

    fun init(context: Context) {
        sharedPreferences = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
    }

    fun saveConfig(clientKey: String, debug: Boolean) {
        sharedPreferences?.edit()?.apply {
            putString(KEY_CLIENT_KEY, clientKey)
            putBoolean(KEY_DEBUG_MODE, debug)
            putBoolean(KEY_INITIALIZED, true)
            apply()
        }
    }

    fun getClientKey(): String? {
        return sharedPreferences?.getString(KEY_CLIENT_KEY, null)
    }

    fun isDebugMode(): Boolean {
        return sharedPreferences?.getBoolean(KEY_DEBUG_MODE, false) ?: false
    }

    fun isInitialized(): Boolean {
        return sharedPreferences?.getBoolean(KEY_INITIALIZED, false) ?: false
    }

    fun clear() {
        sharedPreferences?.edit()?.clear()?.apply()
    }

    // 常用的授权范围
    object AuthScope {
        const val USER_INFO = "user_info"
        const val MOBILE = "mobile"
        const val AWEME_SHARE = "aweme.share"
        const val IM_SHARE = "im.share"
        const val AWEME_CAPTURE = "aweme.capture"
    }

    // 媒体类型
    object MediaType {
        const val IMAGE = "image"
        const val VIDEO = "video"
    }

    // 分享类型
    object ShareType {
        const val NORMAL = 0  // 普通分享
        const val DAILY = 1   // 发日常
    }
}