import 'package:equatable/equatable.dart';
import '../../domain/entities/lecturer_location.dart';

abstract class LecturerLocationState extends Equatable {
  const LecturerLocationState();

  @override
  List<Object> get props => [];
}

class LecturerLocationInitial extends LecturerLocationState {}

class LecturerLocationLoading extends LecturerLocationState {}

class LecturerLocationLoaded extends LecturerLocationState {
  final LecturerLocation location;

  const LecturerLocationLoaded(this.location);

  @override
  List<Object> get props => [location];
}

class LecturerLocationError extends LecturerLocationState {
  final String message;

  const LecturerLocationError(this.message);

  @override
  List<Object> get props => [message];
}

class LecturerLocationRefreshedNoChange extends LecturerLocationState {
  final LecturerLocation location;

  const LecturerLocationRefreshedNoChange(this.location);

  @override
  List<Object> get props => [location];
}
