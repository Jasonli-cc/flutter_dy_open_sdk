import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:dy_open_sdk/dy_open_sdk.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  String _status = '未初始化';
  bool _isDouyinInstalled = false;
  final _dyOpenSdkPlugin = DyOpenSdk();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    try {
      platformVersion = await _dyOpenSdkPlugin.getPlatformVersion() ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // 检查抖音是否安装
    bool isInstalled = false;
    try {
      isInstalled = await _dyOpenSdkPlugin.isDouyinInstalled();
    } catch (e) {
      print('检查抖音安装状态失败: $e');
    }

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
      _isDouyinInstalled = isInstalled;
    });
  }

  Future<void> _initializeSDK() async {
    try {
      // 配置异常处理
      DyOpenSdkConfig.setExceptionConfig(
        DyOpenSdkExceptionConfig(
          enableAutoRetry: true,
          maxRetryCount: 2,
          printStackTraceInDebug: true,
          customExceptionHandler: (exception) {
            DyOpenSdkLogger.e('自定义异常处理: ${exception.message}');
          },
        ),
      );
      
      // 请替换为您的实际clientKey
      const clientKey = "your_client_key_here";
      final result = await _dyOpenSdkPlugin.initialize(
        clientKey: clientKey,
        debug: true,
      );
      
      setState(() {
        _status = result['success'] == true ? 'SDK初始化成功' : 'SDK初始化失败';
      });
      
      DyOpenSdkLogger.i('SDK初始化成功');
    } on DyOpenSdkException catch (e) {
      setState(() {
        _status = 'SDK初始化失败: ${e.userFriendlyMessage}';
      });
      DyOpenSdkLogger.e('SDK初始化异常', e);
    } catch (e) {
      setState(() {
        _status = 'SDK初始化失败: 未知错误';
      });
      DyOpenSdkLogger.e('未知异常', e);
    }
  }

  Future<void> _authorize() async {
    try {
      final result = await _dyOpenSdkPlugin.authorize(scope: "user_info");

      if (result['success'] == true) {
        setState(() {
          _status = '授权成功\nAuthCode: ${result['authCode']}\nPermissions: ${result['grantedPermissions']}';
        });
      } else {
        setState(() {
          _status = '授权失败';
        });
      }
    } catch (e) {
      setState(() {
        _status = '授权失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('抖音开放平台SDK示例'), backgroundColor: Colors.blue),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('平台版本: $_platformVersion'),
                      const SizedBox(height: 8),
                      Text('抖音安装状态: ${_isDouyinInstalled ? "已安装" : "未安装"}'),
                      const SizedBox(height: 8),
                      Text('SDK状态: $_status'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _initializeSDK, child: const Text('初始化SDK')),
              const SizedBox(height: 10),
              ElevatedButton(onPressed: _isDouyinInstalled ? _authorize : null, child: const Text('授权登录')),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isDouyinInstalled
                    ? () {
                        // 这里可以添加分享图片的示例
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先选择图片进行分享')));
                      }
                    : null,
                child: const Text('分享图片'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isDouyinInstalled
                    ? () {
                        // 这里可以添加打开拍摄页的示例
                        _dyOpenSdkPlugin.openRecord();
                      }
                    : null,
                child: const Text('打开拍摄页'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
