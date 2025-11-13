import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_lecturer_location.dart';
import '../../domain/entities/lecturer_location.dart';
import 'lecturer_location_event.dart';
import 'lecturer_location_state.dart';

class LecturerLocationBloc
    extends Bloc<LecturerLocationEvent, LecturerLocationState> {
  final GetLecturerLocation getLecturerLocation;

  LecturerLocation? _lastLocation;

  LecturerLocationBloc({
    required this.getLecturerLocation,
  }) : super(LecturerLocationInitial()) {
    on<GetLecturerLocationEvent>(_onGetLecturerLocation);
    on<RefreshLecturerLocationEvent>(_onRefreshLecturerLocation);
  }

  Future<void> _onGetLecturerLocation(
    GetLecturerLocationEvent event,
    Emitter<LecturerLocationState> emit,
  ) async {
    emit(LecturerLocationLoading());

    final result = await getLecturerLocation(NoParams());

    result.fold(
      (failure) => emit(LecturerLocationError(failure.message)),
      (location) {
        _lastLocation = location;
        emit(LecturerLocationLoaded(location));
      },
    );
  }

  Future<void> _onRefreshLecturerLocation(
    RefreshLecturerLocationEvent event,
    Emitter<LecturerLocationState> emit,
  ) async {
    final result = await getLecturerLocation(NoParams());

    result.fold(
      (failure) => emit(LecturerLocationError(failure.message)),
      (location) {
        if (_lastLocation != null && _lastLocation == location) {
          emit(LecturerLocationRefreshedNoChange(location));
        } else {
          _lastLocation = location;
          emit(LecturerLocationLoaded(location));
        }
      },
    );
  }
}
