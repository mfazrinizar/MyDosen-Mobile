import 'package:intl/intl.dart';
import '../../domain/entities/lecturer_location.dart';

class LecturerLocationModel extends LecturerLocation {
  const LecturerLocationModel({
    required super.status,
    required super.updatedAt,
    required super.location,
  });

  factory LecturerLocationModel.fromJson(Map<String, dynamic> json) {
    return LecturerLocationModel(
      status: json['status'] as String,
      updatedAt: _parseDateTime(json['updatedAt'] as String),
      location: json['location'] as String,
    );
  }

  static DateTime _parseDateTime(String dateTimeStr) {
    // Format: 202611071405 (YYYYMMDDHHmm)
    final year = int.parse(dateTimeStr.substring(0, 4));
    final month = int.parse(dateTimeStr.substring(4, 6));
    final day = int.parse(dateTimeStr.substring(6, 8));
    final hour = int.parse(dateTimeStr.substring(8, 10));
    final minute = int.parse(dateTimeStr.substring(10, 12));

    return DateTime(year, month, day, hour, minute);
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'updatedAt': DateFormat('yyyyMMddHHmm').format(updatedAt),
      'location': location,
    };
  }
}
