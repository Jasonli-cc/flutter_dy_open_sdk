# iOS 集成指南

## 前置条件

1. iOS 12.0 或更高版本
2. 已在抖音开放平台注册应用并获得 ClientKey
3. 设备上已安装抖音或抖音极速版

## 集成步骤

### 1. 添加依赖

在你的 Flutter 项目的 `pubspec.yaml` 中添加：

```yaml
dependencies:
  dy_open_sdk: ^0.0.1
```

### 2. iOS 配置

#### 2.1 配置 URL Scheme

在 `ios/Runner/Info.plist` 中添加 URL Scheme 配置：

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>douyinopensdk</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>你的ClientKey</string>
        </array>
    </dict>
</array>
```

#### 2.2 配置查询白名单

在 `ios/Runner/Info.plist` 中添加：

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>douyinopensdk</string>
    <string>douyinliteopensdk</string>
</array>
```

#### 2.3 配置相册权限

如果需要分享图片或视频，在 `ios/Runner/Info.plist` 中添加：

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册来分享图片和视频到抖音</string>
```

#### 2.4 配置 AppDelegate

在 `ios/Runner/AppDelegate.swift` 中添加 URL 处理：

```swift
import UIKit
import Flutter
import DouyinOpenSDK

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    if DouyinOpenSDKApplicationDelegate.sharedInstance().application(app, open: url, sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String, annotation: options[UIApplication.OpenURLOptionsKey.annotation]) {
      return true
    }
    return super.application(app, open: url, options: options)
  }
  
  override func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
    if DouyinOpenSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation) {
      return true
    }
    return super.application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
  }
}
```

## 使用方法

### 1. 初始化 SDK

```dart
import 'package:dy_open_sdk/dy_open_sdk.dart';

final dyOpenSdk = DyOpenSdk();

// 初始化
try {
  final result = await dyOpenSdk.initialize(
    clientKey: '你的ClientKey',
    debug: true, // iOS端会忽略此参数
  );
  print('初始化成功: ${result['message']}');
} catch (e) {
  print('初始化失败: $e');
}
```

### 2. 检查抖音是否安装

```dart
final isInstalled = await dyOpenSdk.isDouyinInstalled();
if (!isInstalled) {
  // 提示用户安装抖音
  print('请先安装抖音或抖音极速版');
}
```

### 3. 用户授权

```dart
try {
  final result = await dyOpenSdk.authorize(
    scope: 'user_info',
    state: 'your_state', // 可选
  );
  
  if (result['success']) {
    print('授权成功');
    print('授权码: ${result['code']}');
    print('授权权限: ${result['grantedPermissions']}');
  } else {
    print('授权失败: ${result['errorMsg']}');
  }
} catch (e) {
  print('授权异常: $e');
}
```

### 4. 分享图片

```dart
// 注意：iOS端需要传入PHAsset的localIdentifier
// 你需要先从相册获取PHAsset，然后传入其localIdentifier
try {
  final result = await dyOpenSdk.shareImages(
    media: ['PHAsset-localIdentifier-1', 'PHAsset-localIdentifier-2'],
    shareId: 'your_share_id', // 可选
    microAppInfo: { // 可选小程序信息
      'identifier': 'your_micro_app_id',
      'title': '小程序标题',
      'desc': '小程序描述',
      'startPageURL': 'https://your-micro-app-url.com'
    },
    hashTags: ['#标签1', '#标签2'], // 可选
    shareParam: { // 可选分享参数
      'productExtraInfo': {
        'styleID': 'your_style_id'
      }
    }
  );
  
  if (result['success']) {
    print('分享成功');
  } else {
    print('分享失败: ${result['errorMsg']}');
  }
} catch (e) {
  print('分享异常: $e');
}
```

### 5. 分享视频

```dart
// 使用方式与分享图片类似
try {
  final result = await dyOpenSdk.shareVideos(
    media: ['PHAsset-localIdentifier-video'],
    shareId: 'your_share_id',
    // 其他参数与分享图片相同
  );
  
  if (result['success']) {
    print('视频分享成功');
  } else {
    print('视频分享失败: ${result['errorMsg']}');
  }
} catch (e) {
  print('视频分享异常: $e');
}
```

## 注意事项

1. **媒体文件格式**：iOS端必须使用PHAsset的localIdentifier，不能直接使用文件路径
2. **权限要求**：需要相册访问权限才能获取PHAsset
3. **不支持的参数**：iOS端不支持 `isAlbum`、`newShare` 等Android特有参数
4. **URL Scheme**：必须正确配置URL Scheme才能接收抖音的回调
5. **应用安装检查**：分享前建议先检查抖音是否已安装

## 错误处理

插件会返回统一的错误格式：

```dart
{
  "success": false,
  "errorCode": -1,
  "errorMsg": "错误描述"
}
```

常见错误码：
- `BAD_ARGS`: 参数错误
- `NOT_INITIALIZED`: SDK未初始化
- `NO_VIEW_CONTROLLER`: 找不到视图控制器
- `SHARE_ERROR`: 分享失败
- `AUTH_ERROR`: 授权失败

## 从文件路径获取PHAsset示例

如果你需要从文件路径分享，可以参考以下代码将文件保存到相册并获取PHAsset：

```dart
import 'package:photo_manager/photo_manager.dart';

// 保存图片到相册并获取PHAsset
Future<String?> saveImageAndGetAssetId(String imagePath) async {
  final result = await PhotoManager.editor.saveImageWithPath(
    imagePath,
    title: "shared_image",
  );
  return result?.id;
}

// 保存视频到相册并获取PHAsset
Future<String?> saveVideoAndGetAssetId(String videoPath) async {
  final result = await PhotoManager.editor.saveVideo(
    File(videoPath),
    title: "shared_video",
  );
  return result?.id;
}
```

## 参考资源

- [抖音开放平台文档](https://developer.open-douyin.com/)
- [DouyinOpenSDK iOS文档](https://developer.open-douyin.com/docs/resource/zh-CN/dop/develop/sdk/mobile-app/permission/ios-permission/)