import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../screens/viewer_screen.dart';

class PdfViewerPage extends StatefulWidget {
  const PdfViewerPage({super.key, required this.fileName, required this.bytes});

  final String fileName;
  final Uint8List bytes;

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  late final PdfControllerPinch _controller;

  @override
  void initState() {
    super.initState();
    _controller = PdfControllerPinch(
      document: PdfDocument.openData(widget.bytes),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _askPage(int total) async {
    final textCtrl = TextEditingController();
    final page = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('페이지 이동'),
        content: TextField(
          controller: textCtrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: '1 ~ $total'),
          onSubmitted: (v) => Navigator.pop(ctx, int.tryParse(v)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(textCtrl.text)),
            child: const Text('이동'),
          ),
        ],
      ),
    );
    if (page != null && page >= 1 && page <= total) {
      _controller.jumpToPage(page);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName, overflow: TextOverflow.ellipsis),
        actions: [
          PdfPageNumber(
            controller: _controller,
            builder: (_, loadingState, page, pagesCount) => TextButton(
              onPressed: pagesCount == null ? null : () => _askPage(pagesCount),
              child: Text('$page / ${pagesCount ?? 0}'),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade300,
      body: PdfViewPinch(
        controller: _controller,
        padding: 8,
        builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
          options: const DefaultBuilderOptions(),
          documentLoaderBuilder: (_) =>
              const Center(child: CircularProgressIndicator()),
          pageLoaderBuilder: (_) =>
              const Center(child: CircularProgressIndicator()),
          errorBuilder: (_, error) => ViewerError(message: error.toString()),
        ),
      ),
    );
  }
}
