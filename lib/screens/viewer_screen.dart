import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/doc_type.dart';
import '../viewers/excel_viewer.dart';
import '../viewers/hwp_viewer.dart';
import '../viewers/pdf_viewer.dart';

/// 확장자를 보고 알맞은 뷰어로 보내는 화면
class ViewerScreen extends StatelessWidget {
  ViewerScreen({super.key, required this.fileName, required List<int> bytes})
      : bytes = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);

  final String fileName;
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    switch (DocType.fromFileName(fileName)) {
      case DocType.pdf:
        return PdfViewerPage(fileName: fileName, bytes: bytes);
      case DocType.hwp:
        return HwpViewerPage(fileName: fileName, bytes: bytes);
      case DocType.excel:
        return ExcelViewerPage(fileName: fileName, bytes: bytes);
      case DocType.unknown:
        return Scaffold(
          appBar: AppBar(title: Text(fileName)),
          body: const Center(child: Text('지원하지 않는 파일 형식입니다.')),
        );
    }
  }
}

/// 뷰어들이 함께 쓰는 오류 화면
class ViewerError extends StatelessWidget {
  const ViewerError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text('문서를 열지 못했습니다', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
