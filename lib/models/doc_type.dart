import 'package:flutter/material.dart';

/// 앱이 지원하는 문서 종류
enum DocType {
  pdf('PDF', Icons.picture_as_pdf, Color(0xFFD93025)),
  hwp('한글', Icons.article, Color(0xFF1A73E8)),
  excel('엑셀', Icons.grid_on, Color(0xFF188038)),
  unknown('기타', Icons.insert_drive_file, Colors.grey);

  const DocType(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  /// 파일 선택기에 넘길 확장자 목록
  static const supportedExtensions = [
    'pdf',
    'hwp',
    'hwpx',
    'xlsx',
    'xlsm',
    'xls',
  ];

  static DocType fromFileName(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0) return DocType.unknown;
    switch (name.substring(dot + 1).toLowerCase()) {
      case 'pdf':
        return DocType.pdf;
      case 'hwp':
      case 'hwpx':
        return DocType.hwp;
      case 'xlsx':
      case 'xlsm':
      case 'xls':
        return DocType.excel;
      default:
        return DocType.unknown;
    }
  }
}
