import 'package:shared_preferences/shared_preferences.dart';

abstract class ThemeLocalDataSource {
  Future<bool> getIsDarkMode();
  Future<void> setIsDarkMode(bool isDark);
}

class ThemeLocalDataSourceImpl implements ThemeLocalDataSource {
  final SharedPreferences prefs;
  static const _prefKey = 'isDarkMode';

  ThemeLocalDataSourceImpl(this.prefs);

  @override
  Future<bool> getIsDarkMode() async {
    return prefs.getBool(_prefKey) ?? false;
  }

  @override
  Future<void> setIsDarkMode(bool isDark) async {
    await prefs.setBool(_prefKey, isDark);
  }
}
