import 'package:flutter/services.dart';

/// 抖音开放平台SDK异常处理
/// 提供统一的异常类型定义和处理方法
class DyOpenSdkException implements Exception {
  /// 异常类型
  final DyOpenSdkExceptionType type;

  /// 错误码
  final String code;

  /// 错误消息
  final String message;

  /// 详细信息
  final Map<String, dynamic>? details;

  /// 原始异常
  final dynamic originalException;

  const DyOpenSdkException({required this.type, required this.code, required this.message, this.details, this.originalException});

  /// 从PlatformException创建DyOpenSdkException
  factory DyOpenSdkException.fromPlatformException(PlatformException e) {
    final type = _parseExceptionType(e.code);
    return DyOpenSdkException(type: type, code: e.code, message: e.message ?? '未知错误', details: e.details as Map<String, dynamic>?, originalException: e);
  }

  /// 创建参数错误异常
  factory DyOpenSdkException.parameterError(String message, {String? paramName}) {
    return DyOpenSdkException(
      type: DyOpenSdkExceptionType.parameter,
      code: 'BAD_ARGS',
      message: message,
      details: paramName != null ? {'parameterName': paramName} : null,
    );
  }

  /// 创建网络错误异常
  factory DyOpenSdkException.networkError(String message) {
    return DyOpenSdkException(type: DyOpenSdkExceptionType.network, code: 'NETWORK_ERROR', message: message);
  }

  /// 创建API不支持异常
  factory DyOpenSdkException.apiNotSupported(String apiName, String reason) {
    return DyOpenSdkException(
      type: DyOpenSdkExceptionType.apiCall,
      code: 'API_NOT_SUPPORTED',
      message: 'API不支持: $apiName - $reason',
      details: {'apiName': apiName, 'reason': reason},
    );
  }

  /// 解析异常类型
  static DyOpenSdkExceptionType _parseExceptionType(String code) {
    if (code.startsWith('INIT')) return DyOpenSdkExceptionType.initialization;
    if (code.startsWith('BAD_ARGS') || code.startsWith('MISSING') || code.startsWith('INVALID')) {
      return DyOpenSdkExceptionType.parameter;
    }
    if (code.startsWith('FILE')) return DyOpenSdkExceptionType.fileOperation;
    if (code.startsWith('API') || code.startsWith('DOUYIN') || code.startsWith('SDK')) {
      return DyOpenSdkExceptionType.apiCall;
    }
    if (code.startsWith('AUTH')) return DyOpenSdkExceptionType.authorization;
    if (code.startsWith('SHARE')) return DyOpenSdkExceptionType.share;
    if (code.startsWith('NETWORK') || code.startsWith('TIMEOUT')) {
      return DyOpenSdkExceptionType.network;
    }
    return DyOpenSdkExceptionType.unknown;
  }

  /// 是否为用户取消操作
  bool get isUserCancelled {
    return code.contains('CANCELLED');
  }

  /// 是否为网络相关错误
  bool get isNetworkError {
    return type == DyOpenSdkExceptionType.network;
  }

  /// 是否为参数错误
  bool get isParameterError {
    return type == DyOpenSdkExceptionType.parameter;
  }

  /// 是否为API不支持错误
  bool get isApiNotSupported {
    return code == 'API_NOT_SUPPORTED' || code.startsWith('UNSUPPORTED');
  }

  /// 获取用户友好的错误消息
  String get userFriendlyMessage {
    switch (type) {
      case DyOpenSdkExceptionType.initialization:
        return 'SDK初始化失败，请检查配置';
      case DyOpenSdkExceptionType.parameter:
        return '参数错误，请检查输入参数';
      case DyOpenSdkExceptionType.fileOperation:
        return '文件操作失败，请检查文件路径和权限';
      case DyOpenSdkExceptionType.apiCall:
        if (code == 'DOUYIN_NOT_INSTALLED') {
          return '请先安装抖音应用';
        }
        return 'API调用失败，请稍后重试';
      case DyOpenSdkExceptionType.authorization:
        if (isUserCancelled) {
          return '用户取消了授权';
        }
        return '授权失败，请重新尝试';
      case DyOpenSdkExceptionType.share:
        if (isUserCancelled) {
          return '用户取消了分享';
        }
        if (isApiNotSupported) {
          return '当前抖音版本不支持此分享功能';
        }
        return '分享失败，请重新尝试';
      case DyOpenSdkExceptionType.network:
        return '网络连接失败，请检查网络设置';
      case DyOpenSdkExceptionType.unknown:
        return '操作失败，请重新尝试';
    }
  }

  @override
  String toString() {
    return 'DyOpenSdkException(type: $type, code: $code, message: $message, details: $details)';
  }
}

/// 异常类型枚举
enum DyOpenSdkExceptionType {
  /// SDK初始化异常
  initialization('INIT', 'SDK初始化异常'),

  /// 参数异常
  parameter('PARAM', '参数异常'),

  /// 文件操作异常
  fileOperation('FILE', '文件操作异常'),

  /// API调用异常
  apiCall('API', 'API调用异常'),

  /// 授权异常
  authorization('AUTH', '授权异常'),

  /// 分享异常
  share('SHARE', '分享异常'),

  /// 网络异常
  network('NETWORK', '网络异常'),

  /// 未知异常
  unknown('UNKNOWN', '未知异常');

  const DyOpenSdkExceptionType(this.code, this.description);

  /// 异常类型代码
  final String code;

  /// 异常类型描述
  final String description;
}

/// 异常处理工具类
class DyOpenSdkExceptionHandler {
  /// 处理方法调用异常
  static Future<T> handleMethodCall<T>(Future<T> Function() methodCall) async {
    try {
      return await methodCall();
    } on PlatformException catch (e) {
      throw DyOpenSdkException.fromPlatformException(e);
    } catch (e) {
      throw DyOpenSdkException(type: DyOpenSdkExceptionType.unknown, code: 'UNKNOWN_ERROR', message: e.toString(), originalException: e);
    }
  }

  /// 处理异常并返回默认值
  static Future<T> handleWithDefault<T>(Future<T> Function() methodCall, T defaultValue) async {
    try {
      return await handleMethodCall(methodCall);
    } catch (e) {
      return defaultValue;
    }
  }

  /// 处理异常并执行回调
  static Future<T?> handleWithCallback<T>(Future<T> Function() methodCall, {void Function(DyOpenSdkException)? onError}) async {
    try {
      return await handleMethodCall(methodCall);
    } on DyOpenSdkException catch (e) {
      onError?.call(e);
      return null;
    }
  }
}
