import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'dy_open_sdk_platform_interface.dart';
import 'dy_open_sdk_exception.dart';

/// An implementation of [DyOpenSdkPlatform] that uses method channels.
class MethodChannelDyOpenSdk extends DyOpenSdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('dy_open_sdk');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<Map<String, dynamic>> initialize({
    required String clientKey,
    String? clientSecret,
    bool debug = false,
    Map<String, dynamic>? options,
  }) async {
    return await DyOpenSdkExceptionHandler.handleMethodCall(() async {
      if (clientKey.isEmpty) {
        throw DyOpenSdkException.parameterError('clientKey不能为空', paramName: 'clientKey');
      }
      
      final result = await methodChannel.invokeMapMethod<String, dynamic>('initialize', {
        'clientKey': clientKey,
        'debug': debug,
        // clientSecret和options在Android端不使用，但保持API一致性
      });
      return Map<String, dynamic>.from(result ?? {});
    });
  }

  @override
  Future<Map<String, dynamic>> authorize({
    String scope = "user_info",
    String? state,
  }) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>('authorize', {
      'scope': scope,
      'state': state,
    });
    return Map<String, dynamic>.from(result ?? {});
  }

  @override
  Future<bool> isDouyinInstalled() async {
    final result = await methodChannel.invokeMethod<bool>('isDouyinInstalled');
    return result ?? false;
  }

  @override
  Future<Map<String, dynamic>> shareImages({
    required List<String> media,
    bool isAlbum = false,
    String? shareId,
    Map<String, dynamic>? microAppInfo,
    List<String>? hashTags,
    bool newShare = false,
    Map<String, dynamic>? shareParam,
  }) async {
    return await DyOpenSdkExceptionHandler.handleMethodCall(() async {
      if (media.isEmpty) {
        throw DyOpenSdkException.parameterError('媒体文件列表不能为空', paramName: 'media');
      }
      
      // 验证文件路径
      for (final path in media) {
        if (path.isEmpty) {
          throw DyOpenSdkException.parameterError('媒体文件路径不能为空', paramName: 'media');
        }
      }
      
      final result = await methodChannel.invokeMapMethod<String, dynamic>('shareImages', {
        'media': media,
        'isAlbum': isAlbum,
        'shareId': shareId,
        'microAppInfo': microAppInfo,
        'hashTags': hashTags,
        'newShare': newShare,
        'shareParam': shareParam,
      });
      return Map<String, dynamic>.from(result ?? {});
    });
  }

  @override
  Future<Map<String, dynamic>> shareVideos({
    required List<String> media,
    String? shareId,
    Map<String, dynamic>? microAppInfo,
    List<String>? hashTags,
    bool newShare = false,
    Map<String, dynamic>? shareParam,
  }) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>('shareVideos', {
      'media': media,
      'shareId': shareId,
      'microAppInfo': microAppInfo,
      'hashTags': hashTags,
      'newShare': newShare,
      'shareParam': shareParam,
    });
    return Map<String, dynamic>.from(result ?? {});
  }

  // Android-only APIs
  @override
  Future<Map<String, dynamic>> shareDaily({
    required String media,
    required String mediaType,
    String? shareId,
    Map<String, dynamic>? microAppInfo,
    List<String>? hashTags,
    bool newShare = true,
    Map<String, dynamic>? shareParam,
  }) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>('shareDaily', {
      'media': media,
      'mediaType': mediaType,
      'shareId': shareId,
      'microAppInfo': microAppInfo,
      'hashTags': hashTags,
      'newShare': newShare,
      'shareParam': shareParam,
    });
    return Map<String, dynamic>.from(result ?? {});
  }

  @override
  Future<Map<String, dynamic>> shareImageToIm({
    required String media,
    String? shareId,
  }) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>('shareImageToIm', {
      'media': media,
      'shareId': shareId,
    });
    return Map<String, dynamic>.from(result ?? {});
  }

  @override
  Future<Map<String, dynamic>> shareHtmlToIm({
    required Map<String, dynamic> htmlObject,
    String? shareId,
  }) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>('shareHtmlToIm', {
      'htmlObject': htmlObject,
      'shareId': shareId,
    });
    return Map<String, dynamic>.from(result ?? {});
  }

  @override
  Future<Map<String, dynamic>> openRecord({
    String? shareId,
    Map<String, dynamic>? microAppInfo,
    List<String>? hashTags,
    Map<String, dynamic>? shareParam,
  }) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>('openRecord', {
      'shareId': shareId,
      'microAppInfo': microAppInfo,
      'hashTags': hashTags,
      'shareParam': shareParam,
    });
    return Map<String, dynamic>.from(result ?? {});
  }
}
