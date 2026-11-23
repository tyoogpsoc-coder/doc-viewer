import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rhwp/flutter_rhwp.dart';

import '../screens/viewer_screen.dart';

/// 한글(HWP 5.0 / HWPX) 뷰어.
/// flutter_rhwp(Rust rhwp 엔진)로 페이지를 렌더링하고,
/// 렌더링이 어색한 문서를 위해 "텍스트로 보기" 모드도 제공합니다.
class HwpViewerPage extends StatefulWidget {
  const HwpViewerPage({super.key, required this.fileName, required this.bytes});

  final String fileName;
  final Uint8List bytes;

  @override
  State<HwpViewerPage> createState() => _HwpViewerPageState();
}

class _HwpViewerPageState extends State<HwpViewerPage> {
  // Rhwp.open()이 돌려주는 문서 객체.
  // 패키지 버전에 따라 클래스 이름이 다를 수 있어 dynamic으로 둡니다.
  dynamic _doc;
  int? _pageCount;
  String? _error;
  String? _text; // null 이면 페이지 모드
  bool _loadingText = false;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    try {
      final doc = await Rhwp.open(widget.bytes, fileName: widget.fileName);
      final count = await doc.pageCount;
      if (!mounted) {
        await doc.close();
        return;
      }
      setState(() {
        _doc = doc;
        _pageCount = count as int?;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _toggleTextMode() async {
    if (_text != null) {
      setState(() => _text = null);
      return;
    }
    setState(() => _loadingText = true);
    try {
      final t = await _doc.extractText();
      if (mounted) setState(() => _text = t as String);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('텍스트 추출 실패: $e')));
      }
    } finally {
      if (mounted) setState(() => _loadingText = false);
    }
  }

  @override
  void dispose() {
    _doc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName, overflow: TextOverflow.ellipsis),
        actions: [
          if (_pageCount != null && _text == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('$_pageCount쪽'),
              ),
            ),
          if (_doc != null)
            IconButton(
              tooltip: _text == null ? '텍스트로 보기' : '페이지로 보기',
              icon: _loadingText
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(_text == null ? Icons.notes : Icons.description),
              onPressed: _loadingText ? null : _toggleTextMode,
            ),
          if (_text != null)
            IconButton(
              tooltip: '전체 복사',
              icon: const Icon(Icons.copy),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _text!));
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('복사했습니다')));
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) return ViewerError(message: _error!);
    if (_doc == null) return const Center(child: CircularProgressIndicator());
    if (_text != null) {
      return SelectionArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [Text(_text!, style: const TextStyle(fontSize: 15, height: 1.6))],
        ),
      );
    }
    return ColoredBox(
      color: Colors.grey.shade300,
      child: RhwpViewer(document: _doc),
    );
  }
}
