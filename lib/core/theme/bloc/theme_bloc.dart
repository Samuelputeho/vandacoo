import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_state.dart';

enum ThemeEvent { loadTheme, toggleDark, toggleLight }

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(ThemeState.lightTheme) {
    on<ThemeEvent>(_mapEventToState);
    add(ThemeEvent.loadTheme);
  }

  Future<void> _mapEventToState(
      ThemeEvent event, Emitter<ThemeState> emit) async {
    switch (event) {
      case ThemeEvent.loadTheme:
        final themeState = await _loadTheme();
        emit(themeState);
        break;
      case ThemeEvent.toggleDark:
        await _saveTheme('dark');
        emit(ThemeState.darkTheme);
        break;
      case ThemeEvent.toggleLight:
        await _saveTheme('light');
        emit(ThemeState.lightTheme);
        break;
    }
  }

  Future<ThemeState> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('theme') ?? 'light';
    if (theme == 'dark') {
      return ThemeState.darkTheme;
    } else {
      return ThemeState.lightTheme;
    }
  }

  Future<void> _saveTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', theme);
  }
}
