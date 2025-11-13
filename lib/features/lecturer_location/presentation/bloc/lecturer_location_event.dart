import 'package:equatable/equatable.dart';

abstract class LecturerLocationEvent extends Equatable {
  const LecturerLocationEvent();

  @override
  List<Object> get props => [];
}

class GetLecturerLocationEvent extends LecturerLocationEvent {}

class RefreshLecturerLocationEvent extends LecturerLocationEvent {}
