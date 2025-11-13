import 'theme_local_data_source.dart';

abstract class ThemeRepository {
  Future<bool> isDarkMode();
  Future<void> setDarkMode(bool isDark);
}

class ThemeRepositoryImpl implements ThemeRepository {
  final ThemeLocalDataSource localDataSource;

  ThemeRepositoryImpl(this.localDataSource);

  @override
  Future<bool> isDarkMode() => localDataSource.getIsDarkMode();

  @override
  Future<void> setDarkMode(bool isDark) =>
      localDataSource.setIsDarkMode(isDark);
}
