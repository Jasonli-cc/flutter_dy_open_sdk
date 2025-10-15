# Dy Open SDK 使用文档（Android / iOS）

本文档基于当前插件实现与官方 SDK 使用习惯，说明在 Android 与 iOS 平台的集成与使用方式。

## 前置条件
- 已集成本插件（`dy_open_sdk`）到 Flutter 工程。
- 需要安装抖音或抖音极速版客户端，否则分享可能失败。
- Flutter 版本通过 FVM 管理，默认使用 Flutter 3.35.4。

## 快速开始
1) 初始化（应用启动后尽早调用）：
- 仅需提供 `clientKey`；`clientSecret` 当前不用于客户端 SDK 初始化（通常用于服务端安全流程）。
- Android 支持 `debug` 开关（iOS 忽略该开关）。

2) 分享：
- `shareImages` 与 `shareVideos` 分别用于图片与视频分享。
- Android 支持文件路径或 Content URI；iOS 必须使用 `PHAsset` 的 `localIdentifiers`。
 - 新增参数：`shareToPublish` 控制落地页（编辑页或发布页）。
   - iOS：完全支持，`true` 跳转到发布页，`false` 跳转到编辑页。
   - Android：仅支持单视频直达发布页，且需抖音客户端版本支持；图片分享会回退到编辑页。

## Dart API 概览
- 初始化：`DyOpenSdk.initialize({ required clientKey, String? clientSecret, bool debug = false, Map<String, dynamic>? options })`
- 图片分享：`DyOpenSdk.shareImages(...)`
- 视频分享：`DyOpenSdk.shareVideos(...)`

### 示例：控制分享到编辑页或发布页
```dart
// 分享视频，直接进入发布页（受Android端版本与单视频限制）
await DyOpenSdk().shareVideos(
  media: ['/path/to/video.mp4'],
  shareToPublish: true, // true=发布页，false=编辑页
);

// 分享图片，Android不支持直达发布页，自动回退到编辑页
await DyOpenSdk().shareImages(
  media: ['/path/to/image1.jpg', '/path/to/image2.jpg'],
  shareToPublish: false,
);
```

详细参数说明请参考库内以下文件：
- <mcfile name="dy_open_sdk_platform_interface.dart" path="/Users/lichaochao/dy_open_sdk/lib/dy_open_sdk_platform_interface.dart"></mcfile>
- <mcfile name="dy_open_sdk_method_channel.dart" path="/Users/lichaochao/dy_open_sdk/lib/dy_open_sdk_method_channel.dart"></mcfile>
- <mcfile name="dy_open_sdk.dart" path="/Users/lichaochao/dy_open_sdk/lib/dy_open_sdk.dart"></mcfile>

## Android 集成说明
- 本插件已在 Android 端声明了 FileProvider 与抖音包查询，无需额外在宿主 App 配置：
  - <mcfile name="AndroidManifest.xml" path="/Users/lichaochao/dy_open_sdk/android/src/main/AndroidManifest.xml"></mcfile>
  - <mcfile name="filepaths.xml" path="/Users/lichaochao/dy_open_sdk/android/src/main/res/xml/filepaths.xml"></mcfile>
- 初始化流程（插件内部已实现）：
  - <mcfile name="DyOpenSdkPlugin.kt" path="/Users/lichaochao/dy_open_sdk/android/src/main/kotlin/com/plugins/dy_open_sdk/DyOpenSdkPlugin.kt"></mcfile>
  - 使用 `DouYinOpenApiFactory.setDebuggable(debug)` 与 `DouYinOpenApiFactory.initConfig(DouYinOpenSDKConfig.Builder().context(context).clientKey(clientKey).build())` 完成初始化。
- 分享媒体：
  - 支持传入文件路径或 Content URI。插件会自动转换为 FileProvider 可读 URI，并授予抖音读权限。
  - `isAlbum` 参数仅对 Android 有意义（图集分享）；iOS 端会忽略该参数。
  - `shareToPublish`：仅支持单视频场景且需要 `isAppSupportShareToPublish()` 返回 true；其他情况将回退到编辑页。
- 注意事项：
  - Android 10+ 建议使用 **Content URI**（SAF/MediaStore）而非直接文件路径，以符合分区存储策略。
  - 未安装抖音/极速版时分享会失败，请在业务层做好提示。

## iOS 集成说明
- 依赖：插件已在 Podspec 中声明 `DouyinOpenSDK` 依赖：
  - <mcfile name="dy_open_sdk.podspec" path="/Users/lichaochao/dy_open_sdk/ios/dy_open_sdk.podspec"></mcfile>
- 初始化流程（插件内部已实现）：
  - <mcfile name="DyOpenSdkPlugin.swift" path="/Users/lichaochao/dy_open_sdk/ios/Classes/DyOpenSdkPlugin.swift"></mcfile>
  - 使用 `DouyinOpenSDKApplicationDelegate.sharedInstance().registerAppId(clientKey)` 完成注册。
- 隐私权限：
  - 分享时 iOS 必须使用 `PHAsset.localIdentifiers`，请在宿主 App 的 `Info.plist` 添加 `NSPhotoLibraryUsageDescription`，以便访问相册。
- 分享媒体：
  - 传入 `PHAsset` 的 `localIdentifiers` 数组（图片或视频）。
  - 插件调用 `DouyinOpenSDKShareRequest` 的 `sendShareRequest` 发起分享，并通过回调返回结果。
  - `shareToPublish`：通过设置 `DouyinOpenSDKShareRequest.landedPageType` 控制落地页（`.publish` 或 `.edit`）。
- 注意事项：
  - iOS 端不支持 `isAlbum`/`newShare`/`hashTags` 参数，这些参数会被忽略（仅用于保持 API 一致性）。
  - 若需从文件路径分享，需先写入到系统相册并获取对应 `PHAsset.localIdentifier` 后再传给插件。

## 参数与扩展
- `clientSecret`：客户端 SDK 初始化不使用；如需鉴权，请在服务端使用（建议勿在客户端存储）。
- `options`：预留扩展参数；当前版本未使用。

## 常见问题
- 初始化失败：请确保传入的 `clientKey` 正确，且在 Android 端仅在应用上下文可用后调用（插件内部已处理）。
- 分享失败：确认抖音或抖音极速版是否安装；检查 Android 端文件路径/URI 的可读性；iOS 端确认相册权限与 `localIdentifiers` 的有效性。

## 参考实现位置
- Android 初始化与分享实现：
  - <mcfile name="DyOpenSdkPlugin.kt" path="/Users/lichaochao/dy_open_sdk/android/src/main/kotlin/com/plugins/dy_open_sdk/DyOpenSdkPlugin.kt"></mcfile>
- iOS 初始化与分享实现：
  - <mcfile name="DyOpenSdkPlugin.swift" path="/Users/lichaochao/dy_open_sdk/ios/Classes/DyOpenSdkPlugin.swift"></mcfile>

如需将配置（环境变量、路由、主题等）统一抽离，请告知你的偏好目录结构，我可以继续完善相应的配置模块与文档。