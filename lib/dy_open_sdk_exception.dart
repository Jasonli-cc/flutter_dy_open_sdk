enum DouyinShareError {
  success(20000, '成功'),
  unknownError(20001, '未知错误'),
  paramValidError(20002, '参数解析错误，获取到的资源和传入的资源类型不一致'),
  sharePermissionDenied(20003, '没有足够的权限进行操作，分享或授权之前请确认您的 App 有相关操作权限。可在 open.douyin.com 的管理中心查看你有哪些权限'),
  userNotLogin(20004, '用户未登录'),
  notHavePhotoLibraryPermission(20005, '抖音没有相册权限'),
  networkError(20006, '抖音网络错误'),
  videoTimeLimitError(20007, '视频时长不符合限制'),
  photoResolutionError(20008, '图片资源分辨率不符合限制'),
  timeStampError(20009, '时间戳检查失败'),
  handleMediaError(20010, '处理照片资源出错'),
  videoResolutionError(20011, '视频分辨率不符合限制'),
  videoFormatError(20012, '视频格式不支持'),
  cancel(20013, '用户取消分享'),
  haveUploadingTask(20014, '用户有未完成编辑的发布内容'),
  saveAsDraft(20015, '用户将分享内容存储为了草稿或用户账号不允许发布视频'),
  publishFailed(20016, '发布视频失败'),
  mediaInIcloudError(21001, '从 iCloud 同步资源出错'),
  paramsParsingError(21002, '传递的参数处理错误'),
  getMediaError(21003, '获取资源错误资源可能不存在');

  final int code;
  final String desc;
  const DouyinShareError(this.code, this.desc);
}

class DouyinException implements Exception {
  static const int successCode = 0;

  final int? errorCode;
  final int? subErrorCode;
  final String? errorMsg;
  final String? state;

  factory DouyinException.fromJson(Map<String, dynamic> json) => DouyinException(json['errorCode'], json['subErrorCode'], json['errorMsg'], json['state']);

  bool get isSuccess => errorCode == DouyinException.successCode;

  DouyinShareError get shareError => DouyinShareError.values.firstWhere((element) => element.code == subErrorCode, orElse: () => DouyinShareError.unknownError);

  DouyinException(this.errorCode, this.subErrorCode, this.errorMsg, this.state);
}
