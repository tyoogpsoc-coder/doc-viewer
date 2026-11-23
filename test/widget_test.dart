import 'dart:io';

import 'package:doc_viewer/main.dart';
import 'package:doc_viewer/models/doc_type.dart';
import 'package:doc_viewer/viewers/excel_viewer.dart';
import 'package:excel_plus/excel_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('DocType', () {
    test('확장자로 문서 종류 판별', () {
      expect(DocType.fromFileName('a.pdf'), DocType.pdf);
      expect(DocType.fromFileName('A.PDF'), DocType.pdf);
      expect(DocType.fromFileName('보고서.hwp'), DocType.hwp);
      expect(DocType.fromFileName('보고서.HWPX'), DocType.hwp);
      expect(DocType.fromFileName('x.xlsx'), DocType.excel);
      expect(DocType.fromFileName('x.xls'), DocType.excel);
      expect(DocType.fromFileName('x.xlsm'), DocType.excel);
      expect(DocType.fromFileName('x.docx'), DocType.unknown);
      expect(DocType.fromFileName('noext'), DocType.unknown);
    });
  });

  group('엑셀 표시 형식', () {
    test('열 이름', () {
      expect(colName(0), 'A');
      expect(colName(25), 'Z');
      expect(colName(26), 'AA');
      expect(colName(701), 'ZZ');
      expect(colName(702), 'AAA');
    });

    test('셀 값 문자열', () {
      expect(formatCell(null), '');
      expect(formatCell(IntCellValue(42)), '42');
      expect(formatCell(DoubleCellValue(3.0)), '3');
      expect(formatCell(DoubleCellValue(3.14159)), '3.14159');
      expect(formatCell(BoolCellValue(true)), 'TRUE');
      expect(formatCell(TextCellValue('안녕')), '안녕');
    });

    test('샘플 xlsx 파싱', () {
      final bytes = File('test_fixtures/sample.xlsx').readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);
      expect(excel.tables.keys, containsAll(['매출', '직원']));
      final sheet = excel.tables['매출']!;
      expect(formatCell(sheet.rows[0][0]?.value), '월');
      expect(formatCell(sheet.rows[1][1]?.value), '노트북');
      expect(formatCell(sheet.rows[1][2]?.value), '3');
      expect(formatCell(sheet.rows[1][4]?.value), contains('C2*D2'));
    });
  });

  testWidgets('홈 화면 표시', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const DocViewerApp());
    await tester.pumpAndSettle();
    expect(find.text('문서 뷰어'), findsOneWidget);
    expect(find.text('파일 열기'), findsOneWidget);
    expect(find.textContaining('PDF, 한글'), findsOneWidget);
  });

  testWidgets('엑셀 뷰어: 시트·셀 표시, 시트 전환', (tester) async {
    final bytes = File('test_fixtures/sample.xlsx').readAsBytesSync();
    await tester.pumpWidget(MaterialApp(
      home: ExcelViewerPage(fileName: 'sample.xlsx', bytes: bytes),
    ));
    // decodeBytesAsync 는 실제 비동기 작업이라 runAsync 안에서 기다림
    for (var i = 0; i < 50 && find.text('노트북').evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    }
    expect(find.text('노트북'), findsOneWidget);
    expect(find.text('A'), findsOneWidget); // 열 머리글
    expect(find.widgetWithText(ChoiceChip, '직원'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, '직원'));
    await tester.pump();
    expect(find.text('김철수'), findsOneWidget);
  });
}
