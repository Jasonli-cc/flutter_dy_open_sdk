package com.plugins.dy_open_sdk

import io.flutter.plugin.common.MethodChannel

/**
 * 抖音开放平台SDK统一异常处理
 * 定义标准的错误码和异常类型，便于Flutter端统一处理
 */
object DyOpenSdkException {

    /**
     * 错误码定义
     */
    object ErrorCode {
        // 初始化相关错误
        const val INIT_ERROR = "INIT_ERROR"
        const val NO_CONTEXT = "NO_CONTEXT"
        const val INVALID_CLIENT_KEY = "INVALID_CLIENT_KEY"
        
        // Activity相关错误
        const val NO_ACTIVITY = "NO_ACTIVITY"
        const val ACTIVITY_DESTROYED = "ACTIVITY_DESTROYED"
        
        // 参数相关错误
        const val BAD_ARGS = "BAD_ARGS"
        const val MISSING_REQUIRED_PARAM = "MISSING_REQUIRED_PARAM"
        const val INVALID_PARAM_TYPE = "INVALID_PARAM_TYPE"
        const val EMPTY_MEDIA_LIST = "EMPTY_MEDIA_LIST"
        
        // 文件相关错误
        const val FILE_NOT_FOUND = "FILE_NOT_FOUND"
        const val FILE_ACCESS_DENIED = "FILE_ACCESS_DENIED"
        const val FILE_COPY_FAILED = "FILE_COPY_FAILED"
        const val INVALID_FILE_PATH = "INVALID_FILE_PATH"
        const val PROVIDER_URI_FAILED = "PROVIDER_URI_FAILED"
        
        // API相关错误
        const val API_ERROR = "API_ERROR"
        const val API_NOT_SUPPORTED = "API_NOT_SUPPORTED"
        const val DOUYIN_NOT_INSTALLED = "DOUYIN_NOT_INSTALLED"
        const val SDK_NOT_INITIALIZED = "SDK_NOT_INITIALIZED"
        
        // 授权相关错误
        const val AUTH_ERROR = "AUTH_ERROR"
        const val AUTH_FAILED = "AUTH_FAILED"
        const val AUTH_CANCELLED = "AUTH_CANCELLED"
        const val AUTH_CALLBACK_ERROR = "AUTH_CALLBACK_ERROR"
        
        // 分享相关错误
        const val SHARE_ERROR = "SHARE_ERROR"
        const val SHARE_FAILED = "SHARE_FAILED"
        const val SHARE_CANCELLED = "SHARE_CANCELLED"
        const val SHARE_DAILY_ERROR = "SHARE_DAILY_ERROR"
        const val SHARE_IM_ERROR = "SHARE_IM_ERROR"
        const val SHARE_HTML_IM_ERROR = "SHARE_HTML_IM_ERROR"
        
        // 功能不支持错误
        const val UNSUPPORTED_DAILY = "UNSUPPORTED_DAILY"
        const val UNSUPPORTED_CONTACTS = "UNSUPPORTED_CONTACTS"
        const val UNSUPPORTED_RECORD = "UNSUPPORTED_RECORD"
        const val UNSUPPORTED_ALBUM = "UNSUPPORTED_ALBUM"
        
        // 拍摄页相关错误
        const val OPEN_RECORD_ERROR = "OPEN_RECORD_ERROR"
        
        // 网络相关错误
        const val NETWORK_ERROR = "NETWORK_ERROR"
        const val TIMEOUT_ERROR = "TIMEOUT_ERROR"
        
        // 未知错误
        const val UNKNOWN_ERROR = "UNKNOWN_ERROR"
    }

    /**
     * 异常类型定义
     */
    enum class ExceptionType(val code: String, val description: String) {
        INITIALIZATION("INIT", "SDK初始化异常"),
        PARAMETER("PARAM", "参数异常"),
        FILE_OPERATION("FILE", "文件操作异常"),
        API_CALL("API", "API调用异常"),
        AUTHORIZATION("AUTH", "授权异常"),
        SHARE("SHARE", "分享异常"),
        NETWORK("NETWORK", "网络异常"),
        UNKNOWN("UNKNOWN", "未知异常")
    }

    /**
     * 标准异常信息结构
     */
    data class ExceptionInfo(
        val type: ExceptionType,
        val code: String,
        val message: String,
        val details: Map<String, Any?>? = null,
        val cause: Throwable? = null
    )

    /**
     * 统一的异常处理方法
     */
    fun handleException(
        result: MethodChannel.Result,
        exception: Throwable,
        type: ExceptionType = ExceptionType.UNKNOWN,
        code: String = ErrorCode.UNKNOWN_ERROR,
        customMessage: String? = null
    ) {
        val message = customMessage ?: exception.message ?: "未知错误"
        val details = mutableMapOf<String, Any?>(
            "type" to type.code,
            "description" to type.description,
            "originalMessage" to exception.message,
            "stackTrace" to exception.stackTrace.take(5).map { it.toString() }
        )
        
        // 添加异常特定的详细信息
        when (exception) {
            is SecurityException -> {
                details["securityReason"] = "权限不足或安全限制"
            }
            is IllegalArgumentException -> {
                details["argumentError"] = "参数错误"
            }
            is NullPointerException -> {
                details["nullPointerReason"] = "空指针异常"
            }
        }

        android.util.Log.e("DyOpenSdk", "异常处理: type=${type.code}, code=$code, message=$message", exception)
        
        result.error(code, message, details)
    }

    /**
     * 快速创建参数错误
     */
    fun parameterError(result: MethodChannel.Result, message: String, paramName: String? = null) {
        val details = paramName?.let { mapOf("parameterName" to it) }
        result.error(ErrorCode.BAD_ARGS, message, details)
    }

    /**
     * 快速创建API不支持错误
     */
    fun apiNotSupportedError(result: MethodChannel.Result, apiName: String, reason: String) {
        val details = mapOf(
            "apiName" to apiName,
            "reason" to reason
        )
        result.error(ErrorCode.API_NOT_SUPPORTED, "API不支持: $apiName - $reason", details)
    }

    /**
     * 快速创建文件操作错误
     */
    fun fileOperationError(result: MethodChannel.Result, operation: String, filePath: String, cause: Throwable) {
        val details = mapOf(
            "operation" to operation,
            "filePath" to filePath,
            "cause" to cause.message
        )
        result.error(ErrorCode.FILE_ACCESS_DENIED, "文件操作失败: $operation - $filePath", details)
    }

    /**
     * 创建成功响应
     */
    fun success(result: MethodChannel.Result, data: Map<String, Any?> = mapOf("success" to true)) {
        result.success(data)
    }
}