import 'package:equatable/equatable.dart';

class LecturerLocation extends Equatable {
  final String status;
  final DateTime updatedAt;
  final String location;

  const LecturerLocation({
    required this.status,
    required this.updatedAt,
    required this.location,
  });

  @override
  List<Object?> get props => [status, updatedAt, location];
}
