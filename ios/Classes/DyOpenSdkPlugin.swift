import DouyinOpenSDK
import Flutter
import UIKit

public class DyOpenSdkPlugin: NSObject, FlutterPlugin {

  // MARK: - Constants
  private struct Constants {
    static let defaultScope = "user_info"

    struct ErrorCode {
      static let badArgs = "BAD_ARGS"
      static let notInitialized = "NOT_INITIALIZED"
      static let noViewController = "NO_VIEW_CONTROLLER"
      static let shareError = "SHARE_ERROR"
      static let authError = "AUTH_ERROR"
    }

    struct ErrorMessage {
      static let argumentsRequired = "Arguments must be a map."
      static let clientKeyRequired = "clientKey is required."
      static let sdkNotInitialized = "SDK not initialized. Please call initialize first."
      static let mediaListEmpty = "Media list cannot be empty."
      static let noViewController = "Cannot find root view controller."
      static let authorizationFailed = "Authorization failed"
      static let shareFailed = "Share failed"
    }

    // MARK: - Helper Methods
    static func createSuccessResponse(message: String? = nil, data: [String: Any]? = nil)
      -> [String: Any]
    {
      var response: [String: Any] = ["success": true]
      if let message = message {
        response["message"] = message
      }
      if let data = data {
        response.merge(data) { _, new in new }
      }
      return response
    }

    static func createFailureResponse(errorCode: Int, errorMessage: String) -> [String: Any] {
      return [
        "success": false,
        "errorCode": errorCode,
        "errorMsg": errorMessage,
      ]
    }
  }
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "dy_open_sdk", binaryMessenger: registrar.messenger())
    let instance = DyOpenSdkPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "getSDKVersion":
      // Fix: Handle optional return value properly
      let version = DouyinOpenSDKApplicationDelegate.sharedInstance().currentVersion
      result(version ?? "Unknown")
    case "initialize":
      initialize(call: call, result: result)
    case "authorize":
      authorize(call: call, result: result)
    case "isDouyinInstalled":
      isDouyinInstalled(result: result)
    case "shareImages":
      guard let args = call.arguments as? [String: Any] else {
        result(
          FlutterError(
            code: Constants.ErrorCode.badArgs, message: Constants.ErrorMessage.argumentsRequired,
            details: nil))
        return
      }
      shareImages(args: args, result: result)
    case "shareVideos":
      guard let args = call.arguments as? [String: Any] else {
        result(
          FlutterError(
            code: Constants.ErrorCode.badArgs, message: Constants.ErrorMessage.argumentsRequired,
            details: nil))
        return
      }
      shareVideos(args: args, result: result)
    // Android专用方法在iOS端返回不支持错误
    case "shareDaily", "shareImageToIm", "shareHtmlToIm", "openRecord":
      result(
        FlutterError(
          code: "UNSUPPORTED", message: "This method is only supported on Android.", details: nil))
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Initialize
  private func initialize(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(
        FlutterError(
          code: Constants.ErrorCode.badArgs, message: Constants.ErrorMessage.argumentsRequired,
          details: nil))
      return
    }
    guard let clientKey = args["clientKey"] as? String, !clientKey.isEmpty else {
      result(
        FlutterError(
          code: Constants.ErrorCode.badArgs, message: Constants.ErrorMessage.clientKeyRequired,
          details: nil))
      return
    }

    // Register app id (clientKey)
    DouyinOpenSDKApplicationDelegate.sharedInstance().registerAppId(clientKey)
    result(Constants.createSuccessResponse(message: "SDK initialized successfully"))
  }

  // MARK: - Authorization
  private func authorize(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(
        FlutterError(
          code: Constants.ErrorCode.badArgs, message: Constants.ErrorMessage.argumentsRequired,
          details: nil))
      return
    }

    // Check if SDK is initialized - Fix: Handle optional appId properly
    let appId = DouyinOpenSDKApplicationDelegate.sharedInstance().appId()
    guard let appId = appId, !appId.isEmpty else {
      result(
        FlutterError(
          code: Constants.ErrorCode.notInitialized,
          message: Constants.ErrorMessage.sdkNotInitialized,
          details: nil))
      return
    }

    let scope = args["scope"] as? String ?? Constants.defaultScope
    let state = args["state"] as? String

    let request = DouyinOpenSDKAuthRequest()
    request.permissions = NSOrderedSet(object: scope)
    if let state = state {
      request.state = state
    }

    // Get the root view controller
    guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else {
      result(
        FlutterError(
          code: Constants.ErrorCode.noViewController,
          message: Constants.ErrorMessage.noViewController, details: nil))
      return
    }

    // Fix: Use updated method name for sending auth request
    request.send(rootViewController) { response in
      // Fix: Handle optional response properly
      guard let response = response else {
        result(
          FlutterError(
            code: Constants.ErrorCode.authError,
            message: Constants.ErrorMessage.authorizationFailed,
            details: nil))
        return
      }

      // Fix: Convert DouyinOpenSDKErrorCode to Int properly
      if response.errCode.rawValue == 0 {
        result([
          "success": true,
          "code": response.code ?? "",
          "grantedPermissions": Array(response.grantedPermissions ?? []),
          "state": response.state ?? "",
        ])
      } else {
        result(
          FlutterError(
            code: Constants.ErrorCode.authError,
            message: response.errString ?? Constants.ErrorMessage.authorizationFailed,
            details: ["errorCode": response.errCode.rawValue]))
      }
    }
  }

  // MARK: - Check Installation
  private func isDouyinInstalled(result: @escaping FlutterResult) {
    let isInstalled = DouyinOpenSDKApplicationDelegate.sharedInstance().isAppInstalled()
    result(isInstalled)
  }

  // MARK: - Share Images
  private func shareImages(args: [String: Any], result: @escaping FlutterResult) {
    // Check if SDK is initialized - Fix: Handle optional appId properly
    let appId = DouyinOpenSDKApplicationDelegate.sharedInstance().appId()
    guard let appId = appId, !appId.isEmpty else {
      result(
        FlutterError(
          code: Constants.ErrorCode.notInitialized,
          message: Constants.ErrorMessage.sdkNotInitialized, details: nil))
      return
    }

    let media = (args["media"] as? [String]) ?? []
    guard !media.isEmpty else {
      result(
        FlutterError(
          code: Constants.ErrorCode.badArgs, message: Constants.ErrorMessage.mediaListEmpty,
          details: nil))
      return
    }

    let shareId = args["shareId"] as? String
    let microAppInfo = args["microAppInfo"] as? [String: Any]
    let shareParam = args["shareParam"] as? [String: Any]
    let hashTags = args["hashTags"] as? [String]
    let shareToPublish = args["shareToPublish"] as? Bool ?? false

    // iOS 不支持 isAlbum/newShare，这里仅保持参数一致但不使用
    let req = DouyinOpenSDKShareRequest()
    req.localIdentifiers = media
    req.mediaType = .image
    if let shareId = shareId { req.state = shareId }
    // 控制落地页类型：编辑页或发布页
    req.landedPageType = shareToPublish ? .publish : .edit

    // 构建extraInfo
    var extra: [String: Any] = [:]
    if let mp = microAppInfo {
      extra["mpInfo"] = mp
    }
    if let sp = shareParam {
      if let pei = sp["productExtraInfo"] as? [String: Any] {
        extra["product_extra_info"] = pei
      } else if let pei = sp["product_extra_info"] as? [String: Any] {
        extra["product_extra_info"] = pei
      }
    }
    // iOS端支持hashTags（虽然Demo中注释了，但SDK支持）
    if let tags = hashTags, !tags.isEmpty {
      extra["hashtag_list"] = tags
    }
    if !extra.isEmpty { req.extraInfo = extra }

    // Fix: Use correct method name for sending share request
    req.send { resp in
      print(resp)
      if resp.isSucceed {
        result(Constants.createSuccessResponse(message: "Images shared successfully"))
      } else {
        var details: [String: Any] = [:]
        details["errorCode"] = resp.errCode.rawValue
        details["errorMessage"] = resp.errString
        details["subErrorCode"] = resp.subErrorCode
        result(
          FlutterError(
            code: Constants.ErrorCode.shareError,
            message: Constants.ErrorMessage.shareFailed,
            details: details))
      }
    }
  }

  // MARK: - Share Videos
  private func shareVideos(args: [String: Any], result: @escaping FlutterResult) {
    // Check if SDK is initialized - Fix: Handle optional appId properly
    let appId = DouyinOpenSDKApplicationDelegate.sharedInstance().appId()
    guard let appId = appId, !appId.isEmpty else {
      result(
        FlutterError(
          code: Constants.ErrorCode.notInitialized,
          message: Constants.ErrorMessage.sdkNotInitialized, details: nil))
      return
    }

    let media = (args["media"] as? [String]) ?? []
    guard !media.isEmpty else {
      result(
        FlutterError(
          code: Constants.ErrorCode.badArgs, message: Constants.ErrorMessage.mediaListEmpty,
          details: nil))
      return
    }

    let shareId = args["shareId"] as? String
    let microAppInfo = args["microAppInfo"] as? [String: Any]
    let shareParam = args["shareParam"] as? [String: Any]
    let hashTags = args["hashTags"] as? [String]
    let shareToPublish = args["shareToPublish"] as? Bool ?? false

    let req = DouyinOpenSDKShareRequest()
    req.localIdentifiers = media
    req.mediaType = .video
    if let shareId = shareId { req.state = shareId }
    // 控制落地页类型：编辑页或发布页
    req.landedPageType = shareToPublish ? .publish : .edit

    // 构建extraInfo
    var extra: [String: Any] = [:]
    if let mp = microAppInfo {
      extra["mpInfo"] = mp
    }
    if let sp = shareParam {
      if let pei = sp["productExtraInfo"] as? [String: Any] {
        extra["product_extra_info"] = pei
      } else if let pei = sp["product_extra_info"] as? [String: Any] {
        extra["product_extra_info"] = pei
      }
    }
    // iOS端支持hashTags
    if let tags = hashTags, !tags.isEmpty {
      extra["hashtag_list"] = tags
    }
    if !extra.isEmpty { req.extraInfo = extra }

    // Fix: Use correct method name for sending share request
    req.send { resp in
      print(resp)
      if resp.isSucceed {
        result(Constants.createSuccessResponse(message: "Videos shared successfully"))
      } else {
        var details: [String: Any] = [:]
        details["errorCode"] = resp.errCode.rawValue
        details["errorMessage"] = resp.errString
        details["subErrorCode"] = resp.subErrorCode

        result(
          FlutterError(
            code: Constants.ErrorCode.shareError,
            message: Constants.ErrorMessage.shareFailed,
            details: details))
      }
    }
  }
}
