import 'package:equatable/equatable.dart';

abstract class MahasiswaEvent extends Equatable {
  const MahasiswaEvent();

  @override
  List<Object?> get props => [];
}

/// Load all dosen for request list
class LoadAllDosenEvent extends MahasiswaEvent {}

/// Request tracking access to a dosen
class RequestAccessEvent extends MahasiswaEvent {
  final String lecturerId;

  const RequestAccessEvent(this.lecturerId);

  @override
  List<Object?> get props => [lecturerId];
}

/// Load mahasiswa's tracking requests
class LoadMyRequestsEvent extends MahasiswaEvent {}

/// Load allowed dosen with locations
class LoadAllowedDosenEvent extends MahasiswaEvent {}

/// Refresh allowed dosen list
class RefreshAllowedDosenEvent extends MahasiswaEvent {}

/// Load dosen location history
class LoadDosenHistoryEvent extends MahasiswaEvent {
  final String dosenId;

  const LoadDosenHistoryEvent(this.dosenId);

  @override
  List<Object?> get props => [dosenId];
}

/// Update dosen location from socket
class UpdateDosenLocationEvent extends MahasiswaEvent {
  final String dosenId;
  final double latitude;
  final double longitude;
  final String positionName;
  final String lastUpdated;

  const UpdateDosenLocationEvent({
    required this.dosenId,
    required this.latitude,
    required this.longitude,
    required this.positionName,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props =>
      [dosenId, latitude, longitude, positionName, lastUpdated];
}

/// Update dosen online status from socket
class UpdateDosenStatusEvent extends MahasiswaEvent {
  final String dosenId;
  final bool isOnline;

  const UpdateDosenStatusEvent({
    required this.dosenId,
    required this.isOnline,
  });

  @override
  List<Object?> get props => [dosenId, isOnline];
}
