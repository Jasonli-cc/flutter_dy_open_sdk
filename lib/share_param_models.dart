/// 标题对象与标记模型，帮助构造 shareParam.titleObject 的 Map 结构。
abstract class TitleMarker {
  Map<String, dynamic> toMap();
}

/// 话题标记（插入到标题中）
/// type=hashtag, 需要 name 和插入位置 start
class HashtagMarker implements TitleMarker {
  final String name;
  final int start;
  HashtagMarker({required this.name, required this.start});
  @override
  Map<String, dynamic> toMap() => {'type': 'hashtag', 'name': name, 'start': start};
}

/// 提及标记（@某人，插入到标题中）
/// type=mention, 需要 openId 和插入位置 start
class MentionMarker implements TitleMarker {
  final String openId;
  final int start;
  MentionMarker({required this.openId, required this.start});
  @override
  Map<String, dynamic> toMap() => {'type': 'mention', 'openId': openId, 'start': start};
}

/// 标题对象：包含完整标题、短标题（Android 抖音 30.0.0+ 支持）、以及标题中的标记列表
class TitleObject {
  final String? title;
  final String? shortTitle;
  final List<TitleMarker> markers;

  TitleObject({this.title, this.shortTitle, List<TitleMarker>? markers}) : markers = markers ?? const [];

  /// 输出为 shareParam.titleObject 的标准结构
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (title != null) map['title'] = title;
    if (shortTitle != null) map['shortTitle'] = shortTitle;
    if (markers.isNotEmpty) {
      map['markers'] = markers.map((m) => m.toMap()).toList();
    }
    return map;
  }

  /// 从 Map 反序列化（可选工具方法）
  factory TitleObject.fromMap(Map<String, dynamic> map) {
    final markersMap = map['markers'] as List<dynamic>? ?? const [];
    final parsedMarkers = <TitleMarker>[];
    for (final m in markersMap) {
      if (m is Map) {
        final type = m['type'] as String?;
        final start = (m['start'] as num?)?.toInt() ?? 0;
        if (type == 'hashtag') {
          final name = m['name'] as String? ?? '';
          parsedMarkers.add(HashtagMarker(name: name, start: start));
        } else if (type == 'mention') {
          final openId = m['openId'] as String? ?? '';
          parsedMarkers.add(MentionMarker(openId: openId, start: start));
        }
      }
    }
    return TitleObject(title: map['title'] as String?, shortTitle: (map['shortTitle'] as String?) ?? (map['short_title'] as String?), markers: parsedMarkers);
  }
}
