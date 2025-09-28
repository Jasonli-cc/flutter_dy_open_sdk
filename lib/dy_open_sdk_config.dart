import 'dy_open_sdk_exception.dart';

/// 抖音开放平台SDK配置
/// 提供统一的配置管理，包括异常处理、日志等
class DyOpenSdkConfig {
  /// 是否启用调试模式
  static bool _debugMode = false;
  
  /// 异常处理配置
  static DyOpenSdkExceptionConfig _exceptionConfig = DyOpenSdkExceptionConfig();
  
  /// 日志配置
  static DyOpenSdkLogConfig _logConfig = DyOpenSdkLogConfig();

  /// 获取调试模式状态
  static bool get debugMode => _debugMode;

  /// 设置调试模式
  static void setDebugMode(bool debug) {
    _debugMode = debug;
  }

  /// 获取异常处理配置
  static DyOpenSdkExceptionConfig get exceptionConfig => _exceptionConfig;

  /// 设置异常处理配置
  static void setExceptionConfig(DyOpenSdkExceptionConfig config) {
    _exceptionConfig = config;
  }

  /// 获取日志配置
  static DyOpenSdkLogConfig get logConfig => _logConfig;

  /// 设置日志配置
  static void setLogConfig(DyOpenSdkLogConfig config) {
    _logConfig = config;
  }

  /// 重置所有配置为默认值
  static void reset() {
    _debugMode = false;
    _exceptionConfig = DyOpenSdkExceptionConfig();
    _logConfig = DyOpenSdkLogConfig();
  }
}

/// 异常处理配置
class DyOpenSdkExceptionConfig {
  /// 是否启用自动重试
  final bool enableAutoRetry;
  
  /// 最大重试次数
  final int maxRetryCount;
  
  /// 重试延迟（毫秒）
  final int retryDelayMs;
  
  /// 是否在调试模式下打印异常堆栈
  final bool printStackTraceInDebug;
  
  /// 自定义异常处理器
  final void Function(DyOpenSdkException)? customExceptionHandler;
  
  /// 网络异常处理器
  final void Function(DyOpenSdkException)? networkExceptionHandler;
  
  /// 参数异常处理器
  final void Function(DyOpenSdkException)? parameterExceptionHandler;

  const DyOpenSdkExceptionConfig({
    this.enableAutoRetry = false,
    this.maxRetryCount = 3,
    this.retryDelayMs = 1000,
    this.printStackTraceInDebug = true,
    this.customExceptionHandler,
    this.networkExceptionHandler,
    this.parameterExceptionHandler,
  });

  /// 创建副本并修改部分配置
  DyOpenSdkExceptionConfig copyWith({
    bool? enableAutoRetry,
    int? maxRetryCount,
    int? retryDelayMs,
    bool? printStackTraceInDebug,
    void Function(DyOpenSdkException)? customExceptionHandler,
    void Function(DyOpenSdkException)? networkExceptionHandler,
    void Function(DyOpenSdkException)? parameterExceptionHandler,
  }) {
    return DyOpenSdkExceptionConfig(
      enableAutoRetry: enableAutoRetry ?? this.enableAutoRetry,
      maxRetryCount: maxRetryCount ?? this.maxRetryCount,
      retryDelayMs: retryDelayMs ?? this.retryDelayMs,
      printStackTraceInDebug: printStackTraceInDebug ?? this.printStackTraceInDebug,
      customExceptionHandler: customExceptionHandler ?? this.customExceptionHandler,
      networkExceptionHandler: networkExceptionHandler ?? this.networkExceptionHandler,
      parameterExceptionHandler: parameterExceptionHandler ?? this.parameterExceptionHandler,
    );
  }
}

/// 日志配置
class DyOpenSdkLogConfig {
  /// 是否启用日志
  final bool enableLogging;
  
  /// 日志级别
  final DyOpenSdkLogLevel logLevel;
  
  /// 自定义日志处理器
  final void Function(DyOpenSdkLogLevel level, String tag, String message)? customLogHandler;

  const DyOpenSdkLogConfig({
    this.enableLogging = true,
    this.logLevel = DyOpenSdkLogLevel.info,
    this.customLogHandler,
  });

  /// 创建副本并修改部分配置
  DyOpenSdkLogConfig copyWith({
    bool? enableLogging,
    DyOpenSdkLogLevel? logLevel,
    void Function(DyOpenSdkLogLevel level, String tag, String message)? customLogHandler,
  }) {
    return DyOpenSdkLogConfig(
      enableLogging: enableLogging ?? this.enableLogging,
      logLevel: logLevel ?? this.logLevel,
      customLogHandler: customLogHandler ?? this.customLogHandler,
    );
  }
}

/// 日志级别
enum DyOpenSdkLogLevel {
  /// 详细日志
  verbose(0, 'VERBOSE'),
  
  /// 调试日志
  debug(1, 'DEBUG'),
  
  /// 信息日志
  info(2, 'INFO'),
  
  /// 警告日志
  warning(3, 'WARNING'),
  
  /// 错误日志
  error(4, 'ERROR');

  const DyOpenSdkLogLevel(this.level, this.name);

  /// 日志级别数值
  final int level;
  
  /// 日志级别名称
  final String name;
}

/// SDK日志工具
class DyOpenSdkLogger {
  static const String _tag = 'DyOpenSdk';

  /// 打印详细日志
  static void v(String message) {
    _log(DyOpenSdkLogLevel.verbose, message);
  }

  /// 打印调试日志
  static void d(String message) {
    _log(DyOpenSdkLogLevel.debug, message);
  }

  /// 打印信息日志
  static void i(String message) {
    _log(DyOpenSdkLogLevel.info, message);
  }

  /// 打印警告日志
  static void w(String message) {
    _log(DyOpenSdkLogLevel.warning, message);
  }

  /// 打印错误日志
  static void e(String message, [Object? error, StackTrace? stackTrace]) {
    _log(DyOpenSdkLogLevel.error, message);
    if (error != null && DyOpenSdkConfig.exceptionConfig.printStackTraceInDebug && DyOpenSdkConfig.debugMode) {
      _log(DyOpenSdkLogLevel.error, 'Error: $error');
      if (stackTrace != null) {
        _log(DyOpenSdkLogLevel.error, 'StackTrace: $stackTrace');
      }
    }
  }

  /// 内部日志方法
  static void _log(DyOpenSdkLogLevel level, String message) {
    final config = DyOpenSdkConfig.logConfig;
    
    if (!config.enableLogging || level.level < config.logLevel.level) {
      return;
    }

    if (config.customLogHandler != null) {
      config.customLogHandler!(level, _tag, message);
    } else {
      // 默认日志输出
      print('[$_tag][${level.name}] $message');
    }
  }
}