# 문서 뷰어 (PDF · 한글 · 엑셀)

Flutter로 만든 Android/iOS 문서 뷰어입니다.

| 형식 | 확장자 | 라이브러리 | 기능 |
|---|---|---|---|
| PDF | .pdf | `pdfx` | 핀치 줌(확대해도 선명), 페이지 번호, 페이지 이동 |
| 한글 | .hwp, .hwpx | `flutter_rhwp` (Rust rhwp 엔진) | 페이지 렌더링, 텍스트로 보기·전체 복사 |
| 엑셀 | .xlsx, .xlsm, .xls | `excel_plus` | 시트 탭, 확대/축소, 셀 눌러 값·수식 보기/복사 |

홈 화면에는 최근 연 문서 20개가 남습니다.

## 준비물

1. **Flutter 3.35 이상** — https://docs.flutter.dev/get-started/install
2. **Rust** — `flutter_rhwp`가 Rust 엔진을 앱 빌드 때 함께 컴파일하므로 필요합니다.
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android   # Android
   rustup target add aarch64-apple-ios aarch64-apple-ios-sim                              # iOS (Mac)
   ```
3. Android: Android Studio + NDK / iOS: Xcode (Mac 필요)

## 실행 방법

```bash
cd doc_viewer
# Android/iOS 플랫폼 폴더 생성 (lib/, pubspec.yaml은 그대로 유지됨)
flutter create --platforms=android,ios --org com.example .
flutter pub get
python3 tool/patch_android.py    # minSdk 24, 앱 이름, lint 설정
python3 tool/patch_cargokit.py   # 한글 엔진 빌드 스크립트 Gradle 9 대응
flutter run
```

### 빌드가 실패하면

- **Android minSdk 오류** → `android/app/build.gradle(.kts)`에서 `minSdk = 24` 로 올리세요.
- **NDK 버전 오류** → 오류 메시지가 요구하는 `ndkVersion`을 같은 파일에 적어주세요.
- **iOS** → `ios/Podfile` 맨 위의 `platform :ios` 를 `'13.0'` 이상으로.
- **flutter_rhwp 관련 API 이름이 다르다는 오류** → 패키지가 빠르게 바뀌는 중이라
  버전에 따라 이름이 다를 수 있습니다. 수정할 곳은 `lib/viewers/hwp_viewer.dart` 한 파일뿐입니다.

## 폴더 구조

```
lib/
  main.dart                 앱 시작, 테마(라이트/다크)
  models/doc_type.dart      확장자 → 문서 종류
  models/recent_files.dart  최근 문서 저장
  screens/home_screen.dart  홈(파일 열기, 최근 문서)
  screens/viewer_screen.dart 형식별 뷰어로 분기
  viewers/pdf_viewer.dart
  viewers/hwp_viewer.dart
  viewers/excel_viewer.dart
```

## 알아둘 점

- 한글 렌더링은 오픈소스 엔진이라 복잡한 표·도형이 있는 문서는 한컴오피스와 조금 다르게 보일 수 있습니다.
  그럴 땐 상단의 **텍스트로 보기** 버튼을 쓰세요.
- 엑셀은 값을 보여주는 뷰어입니다. 셀 색·테두리·병합·차트는 표시하지 않습니다.
- 암호가 걸린 문서는 지원하지 않습니다.

## 다음 단계 아이디어

- 다른 앱(카카오톡, 파일 앱)에서 **"다른 앱으로 열기"** 로 바로 열기 — Android intent-filter / iOS Document Types 설정 + `receive_sharing_intent` 패키지
- 문서 내 검색, 북마크, 공유 버튼
