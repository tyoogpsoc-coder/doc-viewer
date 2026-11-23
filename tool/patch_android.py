#!/usr/bin/env python3
"""`flutter create` 가 만든 android/ 설정을 이 앱에 맞게 고칩니다.

- minSdk 를 24 로 (Rust 엔진·PDF 렌더러 요구사항에 여유 있게)
- 앱 이름을 '문서 뷰어' 로
- 출시 빌드의 lintVital 검사 끄기
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

# 일부 플러그인(webview_all_android)에서 Android lint 도구가 스스로 충돌하므로
# 출시 빌드의 lintVital 검사만 끕니다. (앱 동작과 무관)
LINT_SNIPPET = """
// [doc_viewer] lintVital 비활성화
subprojects {
    tasks.configureEach {
        if (name.startsWith("lintVital")) enabled = false
    }
}
"""
for name in ("build.gradle.kts", "build.gradle"):
    f = root / "android" / name
    if f.exists() and "[doc_viewer] lintVital" not in f.read_text(encoding="utf-8"):
        f.write_text(f.read_text(encoding="utf-8") + LINT_SNIPPET, encoding="utf-8")
        print(f"patched {f}")

manifest = app / "src" / "main" / "AndroidManifest.xml"
if manifest.exists():
    s = manifest.read_text(encoding="utf-8")
    s = re.sub(r'android:label="[^"]*"', 'android:label="문서 뷰어"', s, count=1)
    manifest.write_text(s, encoding="utf-8")
    print(f"patched {manifest}")
