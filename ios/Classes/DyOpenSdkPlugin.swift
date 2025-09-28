import Flutter
import UIKit
import DouyinOpenSDK

public class DyOpenSdkPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "dy_open_sdk", binaryMessenger: registrar.messenger())
    let instance = DyOpenSdkPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
  
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "initialize":
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "BAD_ARGS", message: "Arguments must be a map.", details: nil))
        return
      }
      guard let clientKey = args["clientKey"] as? String, !clientKey.isEmpty else {
        result(FlutterError(code: "BAD_ARGS", message: "clientKey is required.", details: nil))
        return
      }
      // Optional debug flag ignored on iOS for now
      // let debug = args["debug"] as? Bool ?? false
      // Register app id (clientKey)
      DouyinOpenSDKApplicationDelegate.sharedInstance().registerAppId(clientKey)
      result(["success": true])
    case "shareImages":
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "BAD_ARGS", message: "Arguments must be a map.", details: nil))
        return
      }
      shareImages(args: args, result: result)
    case "shareVideos":
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "BAD_ARGS", message: "Arguments must be a map.", details: nil))
        return
      }
      shareVideos(args: args, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func shareImages(args: [String: Any], result: @escaping FlutterResult) {
    let media = (args["media"] as? [String]) ?? []
    let shareId = args["shareId"] as? String
    let microAppInfo = args["microAppInfo"] as? [String: Any]
    let shareParam = args["shareParam"] as? [String: Any]
    // iOS 不支持 isAlbum/newShare/hashTags，这里仅保持参数一致但不使用
    let req = DouyinOpenSDKShareRequest()
    req.localIdentifiers = media
    req.mediaType = .image
    if let shareId = shareId { req.state = shareId }
    var extra: [String: Any] = [:]
    if let mp = microAppInfo { extra["mpInfo"] = mp }
    if let sp = shareParam {
      if let pei = sp["productExtraInfo"] as? [String: Any] {
        extra["product_extra_info"] = pei
      } else if let pei = sp["product_extra_info"] as? [String: Any] {
        extra["product_extra_info"] = pei
      }
    }
    if !extra.isEmpty { req.extraInfo = extra }
    req.sendShareRequest { resp in
      if resp.isSucceed {
        result(["success": true])
      } else {
        result(["success": false, "errorCode": resp.errorCode ?? -1, "errorMsg": resp.errorString ?? ""]) 
      }
    }
  }
  
  private func shareVideos(args: [String: Any], result: @escaping FlutterResult) {
    let media = (args["media"] as? [String]) ?? []
    let shareId = args["shareId"] as? String
    let microAppInfo = args["microAppInfo"] as? [String: Any]
    let shareParam = args["shareParam"] as? [String: Any]
    let req = DouyinOpenSDKShareRequest()
    req.localIdentifiers = media
    req.mediaType = .video
    if let shareId = shareId { req.state = shareId }
    var extra: [String: Any] = [:]
    if let mp = microAppInfo { extra["mpInfo"] = mp }
    if let sp = shareParam {
      if let pei = sp["productExtraInfo"] as? [String: Any] {
        extra["product_extra_info"] = pei
      } else if let pei = sp["product_extra_info"] as? [String: Any] {
        extra["product_extra_info"] = pei
      }
    }
    if !extra.isEmpty { req.extraInfo = extra }
    req.sendShareRequest { resp in
      if resp.isSucceed {
        result(["success": true])
      } else {
        result(["success": false, "errorCode": resp.errorCode ?? -1, "errorMsg": resp.errorString ?? ""]) 
      }
    }
  }
}
