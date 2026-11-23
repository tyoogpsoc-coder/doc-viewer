// 안드로이드 에뮬레이터에서 실제 네이티브 렌더러(PDF·한글 Rust 엔진)로
// 각 문서를 열어보고 화면을 캡처하는 통합 테스트.
//
// 실행: flutter drive --driver=test_driver/integration_test.dart \
//         --target=integration_test/app_test.dart
import 'dart:io';

import 'package:doc_viewer/main.dart';
import 'package:doc_viewer/screens/viewer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rhwp/flutter_rhwp.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pdfx/pdfx.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures.g.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  var surfaceConverted = false;
  // 테스트마다 화면 캡처 준비를 새로 해야 함
  setUp(() => surfaceConverted = false);

  Future<void> shot(WidgetTester tester, String name) async {
    if (Platform.isAndroid && !surfaceConverted) {
      await binding.convertFlutterSurfaceToImage();
      surfaceConverted = true;
    }
    await tester.pump(const Duration(milliseconds: 500));
    await binding.takeScreenshot(name);
  }

  /// 찾는 위젯이 나타날 때까지 최대 [seconds]초 기다림
  Future<void> waitFor(WidgetTester tester, Finder finder,
      {int seconds = 30}) async {
    final end = DateTime.now().add(Duration(seconds: seconds));
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 200));
      if (finder.evaluate().isNotEmpty) return;
      // 오류 화면이 뜨면 바로 실패 처리
      final err = find.byType(ViewerError);
      if (err.evaluate().isNotEmpty) {
        final texts = find
            .descendant(of: err, matching: find.byType(Text))
            .evaluate()
            .map((e) => (e.widget as Text).data)
            .join(' / ');
        fail('뷰어가 오류를 표시함: $texts');
      }
    }
    fail('시간 초과: $finder');
  }

  Future<void> openViewer(WidgetTester tester, String name) async {
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ViewerScreen(fileName: name, bytes: fixture(name)),
    ));
  }

  testWidgets('1. 홈 화면', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const DocViewerApp());
    await tester.pumpAndSettle();
    expect(find.text('파일 열기'), findsOneWidget);
    await shot(tester, '1_home');
  });

  testWidgets('2. PDF 열기 · 페이지 수 · 페이지 이동', (tester) async {
    await openViewer(tester, 'sample.pdf');
    await waitFor(tester, find.text('1 / 10'));
    expect(find.byType(PdfViewPinch), findsOneWidget);
    await tester.pump(const Duration(seconds: 2)); // 페이지 텍스처 렌더 대기
    await shot(tester, '2_pdf_page1');

    await tester.tap(find.text('1 / 10'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '5');
    await tester.tap(find.text('이동'));
    await tester.pump(const Duration(seconds: 2)); // 이동 애니메이션 + 렌더 대기
    await shot(tester, '3_pdf_page5');
    await waitFor(tester, find.text('5 / 10'));
  });

  testWidgets('3. 엑셀 열기 · 시트 전환 · 셀 상세', (tester) async {
    await openViewer(tester, 'sample.xlsx');
    await waitFor(tester, find.text('노트북'));
    expect(find.text('키보드'), findsOneWidget);
    await shot(tester, '4_excel_sheet1');

    // 화면 폭 안에 보이는 B2 셀(노트북)을 눌러 상세 보기
    await tester.tap(find.text('노트북'));
    await tester.pumpAndSettle();
    expect(find.text('B2'), findsOneWidget);
    expect(find.text('복사'), findsOneWidget);
    await shot(tester, '5_excel_cell_detail');
    Navigator.of(tester.element(find.text('B2'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, '직원'));
    await tester.pumpAndSettle();
    expect(find.text('김철수'), findsOneWidget);
    await shot(tester, '6_excel_sheet2');
  });

  testWidgets('4. 한글 HWP 열기 · 텍스트 보기', (tester) async {
    await openViewer(tester, 'sample.hwp');
    await waitFor(tester, find.byType(RhwpViewer), seconds: 60);
    await waitFor(tester, find.textContaining('쪽'));
    await tester.pump(const Duration(seconds: 3));
    await shot(tester, '7_hwp_page');

    await tester.tap(find.byTooltip('텍스트로 보기'));
    await waitFor(tester, find.textContaining('2021년 평가'), seconds: 60);
    expect(find.textContaining('말뭉치'), findsWidgets);
    await shot(tester, '8_hwp_text');
  });

  testWidgets('5. 한글 HWPX 열기 · 텍스트 보기', (tester) async {
    await openViewer(tester, 'sample.hwpx');
    await waitFor(tester, find.byType(RhwpViewer), seconds: 60);
    await tester.pump(const Duration(seconds: 3));
    await shot(tester, '9_hwpx_page');

    await tester.tap(find.byTooltip('텍스트로 보기'));
    await waitFor(tester, find.textContaining('줄거리'), seconds: 60);
    await shot(tester, '10_hwpx_text');
  });
}
