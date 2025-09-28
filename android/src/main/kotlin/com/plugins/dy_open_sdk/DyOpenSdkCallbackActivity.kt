package com.plugins.dy_open_sdk

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import com.bytedance.sdk.open.aweme.authorize.model.Authorization
import com.bytedance.sdk.open.aweme.common.handler.IApiEventHandler
import com.bytedance.sdk.open.aweme.common.model.BaseReq
import com.bytedance.sdk.open.aweme.common.model.BaseResp
import com.bytedance.sdk.open.aweme.share.Share
import com.bytedance.sdk.open.douyin.DouYinOpenApiFactory
import com.bytedance.sdk.open.douyin.ShareToContact
import com.bytedance.sdk.open.douyin.api.DouYinOpenApi
import com.bytedance.sdk.open.douyin.model.OpenRecord

/**
 * 抖音SDK回调处理Activity
 * 用于处理授权、分享等操作的回调结果
 */
class DyOpenSdkCallbackActivity : Activity(), IApiEventHandler {

    private var douYinOpenApi: DouYinOpenApi? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        android.util.Log.d("DyOpenSdk", "DyOpenSdkCallbackActivity onCreate")
        android.util.Log.d("DyOpenSdk", "Intent action: ${intent?.action}, data: ${intent?.data}")
        
        douYinOpenApi = DouYinOpenApiFactory.create(this)
        val handled = douYinOpenApi?.handleIntent(intent, this) ?: false
        android.util.Log.d("DyOpenSdk", "Intent handled: $handled")
        
        if (!handled) {
            // 如果没有处理Intent，直接关闭
            android.util.Log.d("DyOpenSdk", "Intent未被处理，关闭Activity")
            finish()
        }
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        setIntent(intent)
        douYinOpenApi?.handleIntent(intent, this)
    }

    override fun onReq(req: BaseReq?) {
        // 处理来自抖音的请求（通常不需要处理）
    }

    override fun onResp(resp: BaseResp?) {
        android.util.Log.d("DyOpenSdk", "收到回调响应: ${resp?.javaClass?.simpleName}")
        when (resp) {
            is Authorization.Response -> {
                android.util.Log.d("DyOpenSdk", "处理授权结果: success=${resp.isSuccess}, errorCode=${resp.errorCode}")
                handleAuthResponse(resp)
            }
            is Share.Response -> {
                android.util.Log.d("DyOpenSdk", "处理分享结果: errorCode=${resp.errorCode}, subErrorCode=${resp.subErrorCode}, errorMsg=${resp.errorMsg}")
                handleShareResponse(resp)
            }
            is ShareToContact.Response -> {
                android.util.Log.d("DyOpenSdk", "处理分享到好友结果: errorCode=${resp.errorCode}")
                handleShareToContactResponse(resp)
            }
            is OpenRecord.Response -> {
                android.util.Log.d("DyOpenSdk", "处理拍摄页结果: errorCode=${resp.errorCode}")
                handleOpenRecordResponse(resp)
            }
            else -> {
                android.util.Log.d("DyOpenSdk", "未知的响应类型: ${resp?.javaClass?.simpleName}")
            }
        }
        android.util.Log.d("DyOpenSdk", "回调处理完成，关闭Activity")
        finish()
    }

    override fun onErrorIntent(intent: Intent?) {
        // 处理错误的Intent
        finish()
    }

    private fun handleAuthResponse(response: Authorization.Response) {
        // 获取插件实例并处理授权回调
        val plugin = getPluginInstance()
        plugin?.handleAuthResponse(response)
    }

    private fun handleShareResponse(response: Share.Response) {
        // 可以通过EventChannel或其他方式通知Flutter端分享结果
        // 目前暂时只记录日志
        android.util.Log.d("DyOpenSdk", "Share result: errorCode=${response.errorCode}, subErrorCode=${response.subErrorCode}, errorMsg=${response.errorMsg}")
    }

    private fun handleShareToContactResponse(response: ShareToContact.Response) {
        // 处理分享到好友的结果
        android.util.Log.d("DyOpenSdk", "ShareToContact result: errorCode=${response.errorCode}, errorMsg=${response.errorMsg}")
    }

    private fun handleOpenRecordResponse(response: OpenRecord.Response) {
        // 处理拍摄页的结果
        android.util.Log.d("DyOpenSdk", "OpenRecord result: errorCode=${response.errorCode}, errorMsg=${response.errorMsg}")
    }

    private fun getPluginInstance(): DyOpenSdkPlugin? {
        // 通过静态引用获取插件实例
        return DyOpenSdkPlugin.instance
    }
}