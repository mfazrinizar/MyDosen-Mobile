import 'package:equatable/equatable.dart';

abstract class ThemeState extends Equatable {
  const ThemeState();
  @override
  List<Object?> get props => [];
}

class ThemeInitial extends ThemeState {}

class ThemeLoaded extends ThemeState {
  final bool isDark;
  const ThemeLoaded(this.isDark);
  @override
  List<Object?> get props => [isDark];
}
