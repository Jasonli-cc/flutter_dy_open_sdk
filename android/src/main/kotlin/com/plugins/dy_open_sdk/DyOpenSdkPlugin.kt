package com.plugins.dy_open_sdk

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
// Douyin OpenSDK imports
import com.bytedance.sdk.open.douyin.DouYinOpenApiFactory
import com.bytedance.sdk.open.aweme.init.DouYinOpenSDKConfig
import com.bytedance.sdk.open.aweme.adapter.image.picasso.PicassoOpenImageServiceImpl
import com.bytedance.sdk.open.aweme.adapter.okhttp.OpenNetworkOkHttpServiceImpl
import com.bytedance.sdk.open.aweme.share.Share
import com.bytedance.sdk.open.aweme.base.*
import com.bytedance.sdk.open.aweme.base.openentity.*
import com.bytedance.sdk.open.aweme.utils.ThreadUtils
import com.bytedance.sdk.open.aweme.CommonConstants
import com.bytedance.sdk.open.douyin.ShareToContact
import com.bytedance.sdk.open.douyin.model.ContactHtmlObject
import com.bytedance.sdk.open.douyin.model.OpenRecord
import com.bytedance.sdk.open.aweme.authorize.model.Authorization
import com.bytedance.sdk.open.aweme.common.handler.IApiEventHandler
import com.bytedance.sdk.open.aweme.common.model.BaseReq
import com.bytedance.sdk.open.aweme.common.model.BaseResp
import java.io.File
import java.io.FileOutputStream
import java.util.UUID

/** DyOpenSdkPlugin */
class DyOpenSdkPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private var activity: Activity? = null
  private var applicationContext: Context? = null
  
  // 授权相关
  private var pendingAuthResult: MethodChannel.Result? = null
  private var authState: String? = null
  
  // 分享相关
  private var pendingShareResult: MethodChannel.Result? = null
  private var pendingShareToContactResult: MethodChannel.Result? = null
  private var pendingOpenRecordResult: MethodChannel.Result? = null

  companion object {
    var instance: DyOpenSdkPlugin? = null
  }

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "dy_open_sdk")
    channel.setMethodCallHandler(this)
    applicationContext = flutterPluginBinding.applicationContext
    instance = this
    // 初始化配置管理
    DyOpenSdkConfig.init(flutterPluginBinding.applicationContext)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
      "initialize" -> {
        val args = call.arguments as? Map<*, *> ?: run {
          DyOpenSdkException.parameterError(result, "Arguments must be a map.")
          return
        }
        try {
          val clientKey = args["clientKey"] as? String ?: run {
            DyOpenSdkException.parameterError(result, "clientKey is required.", "clientKey")
            return
          }
          
          if (clientKey.isBlank()) {
            DyOpenSdkException.handleException(
              result, 
              IllegalArgumentException("clientKey cannot be empty"),
              DyOpenSdkException.ExceptionType.PARAMETER,
              DyOpenSdkException.ErrorCode.INVALID_CLIENT_KEY,
              "客户端密钥不能为空"
            )
            return
          }
          
          val debug = args["debug"] as? Boolean ?: false
          DouYinOpenApiFactory.setDebuggable(debug)
          val context = applicationContext ?: activity?.applicationContext
          if (context == null) {
            DyOpenSdkException.handleException(
              result,
              IllegalStateException("Application context is null"),
              DyOpenSdkException.ExceptionType.INITIALIZATION,
              DyOpenSdkException.ErrorCode.NO_CONTEXT,
              "应用上下文为空，请确保插件正确初始化"
            )
            return
          }
          val config = DouYinOpenSDKConfig.Builder()
            .context(context)
            .clientKey(clientKey)
            .networkService(OpenNetworkOkHttpServiceImpl())
            .imageService(PicassoOpenImageServiceImpl())
            .build()
          DouYinOpenApiFactory.initConfig(config)
          
          // 保存配置信息
          DyOpenSdkConfig.saveConfig(clientKey, debug)
          
          android.util.Log.d("DyOpenSdk", "SDK初始化成功: clientKey=${clientKey.take(8)}***, debug=$debug")
          DyOpenSdkException.success(result, mapOf("success" to true, "debug" to debug))
        } catch (e: Exception) {
          DyOpenSdkException.handleException(
            result,
            e,
            DyOpenSdkException.ExceptionType.INITIALIZATION,
            DyOpenSdkException.ErrorCode.INIT_ERROR,
            "SDK初始化失败"
          )
        }
      }
      "shareImages" -> {
        val act = activity ?: run {
          DyOpenSdkException.handleException(
            result,
            IllegalStateException("Activity is null"),
            DyOpenSdkException.ExceptionType.API_CALL,
            DyOpenSdkException.ErrorCode.NO_ACTIVITY,
            "Activity为空，无法执行分享操作"
          )
          return
        }
        val args = call.arguments as? Map<*, *> ?: run {
          DyOpenSdkException.parameterError(result, "Arguments must be a map.")
          return
        }
        try {
          val media = (args["media"] as? List<*>)?.map { it.toString() } ?: emptyList()
          if (media.isEmpty()) {
            DyOpenSdkException.parameterError(result, "media list cannot be empty.", "media")
            return
          }
          val isAlbum = args["isAlbum"] as? Boolean ?: false
          val shareId = args["shareId"] as? String
          val microAppInfoMap = args["microAppInfo"] as? Map<*, *>
          val hashTags = (args["hashTags"] as? List<*>)?.map { it.toString() }
          val newShare = args["newShare"] as? Boolean ?: false
          val shareToPublish = args["shareToPublish"] as? Boolean ?: false
          val shareParamMap = args["shareParam"] as? Map<*, *>

          val request = Share.Request()
          // 普通分享不设置shareToType，只有发日常才设置为1
          request.mMediaContent = MediaContent().apply {
            mMediaObject = if (isAlbum && media.size > 1) {
              // 图集模式：多张 `1``图片时启用图集
              ImageAlbumObject().apply {
                mImagePaths = ArrayList<String>().apply { addAll(convertPathsWithProvider(act, media)) }
                isImageAlbum = true
                android.util.Log.d("DyOpenSdk", "使用图集模式，图片数量: ${media.size}")
              }
            } else if (media.size == 1) {
              // 单张图片：使用ImageObject
              ImageObject().apply {
                mImagePaths = ArrayList<String>().apply { addAll(convertPathsWithProvider(act, media)) }
                android.util.Log.d("DyOpenSdk", "使用单图模式")
              }
            } else {
              // 多张图片但不启用图集：使用ImageAlbumObject但不开启图集模式
              ImageAlbumObject().apply {
                mImagePaths = ArrayList<String>().apply { addAll(convertPathsWithProvider(act, media)) }
                isImageAlbum = false
                android.util.Log.d("DyOpenSdk", "使用多图非图集模式，图片数量: ${media.size}")
              }
            }
          }
          shareId?.let { request.mState = it }
          microAppInfoMap?.let { request.mMicroAppInfo = buildMicroAppInfo(it) }
          hashTags?.let { request.mHashTagList = ArrayList<String>().apply { addAll(it) } }
          request.newShare = newShare
          shareParamMap?.let { request.shareParam = buildShareParam(act, it, media) }
          request.callerLocalEntry = DyOpenSdkCallbackActivity::class.java.canonicalName

          val api = DouYinOpenApiFactory.create(act) ?: run {
            DyOpenSdkException.handleException(
              result,
              IllegalStateException("Cannot create DouYin API instance"),
              DyOpenSdkException.ExceptionType.API_CALL,
              DyOpenSdkException.ErrorCode.DOUYIN_NOT_INSTALLED,
              "无法创建抖音API实例，请检查是否已安装抖音"
            )
            return
          }
          // Android不支持图片直接到发布页，若传入true则忽略并保留到编辑页
          if (shareToPublish) {
            android.util.Log.w("DyOpenSdk", "shareToPublish=true 对图片不生效，已回退到编辑页")
          }
          
          android.util.Log.d("DyOpenSdk", "开始分享图片，媒体数量: ${media.size}, isAlbum参数: $isAlbum")
          android.util.Log.d("DyOpenSdk", "分享请求配置: callerLocalEntry=${request.callerLocalEntry}")
          android.util.Log.d("DyOpenSdk", "媒体对象类型: ${request.mMediaContent?.mMediaObject?.javaClass?.simpleName}")
          
          // 检查图集模式支持（图集模式是基础分享功能的一部分）
          if (isAlbum && media.size > 1) {
            android.util.Log.d("DyOpenSdk", "启用图集模式，图片数量: ${media.size}")
          }
          
          // 保存pending result以便回调时使用
          pendingShareResult = result
          
          val shareResult = api.share(request)
          android.util.Log.d("DyOpenSdk", "分享请求已发送，结果: $shareResult")
        } catch (e: Exception) {
          DyOpenSdkException.handleException(
            result,
            e,
            DyOpenSdkException.ExceptionType.SHARE,
            DyOpenSdkException.ErrorCode.SHARE_ERROR,
            "图片分享失败"
          )
        }
      }
      "shareVideos" -> {
        val act = activity
        if (act == null) {
          result.error("NO_ACTIVITY", "Activity is null. Ensure plugin is attached to an Activity.", null)
          return
        }
        val args = call.arguments as? Map<*, *> ?: run {
          result.error("BAD_ARGS", "Arguments must be a map.", null); return
        }
        try {
          val media = (args["media"] as? List<*>)?.map { it.toString() } ?: emptyList()
          if (media.isEmpty()) {
            result.error("BAD_ARGS", "media list cannot be empty.", null); return
          }
          val shareId = args["shareId"] as? String
          val microAppInfoMap = args["microAppInfo"] as? Map<*, *>
          val hashTags = (args["hashTags"] as? List<*>)?.map { it.toString() }
          val newShare = args["newShare"] as? Boolean ?: false
          val shareToPublish = args["shareToPublish"] as? Boolean ?: false
          val shareParamMap = args["shareParam"] as? Map<*, *>

          val request = Share.Request()
          // 普通分享不设置shareToType，只有发日常才设置为1
          request.mMediaContent = MediaContent().apply {
            mMediaObject = VideoObject().apply {
              mVideoPaths = ArrayList<String>().apply { addAll(convertPathsWithProvider(act, media)) }
            }
          }
          shareId?.let { request.mState = it }
          microAppInfoMap?.let { request.mMicroAppInfo = buildMicroAppInfo(it) }
          hashTags?.let { request.mHashTagList = ArrayList<String>().apply { addAll(it) } }
          request.newShare = newShare
          shareParamMap?.let { request.shareParam = buildShareParam(act, it, media) }
          request.callerLocalEntry = DyOpenSdkCallbackActivity::class.java.canonicalName

          val api = DouYinOpenApiFactory.create(act)
          if (api != null) {
            // 若请求直达发布页，仅支持单视频且需抖音版本支持
            if (shareToPublish) {
              if (media.size == 1 && api.isAppSupportShareToPublish()) {
                request.shareToPublish = true
                android.util.Log.d("DyOpenSdk", "启用shareToPublish，直接到发布页")
              } else {
                android.util.Log.w(
                  "DyOpenSdk",
                  "shareToPublish 条件不满足（仅支持单视频且抖音版本需>=14.8.0），已回退到编辑页"
                )
              }
            }
            // 保存pending result以便回调时使用
            pendingShareResult = result
            api.share(request)
          } else {
            result.error("API_ERROR", "无法创建抖音API实例，请检查是否已安装抖音", null)
          }
        } catch (e: Exception) {
          result.error("SHARE_ERROR", e.message, null)
        }
      }
      // === Android-only APIs mirrored from official demo ===
      "shareDaily" -> {
        val act = activity
        if (act == null) { result.error("NO_ACTIVITY", "Activity is null.", null); return }
        val args = call.arguments as? Map<*, *> ?: run {
          result.error("BAD_ARGS", "Arguments must be a map.", null); return
        }
        try {
          val media = args["media"] as? String
          val mediaType = (args["mediaType"] as? String)?.lowercase()
          if (media.isNullOrEmpty() || mediaType.isNullOrEmpty()) {
            result.error("BAD_ARGS", "media and mediaType(image|video) are required.", null); return
          }
          val shareId = args["shareId"] as? String
          val microAppInfoMap = args["microAppInfo"] as? Map<*, *>
          val hashTags = (args["hashTags"] as? List<*>)?.map { it.toString() }
          val newShare = args["newShare"] as? Boolean ?: true
          val shareParamMap = args["shareParam"] as? Map<*, *>

          val request = Share.Request()
          request.mMediaContent = MediaContent().apply {
            mMediaObject = if (mediaType == "image") {
              ImageObject().also {
                val paths = ArrayList<String>()
                ensureProviderPath(act, media)?.let { paths.add(it) }
                it.mImagePaths = paths
              }
            } else {
              VideoObject().also {
                val paths = ArrayList<String>()
                ensureProviderPath(act, media)?.let { paths.add(it) }
                it.mVideoPaths = paths
              }
            }
          }
          request.shareToType = 1
          shareId?.let { request.mState = it }
          microAppInfoMap?.let { request.mMicroAppInfo = buildMicroAppInfo(it) }
          hashTags?.let { request.mHashTagList = ArrayList<String>().apply { addAll(it) } }
          request.newShare = newShare
          shareParamMap?.let { request.shareParam = buildShareParam(act, it, listOf(media)) }
          request.callerLocalEntry = DyOpenSdkCallbackActivity::class.java.canonicalName

          val api = DouYinOpenApiFactory.create(act)
          if (api.isSupportApi(CommonConstants.SUPPORT.SHARE, CommonConstants.SUPPORT.SHARE_API.SHARE_DAILY)) {
            // 保存pending result以便回调时使用
            pendingShareResult = result
            api.share(request)
          } else {
            result.error("UNSUPPORTED_DAILY", "当前抖音版本不支持发日常", null)
          }
        } catch (e: Exception) {
          result.error("SHARE_DAILY_ERROR", e.message, null)
        }
      }
      "shareImageToIm" -> {
        val act = activity
        if (act == null) { result.error("NO_ACTIVITY", "Activity is null.", null); return }
        val args = call.arguments as? Map<*, *> ?: run {
          result.error("BAD_ARGS", "Arguments must be a map.", null); return
        }
        try {
          val media = args["media"] as? String
          if (media.isNullOrEmpty()) {
            result.error("BAD_ARGS", "media is required.", null); return
          }
          val shareId = args["shareId"] as? String

          val request = ShareToContact.Request()
          shareId?.let { request.mState = it }
          request.mMediaContent = MediaContent().apply {
            mMediaObject = ImageObject().apply {
              val path = ensureProviderPath(act, media) ?: media
              mImagePaths = arrayListOf(path)
            }
          }
          request.callerLocalEntry = DyOpenSdkCallbackActivity::class.java.canonicalName
          val api = DouYinOpenApiFactory.create(act)
          if (api.isAppSupportShareToContacts) {
            // 保存pending result以便回调时使用
            pendingShareToContactResult = result
            api.shareToContacts(request)
          } else {
            result.error("UNSUPPORTED_CONTACTS", "当前抖音版本不支持分享给好友", null)
          }
        } catch (e: Exception) {
          result.error("SHARE_IM_ERROR", e.message, null)
        }
      }
      "shareHtmlToIm" -> {
        val act = activity
        if (act == null) { result.error("NO_ACTIVITY", "Activity is null.", null); return }
        val args = call.arguments as? Map<*, *> ?: run {
          result.error("BAD_ARGS", "Arguments must be a map.", null); return
        }
        try {
          val html = args["htmlObject"] as? Map<*, *>
          if (html == null) { result.error("BAD_ARGS", "htmlObject is required.", null); return }
          val title = html["title"] as? String
          // Accept both "description" and legacy "discription" from caller, map to SDK's ContactHtmlObject.discription
          val description = (html["description"] as? String) ?: (html["discription"] as? String)
          // Accept both "html" (preferred) and fallback "url" from caller, map to SDK's ContactHtmlObject.html
          val urlOrHtml = (html["html"] as? String) ?: (html["url"] as? String)
          // Accept both "thumbUrl" (preferred) and fallback "coverUrl" from caller, map to SDK's ContactHtmlObject.thumbUrl
          val thumb = (html["thumbUrl"] as? String) ?: (html["coverUrl"] as? String)
          val shareId = args["shareId"] as? String

          val obj = ContactHtmlObject().apply {
            title?.let { this.title = it }
            description?.let { this.discription = it }
            urlOrHtml?.let { this.html = it }
            thumb?.let { this.thumbUrl = it }
          }
          val request = ShareToContact.Request()
          request.htmlObject = obj
          shareId?.let { request.mState = it }
          request.callerLocalEntry = DyOpenSdkCallbackActivity::class.java.canonicalName

          val api = DouYinOpenApiFactory.create(act)
          if (api.isAppSupportShareToContacts) {
            // 保存pending result以便回调时使用
            pendingShareToContactResult = result
            api.shareToContacts(request)
          } else {
            result.error("UNSUPPORTED_CONTACTS", "当前抖音版本不支持分享给好友", null)
          }
        } catch (e: Exception) {
          result.error("SHARE_HTML_IM_ERROR", e.message, null)
        }
      }
      "openRecord" -> {
        val act = activity
        if (act == null) { result.error("NO_ACTIVITY", "Activity is null.", null); return }
        val args = call.arguments as? Map<*, *> ?: run {
          result.error("BAD_ARGS", "Arguments must be a map.", null); return
        }
        try {
          val shareId = args["shareId"] as? String
          val microAppInfoMap = args["microAppInfo"] as? Map<*, *>
          val hashTags = (args["hashTags"] as? List<*>)?.map { it.toString() }
          val shareParamMap = args["shareParam"] as? Map<*, *>

          val request = OpenRecord.Request()
          shareId?.let { request.mState = it }
          microAppInfoMap?.let { request.mMicroAppInfo = buildMicroAppInfo(it) }
          hashTags?.let { request.mHashTagList = ArrayList<String>().apply { addAll(it) } }
          shareParamMap?.let { request.shareParam = buildShareParam(act, it, emptyList()) }
          request.callerLocalEntry = DyOpenSdkCallbackActivity::class.java.canonicalName

          val api = DouYinOpenApiFactory.create(act)
          if (api.isSupportOpenRecordPage) {
            // 保存pending result以便回调时使用
            pendingOpenRecordResult = result
            api.openRecordPage(request)
          } else {
            result.error("UNSUPPORTED_RECORD", "当前抖音版本不支持拉起拍摄页", null)
          }
        } catch (e: Exception) {
          result.error("OPEN_RECORD_ERROR", e.message, null)
        }
      }
      "authorize" -> {
        val act = activity
        if (act == null) { result.error("NO_ACTIVITY", "Activity is null.", null); return }
        val args = call.arguments as? Map<*, *> ?: run {
          result.error("BAD_ARGS", "Arguments must be a map.", null); return
        }
        try {
          val scope = args["scope"] as? String ?: "user_info"
          val state = args["state"] as? String ?: UUID.randomUUID().toString()
          
          // 保存当前的授权请求结果回调
          pendingAuthResult = result
          authState = state
          
          val request = Authorization.Request()
          request.scope = scope
          request.state = state
          request.callerLocalEntry = DyOpenSdkCallbackActivity::class.java.canonicalName
          
          val api = DouYinOpenApiFactory.create(act)
          api?.authorize(request)
          
          // 不立即返回结果，等待授权回调
        } catch (e: Exception) {
          result.error("AUTH_ERROR", e.message, null)
        }
      }
      "isDouyinInstalled" -> {
        try {
          val context = applicationContext ?: activity?.applicationContext
          if (context == null) {
            result.success(false)
            return
          }
          val packageManager = context.packageManager
          val isDouyinInstalled = try {
            packageManager.getPackageInfo("com.ss.android.ugc.aweme", 0)
            true
          } catch (e: Exception) {
            false
          }
          val isDouyinLiteInstalled = try {
            packageManager.getPackageInfo("com.ss.android.ugc.aweme.lite", 0)
            true
          } catch (e: Exception) {
            false
          }
          result.success(isDouyinInstalled || isDouyinLiteInstalled)
        } catch (e: Exception) {
          result.success(false)
        }
      }
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    applicationContext = null
    instance = null
  }

  // ActivityAware implementations
  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    this.activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    this.activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    this.activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    this.activity = null
  }

  // 处理授权回调
  fun handleAuthResponse(response: Authorization.Response) {
    val result = pendingAuthResult
    if (result != null) {
      try {
        if (response.isSuccess) {
          val authResult = mapOf(
            "success" to true,
            "authCode" to response.authCode,
            "grantedPermissions" to response.grantedPermissions,
            "state" to response.state
          )
          result.success(authResult)
        } else {
          result.error("AUTH_FAILED", "Authorization failed: ${response.errorMsg}", mapOf(
            "errorCode" to response.errorCode,
            "errorMsg" to response.errorMsg,
          ))
        }
      } catch (e: Exception) {
        result.error("AUTH_CALLBACK_ERROR", e.message, null)
      } finally {
        pendingAuthResult = null
        authState = null
      }
    }
  }

  // 处理分享回调
  fun handleShareResponse(response: Share.Response) {
    val result = pendingShareResult
    if (result != null) {
      try {
        if (response.errorCode == 0) {
          val shareResult = mapOf(
            "success" to true,
            "errorCode" to response.errorCode,
            "subErrorCode" to response.subErrorCode,
            "errorMsg" to (response.errorMsg ?: ""),
            "state" to (response.state ?: "")
          )
          result.success(shareResult)
          android.util.Log.d("DyOpenSdk", "分享成功: $shareResult")
        } else {
          result.error("SHARE_FAILED", "Share failed: ${response.errorMsg}", mapOf(
            "errorCode" to response.errorCode,
            "subErrorCode" to response.subErrorCode,
            "errorMsg" to (response.errorMsg ?: ""),
            "state" to (response.state ?: "")
          ))
          android.util.Log.d("DyOpenSdk", "分享失败: errorCode=${response.errorCode}, errorMsg=${response.errorMsg}")
        }
      } catch (e: Exception) {
        result.error("SHARE_CALLBACK_ERROR", e.message, null)
        android.util.Log.e("DyOpenSdk", "分享回调处理异常", e)
      } finally {
        pendingShareResult = null
      }
    } else {
      android.util.Log.w("DyOpenSdk", "收到分享回调但没有pending result")
    }
  }

  // 处理分享到好友回调
  fun handleShareToContactResponse(response: ShareToContact.Response) {
    val result = pendingShareToContactResult
    if (result != null) {
      try {
        if (response.errorCode == 0) {
          val shareResult = mapOf(
            "success" to true,
            "errorCode" to response.errorCode,
            "errorMsg" to (response.errorMsg ?: ""),
          )
          result.success(shareResult)
          android.util.Log.d("DyOpenSdk", "分享到好友成功: $shareResult")
        } else {
          result.error("SHARE_TO_CONTACT_FAILED", "Share to contact failed: ${response.errorMsg}", mapOf(
            "errorCode" to response.errorCode,
            "errorMsg" to (response.errorMsg ?: "")
          ))
          android.util.Log.d("DyOpenSdk", "分享到好友失败: errorCode=${response.errorCode}, errorMsg=${response.errorMsg}")
        }
      } catch (e: Exception) {
        result.error("SHARE_TO_CONTACT_CALLBACK_ERROR", e.message, null)
        android.util.Log.e("DyOpenSdk", "分享到好友回调处理异常", e)
      } finally {
        pendingShareToContactResult = null
      }
    } else {
      android.util.Log.w("DyOpenSdk", "收到分享到好友回调但没有pending result")
    }
  }

  // 处理拍摄页回调
  fun handleOpenRecordResponse(response: OpenRecord.Response) {
    val result = pendingOpenRecordResult
    if (result != null) {
      try {
        if (response.errorCode == 0) {
          val recordResult = mapOf(
            "success" to true,
            "errorCode" to response.errorCode,
            "errorMsg" to (response.errorMsg ?: ""),
            "state" to (response.state ?: "")
          )
          result.success(recordResult)
          android.util.Log.d("DyOpenSdk", "拍摄页操作成功: $recordResult")
        } else {
          result.error("OPEN_RECORD_FAILED", "Open record failed: ${response.errorMsg}", mapOf(
            "errorCode" to response.errorCode,
            "errorMsg" to (response.errorMsg ?: ""),
            "state" to (response.state ?: "")
          ))
          android.util.Log.d("DyOpenSdk", "拍摄页操作失败: errorCode=${response.errorCode}, errorMsg=${response.errorMsg}")
        }
      } catch (e: Exception) {
        result.error("OPEN_RECORD_CALLBACK_ERROR", e.message, null)
        android.util.Log.e("DyOpenSdk", "拍摄页回调处理异常", e)
      } finally {
        pendingOpenRecordResult = null
      }
    } else {
      android.util.Log.w("DyOpenSdk", "收到拍摄页回调但没有pending result")
    }
  }

  // Helpers
  private fun buildMicroAppInfo(map: Map<*, *>): MicroAppInfo {
    val info = MicroAppInfo()
    (map["appId"] as? String)?.let { info.appId = it }
    (map["appTitle"] as? String)?.let { info.appTitle = it }
    (map["appUrl"] as? String)?.let { info.appUrl = it }
    (map["description"] as? String)?.let { info.description = it }
    return info
  }

  private fun buildShareParam(context: Context, map: Map<*, *>, media: List<String>): ShareParam {
    val param = ShareParam()
    val titleObj = TitleObject()
    (map["titleObject"] as? Map<*, *>)?.let { tMap ->
      (tMap["title"] as? String)?.let { titleObj.title = it }
      // 新增：支持短标题（抖音 30.0.0+ 支持 shortTitle）
      (tMap["shortTitle"] as? String)?.let { titleObj.shortTitle = it }
      (tMap["markers"] as? List<*>)?.forEach { marker ->
        val m = marker as? Map<*, *> ?: return@forEach
        when (m["type"]) {
          "hashtag" -> {
            val ht = HashtagTitleMarker()
            (m["name"] as? String)?.let { ht.name = it }
            val start = (m["start"] as? Number)?.toInt() ?: 0
            ht.start = start
            titleObj.addMarker(ht)
          }
          "mention" -> {
            val mt = MentionTitleMarker()
            (m["openId"] as? String)?.let { mt.openId = it }
            val start = (m["start"] as? Number)?.toInt() ?: 0
            mt.start = start
            titleObj.addMarker(mt)
          }
        }
      }
    }
    param.titleObject = titleObj

    (map["stickersObject"] as? Map<*, *>)?.let { sMap ->
      val stickers = StickersObject()
      (sMap["stickers"] as? List<*>)?.forEach { s ->
        val sm = s as? Map<*, *> ?: return@forEach
        when (sm["type"]) {
          "hashtag" -> {
            val hs = HashtagSticker()
            (sm["name"] as? String)?.let { hs.name = it }
            stickers.addSticker(hs)
          }
          "mention" -> {
            val ms = MentionSticker()
            (sm["openId"] as? String)?.let { ms.openId = it }
            stickers.addSticker(ms)
          }
          "custom" -> {
            val cs = CustomSticker()
            val path = (sm["path"] as? String)
            val uriStr = (sm["uri"] as? String)
            val stickerPath = when {
              path != null -> ensureProviderPath(context, path)
              uriStr != null -> ensureProviderPath(context, uriStr)
              media.isNotEmpty() -> ensureProviderPath(context, media.first())
              else -> null
            }
            stickerPath?.let { cs.path = it }
            (sm["startTime"] as? Number)?.let { cs.startTime = it.toInt() }
            (sm["endTime"] as? Number)?.let { cs.endTime = it.toInt() }
            (sm["offsetX"] as? Number)?.let { cs.offsetX = it.toFloat() }
            (sm["offsetY"] as? Number)?.let { cs.offsetY = it.toFloat() }
            (sm["normalizedSizeX"] as? Number)?.let { cs.normalizedSizeX = it.toFloat() }
            (sm["normalizedSizeY"] as? Number)?.let { cs.normalizedSizeY = it.toFloat() }
            stickers.addSticker(cs)
          }
        }
      }
      param.stickersObject = stickers
    }

    (map["poiId"] as? String)?.let { param.poiId = it }
    return param
  }

  private fun convertPathsWithProvider(context: Context, list: List<String>): List<String> {
    val out = ArrayList<String>()
    list.forEach { s -> out.add(ensureProviderPath(context, s) ?: s) }
    return out
  }

  private fun ensureProviderPath(context: Context, input: String): String? {
    return try {
      android.util.Log.d("DyOpenSdk", "Processing file path: $input")
      val uri = Uri.parse(input)
      val result = if (uri.scheme == "content") {
        copyFile(context, uri)
      } else {
        val file = if (uri.scheme == "file") File(uri.path!!) else File(input)
        if (!file.exists()) {
          android.util.Log.e("DyOpenSdk", "File does not exist: ${file.absolutePath}")
          return null
        }
        shareWithProvider(context, file)
      }
      android.util.Log.d("DyOpenSdk", "Converted to provider path: $result")
      result
    } catch (e: Exception) {
      android.util.Log.e("DyOpenSdk", "Error processing file path: $input", e)
      null
    }
  }

  private fun copyFile(context: Context, uri: Uri): String {
    val suffix = run {
      val name = uri.lastPathSegment ?: "tmp"
      val idx = name.lastIndexOf('.')
      if (idx != -1 && idx < name.length - 1) name.substring(idx + 1) else "tmp"
    }
    val shareDirectory = File(context.getExternalFilesDir(null), "/dy_open_share")
    if (!shareDirectory.exists()) {
      shareDirectory.mkdir()
    }
    val tempFile = File.createTempFile("share_", ".${suffix}", shareDirectory)
    tempFile.deleteOnExit()
    context.contentResolver.openInputStream(uri)?.use { input ->
      FileOutputStream(tempFile).use { output ->
        input.copyTo(output)
      }
    }
    return shareWithProvider(context, tempFile)
  }

  private fun shareWithProvider(context: Context, file: File): String {
    val candidates = mutableListOf<String>()
    val pkg = context.packageName
    // 1) Try to discover provider authority declared by host app
    try {
      val pm = context.packageManager
      @Suppress("DEPRECATION")
      val pi = pm.getPackageInfo(pkg, android.content.pm.PackageManager.GET_PROVIDERS)
      val providers = pi.providers
      providers?.forEach { p ->
        if (p != null && p.name == FileProvider::class.java.name && p.authority?.startsWith(pkg) == true) {
          candidates.add(p.authority)
        }
      }
    } catch (_: Exception) {
    }
    // 2) Common conventions
    candidates.add("$pkg.fileProvider")
    candidates.add("$pkg.fileprovider")
    candidates.add("$pkg.provider")
    candidates.add("$pkg.dyopen.fileprovider") // backward compatibility

    var lastError: Exception? = null
    for (auth in candidates.distinct()) {
      try {
        val uri = FileProvider.getUriForFile(context, auth, file)
        // Grant read to Douyin
        context.grantUriPermission("com.ss.android.ugc.aweme", uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        context.grantUriPermission("com.ss.android.ugc.aweme.lite", uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        return uri.toString()
      } catch (e: Exception) {
        lastError = e
      }
    }
    // If no authority worked, rethrow the last error for visibility
    throw lastError ?: IllegalStateException("No valid FileProvider authority found in host app.")
  }
}
