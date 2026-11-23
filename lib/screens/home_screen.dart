import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/doc_type.dart';
import '../models/recent_files.dart';
import 'viewer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _store = RecentFilesStore();
  List<RecentFile> _recent = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final list = await _store.load();
    if (mounted) setState(() => _recent = list);
  }

  Future<void> _pick() async {
    setState(() => _busy = true);
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: DocType.supportedExtensions,
      );
      if (file == null) return; // 취소
      final bytes = await file.readAsBytes();
      if (file.path != null) await _store.add(file.name, file.path!);
      if (!mounted) return;
      await _openViewer(file.name, bytes);
    } catch (e) {
      _showError('파일을 열 수 없습니다: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openRecent(RecentFile f) async {
    final file = File(f.path);
    if (!file.existsSync()) {
      await _store.remove(f.path);
      _showError('파일이 이동되었거나 삭제되었습니다.');
      await _refresh();
      return;
    }
    final bytes = await file.readAsBytes();
    await _store.add(f.name, f.path);
    if (!mounted) return;
    await _openViewer(f.name, bytes);
  }

  Future<void> _openViewer(String name, List<int> bytes) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ViewerScreen(fileName: name, bytes: bytes),
      ),
    );
    _refresh();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('문서 뷰어'),
        actions: [
          if (_recent.isNotEmpty)
            IconButton(
              tooltip: '최근 목록 지우기',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () async {
                await _store.clear();
                _refresh();
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _pick,
        icon: _busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.folder_open),
        label: const Text('파일 열기'),
      ),
      body: _recent.isEmpty
          ? _EmptyState(onPick: _pick)
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text('최근 문서',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(color: cs.primary)),
                ),
                for (final f in _recent) _RecentTile(file: f, onTap: () => _openRecent(f)),
              ],
            ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.file, required this.onTap});

  final RecentFile file;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = DocType.fromFileName(file.name);
    final t = file.openedAt;
    final when =
        '${t.year}.${t.month.toString().padLeft(2, '0')}.${t.day.toString().padLeft(2, '0')} '
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: type.color.withValues(alpha: 0.12),
        child: Icon(type.icon, color: type.color),
      ),
      title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${type.label} · $when'),
      onTap: onTap,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onPick});

  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final t in [DocType.pdf, DocType.hwp, DocType.excel])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      children: [
                        Icon(t.icon, size: 44, color: t.color),
                        const SizedBox(height: 6),
                        Text(t.label),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text('PDF, 한글(HWP·HWPX), 엑셀(XLSX·XLS)\n문서를 열어보세요.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.folder_open),
              label: const Text('파일 선택'),
            ),
          ],
        ),
      ),
    );
  }
}
