import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mydosen/core/theme/theme_local_data_source.dart';
import 'package:mydosen/core/theme/theme_repository.dart';

class MockLocalDS extends Mock implements ThemeLocalDataSource {}

void main() {
  late MockLocalDS mockLocal;
  late ThemeRepositoryImpl repo;

  setUp(() {
    mockLocal = MockLocalDS();
    repo = ThemeRepositoryImpl(mockLocal);
  });

  test('isDarkMode returns value from local datasource', () async {
    when(() => mockLocal.getIsDarkMode()).thenAnswer((_) async => true);
    final res = await repo.isDarkMode();
    expect(res, true);
    verify(() => mockLocal.getIsDarkMode()).called(1);
  });

  test('setDarkMode forwards to local datasource', () async {
    when(() => mockLocal.setIsDarkMode(false)).thenAnswer((_) async => {});
    await repo.setDarkMode(false);
    verify(() => mockLocal.setIsDarkMode(false)).called(1);
  });
}
