import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../domain/usecases/tracking_usecases.dart';
import 'mahasiswa_event.dart';
import 'mahasiswa_state.dart';

class MahasiswaBloc extends Bloc<MahasiswaEvent, MahasiswaState> {
  final GetAllDosen getAllDosen;
  final RequestTrackingAccess requestTrackingAccess;
  final GetMyRequests getMyRequests;
  final GetAllowedDosen getAllowedDosen;
  final GetDosenHistory getDosenHistory;

  MahasiswaBloc({
    required this.getAllDosen,
    required this.requestTrackingAccess,
    required this.getMyRequests,
    required this.getAllowedDosen,
    required this.getDosenHistory,
  }) : super(MahasiswaInitial()) {
    on<LoadAllDosenEvent>(_onLoadAllDosen);
    on<RequestAccessEvent>(_onRequestAccess);
    on<LoadMyRequestsEvent>(_onLoadMyRequests);
    on<LoadAllowedDosenEvent>(_onLoadAllowedDosen);
    on<RefreshAllowedDosenEvent>(_onRefreshAllowedDosen);
    on<LoadDosenHistoryEvent>(_onLoadDosenHistory);
    on<UpdateDosenLocationEvent>(_onUpdateDosenLocation);
    on<UpdateDosenStatusEvent>(_onUpdateDosenStatus);
  }

  Future<void> _onLoadAllDosen(
    LoadAllDosenEvent event,
    Emitter<MahasiswaState> emit,
  ) async {
    emit(MahasiswaLoading());

    final result = await getAllDosen(NoParams());

    result.fold(
      (failure) => emit(MahasiswaError(failure.message)),
      (dosenList) => emit(DosenListLoaded(dosenList)),
    );
  }

  Future<void> _onRequestAccess(
    RequestAccessEvent event,
    Emitter<MahasiswaState> emit,
  ) async {
    emit(MahasiswaLoading());

    final result = await requestTrackingAccess(event.lecturerId);

    result.fold(
      (failure) => emit(MahasiswaError(failure.message)),
      (response) => emit(RequestAccessSuccess(
        message: response['message'] ?? 'Permintaan berhasil diajukan',
        lecturerName: response['lecturer_name'] ?? '',
      )),
    );
  }

  Future<void> _onLoadMyRequests(
    LoadMyRequestsEvent event,
    Emitter<MahasiswaState> emit,
  ) async {
    emit(MahasiswaLoading());

    final result = await getMyRequests(NoParams());

    result.fold(
      (failure) => emit(MahasiswaError(failure.message)),
      (requests) => emit(MyRequestsLoaded(requests)),
    );
  }

  Future<void> _onLoadAllowedDosen(
    LoadAllowedDosenEvent event,
    Emitter<MahasiswaState> emit,
  ) async {
    emit(MahasiswaLoading());

    final result = await getAllowedDosen(NoParams());

    result.fold(
      (failure) => emit(MahasiswaError(failure.message)),
      (dosenList) => emit(AllowedDosenLoaded(dosenList)),
    );
  }

  Future<void> _onRefreshAllowedDosen(
    RefreshAllowedDosenEvent event,
    Emitter<MahasiswaState> emit,
  ) async {
    // Don't show loading state for refresh
    final result = await getAllowedDosen(NoParams());

    result.fold(
      (failure) => emit(MahasiswaError(failure.message)),
      (dosenList) => emit(AllowedDosenLoaded(dosenList)),
    );
  }

  Future<void> _onLoadDosenHistory(
    LoadDosenHistoryEvent event,
    Emitter<MahasiswaState> emit,
  ) async {
    emit(MahasiswaLoading());

    final result = await getDosenHistory(event.dosenId);

    result.fold(
      (failure) => emit(MahasiswaError(failure.message)),
      (history) => emit(DosenHistoryLoaded(history)),
    );
  }

  void _onUpdateDosenLocation(
    UpdateDosenLocationEvent event,
    Emitter<MahasiswaState> emit,
  ) {
    if (state is AllowedDosenLoaded) {
      final currentState = state as AllowedDosenLoaded;
      final updatedState = currentState.withUpdatedLocation(
        dosenId: event.dosenId,
        latitude: event.latitude,
        longitude: event.longitude,
        positionName: event.positionName,
        lastUpdated:
            DateTimeUtils.parseBackendDate(event.lastUpdated) ?? DateTime.now(),
      );
      emit(updatedState);
    }
  }

  void _onUpdateDosenStatus(
    UpdateDosenStatusEvent event,
    Emitter<MahasiswaState> emit,
  ) {
    if (state is AllowedDosenLoaded) {
      final currentState = state as AllowedDosenLoaded;
      final updatedState = currentState.withUpdatedStatus(
        dosenId: event.dosenId,
        isOnline: event.isOnline,
      );
      emit(updatedState);
    }
  }
}
