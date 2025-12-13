import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/tracking_models.dart';

abstract class TrackingRemoteDataSource {
  /// Get list of all dosen for requesting access
  Future<List<DosenInfoModel>> getAllDosen();

  /// Request tracking access to a dosen
  Future<Map<String, dynamic>> requestAccess(String lecturerId);

  /// Get mahasiswa's tracking requests
  Future<List<TrackingPermissionModel>> getMyRequests();

  /// Get list of dosen that mahasiswa has approved access to
  Future<List<DosenLocationModel>> getAllowedDosen();

  /// Get location history of a dosen
  Future<LocationHistoryModel> getDosenHistory(String dosenId);
}

class TrackingRemoteDataSourceImpl implements TrackingRemoteDataSource {
  final ApiClient apiClient;

  TrackingRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<DosenInfoModel>> getAllDosen() async {
    try {
      final response = await apiClient.get(ApiEndpoints.trackingDosen);

      if (response.statusCode == 200) {
        final dosenList = (response.data['dosen'] as List<dynamic>?) ?? [];
        return dosenList
            .map((e) => DosenInfoModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: response.data['error'] ?? 'Failed to get dosen list',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> requestAccess(String lecturerId) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.trackingRequest,
        data: {'lecturer_id': lecturerId},
      );

      if (response.statusCode == 201) {
        return {
          'message': response.data['message'] ?? 'Request submitted',
          'permission_id': response.data['permission_id'] ?? '',
          'lecturer_name': response.data['lecturer_name'] ?? '',
        };
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: response.data['error'] ?? 'Failed to submit request',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<TrackingPermissionModel>> getMyRequests() async {
    try {
      final response = await apiClient.get(ApiEndpoints.trackingMyRequests);

      if (response.statusCode == 200) {
        final requestsList =
            (response.data['requests'] as List<dynamic>?) ?? [];
        return requestsList
            .map((e) =>
                TrackingPermissionModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: response.data['error'] ?? 'Failed to get requests',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<DosenLocationModel>> getAllowedDosen() async {
    try {
      final response = await apiClient.get(ApiEndpoints.trackingAllowedDosen);

      if (response.statusCode == 200) {
        final dosenList = (response.data['dosen'] as List<dynamic>?) ?? [];
        return dosenList
            .map((e) => DosenLocationModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: response.data['error'] ?? 'Failed to get allowed dosen',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<LocationHistoryModel> getDosenHistory(String dosenId) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.trackingHistory,
        queryParameters: {'dosen_id': dosenId},
      );

      if (response.statusCode == 200) {
        return LocationHistoryModel.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: response.data['error'] ?? 'Failed to get history',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
