import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'dy_open_sdk_platform_interface.dart';

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
    final result = await methodChannel.invokeMapMethod<String, dynamic>('initialize', {
      'clientKey': clientKey,
      'clientSecret': clientSecret,
      'debug': debug,
      'options': options,
    });
    return Map<String, dynamic>.from(result ?? {'success': false});
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
