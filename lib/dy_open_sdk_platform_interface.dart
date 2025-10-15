import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'dy_open_sdk_method_channel.dart';

abstract class DyOpenSdkPlatform extends PlatformInterface {
  /// Constructs a DyOpenSdkPlatform.
  DyOpenSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static DyOpenSdkPlatform _instance = MethodChannelDyOpenSdk();

  /// The default instance of [DyOpenSdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelDyOpenSdk].
  static DyOpenSdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [DyOpenSdkPlatform] when
  /// they register themselves.
  static set instance(DyOpenSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Initialize the Douyin Open SDK.
  /// Note: clientSecret is NOT used on-device; keep it on your server. This param is accepted for API symmetry but ignored by native code.
  Future<Map<String, dynamic>> initialize({
    required String clientKey,
    String? clientSecret,
    bool debug = false,
    Map<String, dynamic>? options,
  }) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// Authorize with Douyin Open Platform.
  /// Returns authorization code and granted permissions on success.
  Future<Map<String, dynamic>> authorize({
    String scope = "user_info",
    String? state,
  }) {
    throw UnimplementedError('authorize() has not been implemented.');
  }

  /// Check if Douyin app is installed.
  Future<bool> isDouyinInstalled() {
    throw UnimplementedError('isDouyinInstalled() has not been implemented.');
  }

  /// Share one or multiple images to Douyin.
  /// Note: On iOS, [media] must be PHAsset localIdentifiers. On Android, these can be file paths or content URIs.
  Future<Map<String, dynamic>> shareImages({
    required List<String> media,
    bool isAlbum = false,
    String? shareId,
    Map<String, dynamic>? microAppInfo,
    List<String>? hashTags,
    bool newShare = false,
    // 控制分享到发布页（true）或编辑页（false）。
    // 注意：Android 仅支持单视频直接到发布页；不满足条件时将回退到编辑页。
    bool shareToPublish = false,
    Map<String, dynamic>? shareParam,
  }) {
    throw UnimplementedError('shareImages() has not been implemented.');
  }

  /// Share one or multiple videos to Douyin.
  /// Note: On iOS, [media] must be PHAsset localIdentifiers. On Android, these can be file paths or content URIs.
  Future<Map<String, dynamic>> shareVideos({
    required List<String> media,
    String? shareId,
    Map<String, dynamic>? microAppInfo,
    List<String>? hashTags,
    bool newShare = false,
    // 控制分享到发布页（true）或编辑页（false）。
    // 注意：Android 仅支持单视频直接到发布页；不满足条件时将回退到编辑页。
    bool shareToPublish = false,
    Map<String, dynamic>? shareParam,
  }) {
    throw UnimplementedError('shareVideos() has not been implemented.');
  }

  /// Android-only: 发日常（share daily）
  Future<Map<String, dynamic>> shareDaily({
    required String media,
    required String mediaType, // 'image' | 'video'
    String? shareId,
    Map<String, dynamic>? microAppInfo,
    List<String>? hashTags,
    bool newShare = true,
    Map<String, dynamic>? shareParam,
  }) {
    throw UnimplementedError('shareDaily() has not been implemented.');
  }

  /// Android-only: 把图片分享给好友（IM）
  Future<Map<String, dynamic>> shareImageToIm({
    required String media,
    String? shareId,
  }) {
    throw UnimplementedError('shareImageToIm() has not been implemented.');
  }

  /// Android-only: 把网页（HTML 卡片）分享给好友（IM）
  Future<Map<String, dynamic>> shareHtmlToIm({
    required Map<String, dynamic> htmlObject,
    String? shareId,
  }) {
    throw UnimplementedError('shareHtmlToIm() has not been implemented.');
  }

  /// Android-only: 打开拍摄页（Open Record Page）
  Future<Map<String, dynamic>> openRecord({
    String? shareId,
    Map<String, dynamic>? microAppInfo,
    List<String>? hashTags,
    Map<String, dynamic>? shareParam,
  }) {
    throw UnimplementedError('openRecord() has not been implemented.');
  }
}
