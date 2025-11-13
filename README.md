# MyDosen

A concise guide to run, test, and build the MyDosen Flutter app.

## Prerequisites
- Flutter SDK (matching environment in [pubspec.yaml](pubspec.yaml))
- Android Studio / Xcode (for device/emulator)
- Dart & Flutter tools on PATH
- (Optional) VS Code with Flutter extension

## Important - BLoC Architecture
- App entry: [`lib/main.dart`](lib/main.dart) — loads `.env` and initializes DI
- DI container: [`lib/core/di/injection_container.dart`](lib/core/di/injection_container.dart)
- API & Dio factory: [`lib/core/network/api_endpoints.dart`](lib/core/network/api_endpoints.dart)
- Theme: [`lib/core/theme/theme_bloc.dart`](lib/core/theme/theme_bloc.dart), [`lib/core/theme/theme_repository.dart`](lib/core/theme/theme_repository.dart)
- Example env: [`.env.example`](.env.example)
- Tests: [`test/`](test/) (examples: [`test/core/theme/theme_bloc_test.dart`](test/core/theme/theme_bloc_test.dart), [`test/feature/lecturer_location/...`](test/feature/lecturer_location))

## Setup (one-time)
1. Clone project and open in your IDE.
2. Copy environment example:
   - cp .env.example .env
   - Edit `.env` and set keys like `API_URL_PRIMARY`.
3. Install packages:
   - flutter pub get

## Run (development)
- Run on connected device / emulator:
  - flutter run
- Run on specific device:
  - flutter run -d <device_id>

## Build
- Debug APK:
  - flutter build apk --debug
- Release APK:
  - flutter build apk --release
- iOS archive (macOS + Xcode):
  - flutter build ipa

## Tests
- Run all tests:
  - flutter test
- Run a single test file:
  - flutter test test/path/to/test_file.dart
- Common test setup:
  - Mocktail requires registering fallback values for custom parameter types used with `any()` or `captureAny`.
    Example (test setup):
    ```dart
    setUpAll(() {
      registerFallbackValue(NoParams());
    });
    ```

## Notes / Troubleshooting
- Dotenv must be loaded before DI uses ApiEndpoints:
  - Confirm [`lib/main.dart`](lib/main.dart) calls `await dotenv.load(fileName: ".env");` before `await di.init();`.
  - Typical error: `NotInitializedError` from flutter_dotenv if .env isn't loaded.
- DI registers typed clients (e.g., `PrimaryApiClient`) — avoid relying on raw `Dio` from service locator.
- For network retries and logging, see [`lib/core/network/api_endpoints.dart`](lib/core/network/api_endpoints.dart).
- Make sure `org.gradle.java.home` value in [`android\gradle.properties`](android\gradle.properties) is set to your Java JDK path or remove it.