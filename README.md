# 抖音开放平台 Flutter SDK

基于抖音开放平台官方Android Demo实现的Flutter插件，提供完整的抖音SDK功能集成。

## 功能特性

### 核心功能
- ✅ **SDK初始化** - 支持调试模式和生产模式
- ✅ **授权登录** - 获取用户授权码和权限信息
- ✅ **图片分享** - 支持单图和图集分享
- ✅ **视频分享** - 支持视频分享到抖音
- ✅ **发日常** - Android专用的日常分享功能
- ✅ **IM分享** - 分享图片和HTML卡片给好友
- ✅ **拍摄页** - 打开抖音拍摄页面
- ✅ **安装检查** - 检查抖音是否已安装

### Android端增强功能
基于官方Demo实现的完整功能：

1. **完整的SDK配置**
   - 网络服务配置 (OpenNetworkOkHttpServiceImpl)
   - 图片服务配置 (PicassoOpenImageServiceImpl)
   - 调试模式支持

2. **授权登录系统**
   - 支持多种授权范围 (user_info, mobile, aweme.share等)
   - 完整的回调处理机制
   - 状态管理和错误处理

3. **回调处理机制**
   - <mcfile name="DyOpenSdkCallbackActivity.kt" path="/Users/lichaochao/dy_open_sdk/android/src/main/kotlin/com/plugins/dy_open_sdk/DyOpenSdkCallbackActivity.kt"></mcfile> - 处理授权、分享等回调
   - <mcfile name="StayInDyReceiver.kt" path="/Users/lichaochao/dy_open_sdk/android/src/main/kotlin/com/plugins/dy_open_sdk/StayInDyReceiver.kt"></mcfile> - 处理用户留在抖音的广播

4. **配置管理**
   - <mcfile name="DyOpenSdkConfig.kt" path="/Users/lichaochao/dy_open_sdk/android/src/main/kotlin/com/plugins/dy_open_sdk/DyOpenSdkConfig.kt"></mcfile> - 统一的配置管理
   - 支持配置持久化存储

## 快速开始

### 1. 初始化SDK
```dart
import 'package:dy_open_sdk/dy_open_sdk.dart';

final dyOpenSdk = DyOpenSdk();

// 初始化SDK
await dyOpenSdk.initialize(
  clientKey: "your_client_key_here",
  debug: true, // 开发环境设为true
);
```

### 2. 检查抖音安装状态
```dart
bool isInstalled = await dyOpenSdk.isDouyinInstalled();
if (!isInstalled) {
  // 提示用户安装抖音
}
```

### 3. 授权登录
```dart
try {
  final result = await dyOpenSdk.authorize(
    scope: "user_info", // 可选: user_info, mobile, aweme.share等
  );
  
  if (result['success'] == true) {
    String authCode = result['authCode'];
    String permissions = result['grantedPermissions'];
    // 使用authCode到服务端换取access_token
  }
} catch (e) {
  print('授权失败: $e');
}
```

### 4. 分享功能
```dart
// 分享图片
await dyOpenSdk.shareImages(
  media: ['/path/to/image.jpg'],
  isAlbum: false, // true为图集模式
  hashTags: ['#测试标签'],
);

// 分享视频
await dyOpenSdk.shareVideos(
  media: ['/path/to/video.mp4'],
  hashTags: ['#视频标签'],
);

// 发日常 (Android专用)
await dyOpenSdk.shareDaily(
  media: '/path/to/media',
  mediaType: 'image', // 'image' 或 'video'
);
```

## Android集成配置

### 1. 权限配置
插件已自动配置以下权限：
- 网络访问权限
- 抖音包查询权限
- FileProvider配置

### 2. 宿主应用配置
在您的Android应用中添加FileProvider配置：

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<provider
    android:name="androidx.core.content.FileProvider"
    android:authorities="${applicationId}.fileProvider"
    android:exported="false"
    android:grantUriPermissions="true">
    <meta-data
        android:name="android.support.FILE_PROVIDER_PATHS"
        android:resource="@xml/file_paths" />
</provider>
```

创建 `android/app/src/main/res/xml/file_paths.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<paths xmlns:android="http://schemas.android.com/apk/res/android">
    <external-files-path name="external_files" path="." />
    <external-cache-path name="external_cache" path="." />
    <files-path name="files" path="." />
    <cache-path name="cache" path="." />
    <external-files-path name="dy_open_share" path="dy_open_share/" />
</paths>
```

## 技术实现

### 核心组件
- <mcfile name="DyOpenSdkPlugin.kt" path="/Users/lichaochao/dy_open_sdk/android/src/main/kotlin/com/plugins/dy_open_sdk/DyOpenSdkPlugin.kt"></mcfile> - 主插件类
- <mcfile name="DyOpenSdkCallbackActivity.kt" path="/Users/lichaochao/dy_open_sdk/android/src/main/kotlin/com/plugins/dy_open_sdk/DyOpenSdkCallbackActivity.kt"></mcfile> - 回调处理
- <mcfile name="DyOpenSdkConfig.kt" path="/Users/lichaochao/dy_open_sdk/android/src/main/kotlin/com/plugins/dy_open_sdk/DyOpenSdkConfig.kt"></mcfile> - 配置管理

### 依赖版本
- 抖音OpenSDK: 0.2.0.9
- Android编译SDK: 35
- 最低支持版本: Android 21 (5.0)
- Kotlin版本: 2.1.0

## 注意事项

1. **客户端密钥安全**：clientSecret不应在客户端使用，请在服务端进行鉴权
2. **文件分享**：Android 10+建议使用Content URI而非直接文件路径
3. **权限申请**：分享功能需要相应的开放平台权限配置
4. **版本兼容**：部分功能需要特定版本的抖音客户端支持

## 开发环境

- Flutter 3.35.4 (通过FVM管理)
- Android Gradle Plugin 8.7.3
- Kotlin 2.1.0

## 更多信息

详细的使用说明请参考：<mcfile name="USAGE.md" path="/Users/lichaochao/dy_open_sdk/USAGE.md"></mcfile>

