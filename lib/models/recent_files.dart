import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

class RecentFile {
  RecentFile({required this.name, required this.path, required this.openedAt});

  final String name;
  final String path;
  final DateTime openedAt;

  Map<String, dynamic> toJson() => {
        'name': name,
        'path': path,
        'openedAt': openedAt.toIso8601String(),
      };

  static RecentFile fromJson(Map<String, dynamic> j) => RecentFile(
        name: j['name'] as String,
        path: j['path'] as String,
        openedAt: DateTime.parse(j['openedAt'] as String),
      );
}

/// 최근 연 파일 목록 (최대 20개). 파일 선택기가 준 경로를 저장하며,
/// 파일이 지워졌으면 목록에서 자동으로 빠집니다.
class RecentFilesStore {
  static const _key = 'recent_files';
  static const _max = 20;

  Future<List<RecentFile>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    final list = <RecentFile>[];
    for (final s in raw) {
      try {
        final f = RecentFile.fromJson(jsonDecode(s) as Map<String, dynamic>);
        if (File(f.path).existsSync()) list.add(f);
      } catch (_) {
        // 깨진 항목은 무시
      }
    }
    return list;
  }

  Future<void> add(String name, String path) async {
    final list = await load();
    list.removeWhere((f) => f.path == path);
    list.insert(0, RecentFile(name: name, path: path, openedAt: DateTime.now()));
    await _save(list.take(_max).toList());
  }

  Future<void> remove(String path) async {
    final list = await load();
    list.removeWhere((f) => f.path == path);
    await _save(list);
  }

  Future<void> clear() async => _save(const []);

  Future<void> _save(List<RecentFile> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      list.map((f) => jsonEncode(f.toJson())).toList(),
    );
  }
}
