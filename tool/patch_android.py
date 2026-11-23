#!/usr/bin/env python3
"""`flutter create` 가 만든 android/ 설정을 이 앱에 맞게 고칩니다.

- minSdk 를 24 로 (Rust 엔진·PDF 렌더러 요구사항에 여유 있게)
- 앱 이름을 '문서 뷰어' 로
"""
import pathlib
import re

root = pathlib.Path(__file__).resolve().parent.parent
app = root / "android" / "app"

for name in ("build.gradle.kts", "build.gradle"):
    f = app / name
    if not f.exists():
        continue
    s = f.read_text(encoding="utf-8")
    s = re.sub(r"minSdk(Version)?\s*=?\s*flutter\.minSdkVersion", "minSdk = 24", s)
    s = re.sub(r"minSdkVersion\s+flutter\.minSdkVersion", "minSdkVersion 24", s)
    f.write_text(s, encoding="utf-8")
    print(f"patched {f}")

manifest = app / "src" / "main" / "AndroidManifest.xml"
if manifest.exists():
    s = manifest.read_text(encoding="utf-8")
    s = re.sub(r'android:label="[^"]*"', 'android:label="문서 뷰어"', s, count=1)
    manifest.write_text(s, encoding="utf-8")
    print(f"patched {manifest}")
