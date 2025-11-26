import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _currentTheme;
  final Box _userBox;

  ThemeNotifier(this._currentTheme, this._userBox);

  ThemeMode get currentTheme => _currentTheme;

  Future<void> setTheme(ThemeMode mode) async {
    // Si el tema ya es el mismo, no hagas nada
    if (mode == _currentTheme) return;

    _currentTheme = mode;
    // Notificar a todos los 'listeners' (como MyApp) que el tema cambió
    notifyListeners();

    // Guardar la preferencia en Hive para la próxima vez que se abra la app
    String themeName;
    switch (mode) {
      case ThemeMode.light:
        themeName = 'light';
        break;
      case ThemeMode.dark:
        themeName = 'dark';
        break;
      case ThemeMode.system:
        themeName = 'system';
        break;
    }
    await _userBox.put('theme', themeName);
  }
}
