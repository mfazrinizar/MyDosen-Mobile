import 'package:equatable/equatable.dart';
import '../../domain/entities/tracking_entities.dart';

abstract class MahasiswaState extends Equatable {
  const MahasiswaState();

  @override
  List<Object?> get props => [];
}

class MahasiswaInitial extends MahasiswaState {}

class MahasiswaLoading extends MahasiswaState {}

/// State for dosen list
class DosenListLoaded extends MahasiswaState {
  final List<DosenInfo> dosenList;

  const DosenListLoaded(this.dosenList);

  @override
  List<Object?> get props => [dosenList];
}

/// State for my requests
class MyRequestsLoaded extends MahasiswaState {
  final List<TrackingPermission> requests;

  const MyRequestsLoaded(this.requests);

  @override
  List<Object?> get props => [requests];
}

/// State for allowed dosen with locations
class AllowedDosenLoaded extends MahasiswaState {
  final List<DosenLocation> dosenList;

  const AllowedDosenLoaded(this.dosenList);

  // Create new state with updated dosen location
  AllowedDosenLoaded withUpdatedLocation({
    required String dosenId,
    required double latitude,
    required double longitude,
    required String positionName,
    required DateTime lastUpdated,
  }) {
    final updatedList = dosenList.map((dosen) {
      if (dosen.userId == dosenId) {
        return DosenLocation(
          userId: dosen.userId,
          name: dosen.name,
          nidn: dosen.nidn,
          latitude: latitude,
          longitude: longitude,
          positionName: positionName,
          isOnline: dosen.isOnline,
          lastUpdated: lastUpdated,
        );
      }
      return dosen;
    }).toList();

    return AllowedDosenLoaded(updatedList);
  }

  // Create new state with updated dosen status
  AllowedDosenLoaded withUpdatedStatus({
    required String dosenId,
    required bool isOnline,
  }) {
    final updatedList = dosenList.map((dosen) {
      if (dosen.userId == dosenId) {
        return DosenLocation(
          userId: dosen.userId,
          name: dosen.name,
          nidn: dosen.nidn,
          latitude: dosen.latitude,
          longitude: dosen.longitude,
          positionName: dosen.positionName,
          isOnline: isOnline,
          lastUpdated: dosen.lastUpdated,
        );
      }
      return dosen;
    }).toList();

    return AllowedDosenLoaded(updatedList);
  }

  @override
  List<Object?> get props => [dosenList];
}

/// State for location history
class DosenHistoryLoaded extends MahasiswaState {
  final LocationHistory history;

  const DosenHistoryLoaded(this.history);

  @override
  List<Object?> get props => [history];
}

/// State for successful request submission
class RequestAccessSuccess extends MahasiswaState {
  final String message;
  final String lecturerName;

  const RequestAccessSuccess({
    required this.message,
    required this.lecturerName,
  });

  @override
  List<Object?> get props => [message, lecturerName];
}

/// Error state
class MahasiswaError extends MahasiswaState {
  final String message;

  const MahasiswaError(this.message);

  @override
  List<Object?> get props => [message];
}
