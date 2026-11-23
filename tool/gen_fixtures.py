#!/usr/bin/env python3
"""test_fixtures/ 의 샘플 문서를 통합 테스트용 Dart 상수(base64)로 변환합니다.

통합 테스트는 에뮬레이터 안에서 돌기 때문에 PC의 파일을 직접 읽을 수 없어,
샘플을 코드에 넣어 앱과 함께 설치합니다. (출시용 APK에는 들어가지 않음)

사용법: python3 tool/gen_fixtures.py
"""
import base64
import pathlib

root = pathlib.Path(__file__).resolve().parent.parent
src = root / "test_fixtures"
out = root / "integration_test" / "fixtures.g.dart"

files = ["sample.pdf", "sample.xlsx", "sample.hwp", "sample.hwpx"]
lines = [
    "// 자동 생성 파일 — tool/gen_fixtures.py 로 다시 만드세요.",
    "// ignore_for_file: constant_identifier_names, lines_longer_than_80_chars",
    "import 'dart:convert';",
    "import 'dart:typed_data';",
    "",
    "const _data = <String, String>{",
]
for name in files:
    b64 = base64.b64encode((src / name).read_bytes()).decode()
    lines.append(f"  '{name}': '{b64}',")
lines += [
    "};",
    "",
    "Uint8List fixture(String name) => base64Decode(_data[name]!);",
    "",
]
out.write_text("\n".join(lines), encoding="utf-8")
print(f"wrote {out} ({out.stat().st_size // 1024} KB)")
