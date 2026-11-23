import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// 통합 테스트가 찍은 화면을 screenshots/ 폴더에 PNG로 저장
Future<void> main() async {
  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
      final file = File('screenshots/$name.png');
      file.createSync(recursive: true);
      file.writeAsBytesSync(bytes);
      return true;
    },
  );
}
