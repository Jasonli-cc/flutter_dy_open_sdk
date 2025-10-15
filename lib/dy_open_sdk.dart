import 'dy_open_sdk_platform_interface.dart';

export 'dy_open_sdk_exception.dart';

enum MediaType { image, video }

class DyOpenSdk {
  Future<String?> getPlatformVersion() {
    return DyOpenSdkPlatform.instance.getPlatformVersion();
  }

  Future<Map<String, dynamic>> initialize({required String clientKey, String? clientSecret, bool debug = false, Map<String, dynamic>? options}) {
    return DyOpenSdkPlatform.instance.initialize(clientKey: clientKey, clientSecret: clientSecret, debug: debug, options: options);
  }

  Future<Map<String, dynamic>> authorize({String scope = "user_info", String? state}) {
    return DyOpenSdkPlatform.instance.authorize(scope: scope, state: state);
  }

  Future<bool> isDouyinInstalled() {
    return DyOpenSdkPlatform.instance.isDouyinInstalled();
  }

  Future<Map<String, dynamic>> shareImages({
    required List<String> media,
    bool isAlbum = false,
    String? shareId,
    Map<String, dynamic>? microAppInfo,
    List<String>? hashTags,
    bool newShare = false,
    bool shareToPublish = false,
    Map<String, dynamic>? shareParam,
  }) {
    return DyOpenSdkPlatform.instance.shareImages(
      media: media,
      isAlbum: isAlbum,
      shareId: shareId,
      microAppInfo: microAppInfo,
      hashTags: hashTags,
      newShare: newShare,
      shareToPublish: shareToPublish,
      shareParam: shareParam,
    );
  }

  Future<Map<String, dynamic>> shareVideos({
    required List<String> media,
    String? shareId,
    Map<String, dynamic>? microAppInfo,
    List<String>? hashTags,
    bool newShare = false,
    bool shareToPublish = false,
    Map<String, dynamic>? shareParam,
  }) {
    return DyOpenSdkPlatform.instance.shareVideos(
      media: media,
      shareId: shareId,
      microAppInfo: microAppInfo,
      hashTags: hashTags,
      newShare: newShare,
      shareToPublish: shareToPublish,
      shareParam: shareParam,
    );
  }

  // Android-only methods
  Future<Map<String, dynamic>> shareDaily({
    required String media,
    required MediaType mediaType,
    String? shareId,
    Map<String, dynamic>? microAppInfo,
    List<String>? hashTags,
    bool newShare = true,
    Map<String, dynamic>? shareParam,
  }) {
    return DyOpenSdkPlatform.instance.shareDaily(
      media: media,
      mediaType: mediaType.name,
      shareId: shareId,
      microAppInfo: microAppInfo,
      hashTags: hashTags,
      newShare: newShare,
      shareParam: shareParam,
    );
  }

  Future<Map<String, dynamic>> shareImageToIm({required String media, String? shareId}) {
    return DyOpenSdkPlatform.instance.shareImageToIm(media: media, shareId: shareId);
  }

  Future<Map<String, dynamic>> shareHtmlToIm({required Map<String, dynamic> htmlObject, String? shareId}) {
    return DyOpenSdkPlatform.instance.shareHtmlToIm(htmlObject: htmlObject, shareId: shareId);
  }

  Future<Map<String, dynamic>> openRecord({String? shareId, Map<String, dynamic>? microAppInfo, List<String>? hashTags, Map<String, dynamic>? shareParam}) {
    return DyOpenSdkPlatform.instance.openRecord(shareId: shareId, microAppInfo: microAppInfo, hashTags: hashTags, shareParam: shareParam);
  }
}
