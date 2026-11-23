#!/usr/bin/env python3
"""flutter_rhwp 안의 cargokit Gradle 스크립트를 Gradle 9 에 맞게 고칩니다.

Gradle 9 에서는 Task 안에서 `project.exec { }` 를 쓸 수 없어서
`Could not find method exec()` 오류로 빌드가 멈춥니다.
ExecOperations 를 주입받아 `execOperations.exec { }` 로 바꿉니다.

`flutter pub get` 다음에 실행하세요:  python3 tool/patch_cargokit.py
"""
import json
import pathlib
from urllib.parse import urlparse, unquote

root = pathlib.Path(__file__).resolve().parent.parent
config = json.loads((root / ".dart_tool" / "package_config.json").read_text())

pkg = next(p for p in config["packages"] if p["name"] == "flutter_rhwp")
uri = pkg["rootUri"]
pkg_dir = (
    pathlib.Path(unquote(urlparse(uri).path))
    if uri.startswith("file:")
    else (root / ".dart_tool" / uri).resolve()
)
f = pkg_dir / "cargokit" / "gradle" / "plugin.gradle"
s = f.read_text(encoding="utf-8")

MARK = "// [doc_viewer] gradle9 patch"
if MARK in s:
    print(f"already patched: {f}")
else:
    head = "abstract class CargoKitBuildTask extends DefaultTask {"
    assert head in s, "cargokit 구조가 바뀌었습니다 — 패치 확인 필요"
    s = s.replace(
        head,
        head
        + f"\n    {MARK}\n"
        + "    @javax.inject.Inject\n"
        + "    abstract org.gradle.process.ExecOperations getExecOperations()\n",
        1,
    )
    n = s.count("project.exec {")
    s = s.replace("project.exec {", "execOperations.exec {")
    f.write_text(s, encoding="utf-8")
    print(f"patched {n} exec call(s): {f}")
