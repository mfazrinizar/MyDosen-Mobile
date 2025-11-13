import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mydosen/core/theme/theme_bloc.dart';
import 'package:mydosen/core/theme/theme_event.dart';
import 'package:mydosen/core/theme/theme_repository.dart';
import 'package:mydosen/core/theme/theme_state.dart';

class MockThemeRepository extends Mock implements ThemeRepository {}

void main() {
  late MockThemeRepository mockRepo;
  late ThemeBloc bloc;

  setUp(() {
    mockRepo = MockThemeRepository();
    bloc = ThemeBloc(mockRepo);
  });

  test('initial state is ThemeInitial', () {
    expect(bloc.state, isA<ThemeInitial>());
  });

  blocTest<ThemeBloc, ThemeState>(
    'LoadThemeEvent emits ThemeLoaded with value from repository',
    setUp: () {
      when(() => mockRepo.isDarkMode()).thenAnswer((_) async => true);
    },
    build: () => bloc,
    act: (b) => b.add(LoadThemeEvent()),
    expect: () => [const ThemeLoaded(true)],
  );

  blocTest<ThemeBloc, ThemeState>(
    'ToggleThemeEvent toggles and persists',
    setUp: () {
      when(() => mockRepo.isDarkMode()).thenAnswer((_) async => false);
      when(() => mockRepo.setDarkMode(true)).thenAnswer((_) async {});
    },
    build: () => bloc,
    act: (b) => b.add(ToggleThemeEvent()),
    expect: () => [const ThemeLoaded(true)],
    verify: (_) {
      verify(() => mockRepo.setDarkMode(true)).called(1);
    },
  );
}
