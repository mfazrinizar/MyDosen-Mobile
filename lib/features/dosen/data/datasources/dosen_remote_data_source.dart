import 'package:flutter/foundation.dart' show kDebugMode;

import '../../../../core/network/api_endpoints.dart';
import '../models/dosen_models.dart';

abstract class DosenRemoteDataSource {
  /// GET /tracking/pending
  Future<List<TrackingRequestModel>> getPendingRequests();

  /// POST /tracking/handle
  Future<Map<String, dynamic>> handleRequest({
    required String permissionId,
    required String action,
  });

  /// GET /tracking/history (for dosen, no query param needed)
  Future<List<DosenLocationHistoryModel>> getOwnHistory();

  /// GET /tracking/students - Get students who can track this dosen
  Future<List<TrackingStudentModel>> getTrackingStudents();
}

class DosenRemoteDataSourceImpl implements DosenRemoteDataSource {
  final AuthenticatedApiClient apiClient;

  DosenRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<TrackingRequestModel>> getPendingRequests() async {
    try {
      final response = await apiClient.dio.get(ApiEndpoints.trackingPending);

      if (response.statusCode == 200) {
        final List<dynamic> requestsJson = response.data['requests'] ?? [];
        return requestsJson
            .map((json) => TrackingRequestModel.fromJson(json))
            .toList();
      }
      throw Exception(response.data['error'] ?? 'Failed to fetch requests');
    } catch (e) {
      if (kDebugMode) {
        throw Exception('Failed to fetch pending requests: $e');
      } else {
        throw Exception('Gagal mengambil permintaan yang tertunda');
      }
    }
  }

  @override
  Future<Map<String, dynamic>> handleRequest({
    required String permissionId,
    required String action,
  }) async {
    try {
      final response = await apiClient.dio.post(
        ApiEndpoints.trackingHandle,
        data: {
          'permission_id': permissionId,
          'action': action,
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception(response.data['error'] ?? 'Failed to handle request');
    } catch (e) {
      throw Exception('Failed to handle request: $e');
    }
  }

  @override
  Future<List<DosenLocationHistoryModel>> getOwnHistory() async {
    try {
      final response = await apiClient.dio.get(ApiEndpoints.trackingHistory);

      if (response.statusCode == 200) {
        final List<dynamic> historyJson = response.data['history'] ?? [];
        return historyJson
            .map((json) => DosenLocationHistoryModel.fromJson(json))
            .toList();
      }
      throw Exception(response.data['error'] ?? 'Failed to fetch history');
    } catch (e) {
      if (kDebugMode) {
        throw Exception('Failed to fetch own history: $e');
      } else {
        throw Exception('Gagal mengambil riwayat lokasi');
      }
    }
  }

  @override
  Future<List<TrackingStudentModel>> getTrackingStudents() async {
    try {
      final response = await apiClient.dio.get(ApiEndpoints.trackingStudents);

      if (response.statusCode == 200) {
        final List<dynamic> studentsJson = response.data['students'] ?? [];
        return studentsJson
            .map((json) => TrackingStudentModel.fromJson(json))
            .toList();
      }
      throw Exception(response.data['error'] ?? 'Failed to fetch students');
    } catch (e) {
      if (kDebugMode) {
        throw Exception('Failed to fetch tracking students: $e');
      } else {
        throw Exception('Gagal mengambil daftar mahasiswa yang melacak');
      }
    }
  }
}
