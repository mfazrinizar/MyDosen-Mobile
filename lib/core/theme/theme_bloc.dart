import 'package:flutter_bloc/flutter_bloc.dart';
import 'theme_event.dart';
import 'theme_state.dart';
import 'theme_repository.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final ThemeRepository repository;

  ThemeBloc(this.repository) : super(ThemeInitial()) {
    on<LoadThemeEvent>(_onLoad);
    on<ToggleThemeEvent>(_onToggle);
    on<SetThemeEvent>(_onSet);
  }

  Future<void> _onLoad(LoadThemeEvent event, Emitter<ThemeState> emit) async {
    final isDark = await repository.isDarkMode();
    emit(ThemeLoaded(isDark));
  }

  Future<void> _onToggle(ToggleThemeEvent event, Emitter<ThemeState> emit) async {
    final current = state is ThemeLoaded
        ? (state as ThemeLoaded).isDark
        : await repository.isDarkMode();
    final next = !current;
    await repository.setDarkMode(next);
    emit(ThemeLoaded(next));
  }

  Future<void> _onSet(SetThemeEvent event, Emitter<ThemeState> emit) async {
    await repository.setDarkMode(event.isDark);
    emit(ThemeLoaded(event.isDark));
  }
}