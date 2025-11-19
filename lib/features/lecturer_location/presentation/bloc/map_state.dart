part of 'map_cubit.dart';

class MapState extends Equatable {
  final bool ready;
  final String? error;

  const MapState({required this.ready, this.error});

  const MapState.initial()
      : ready = false,
        error = null;
  const MapState.ready()
      : ready = true,
        error = null;
  const MapState.error(String message)
      : ready = false,
        error = message;

  @override
  List<Object?> get props => [ready, error];
}
