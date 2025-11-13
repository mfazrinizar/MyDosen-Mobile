import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/lecturer_location_model.dart';

abstract class LecturerLocationRemoteDataSource {
  Future<LecturerLocationModel> getLecturerLocation();
}

class LecturerLocationRemoteDataSourceImpl
    implements LecturerLocationRemoteDataSource {
  final ApiClient apiClient;

  LecturerLocationRemoteDataSourceImpl({ApiClient? apiClient})
      : apiClient = apiClient ?? ApiClient(ApiEndpoint.primary);

  @override
  Future<LecturerLocationModel> getLecturerLocation() async {
    try {
      final response = await apiClient.get('/dimana.php');

      if (response.statusCode == 200) {
        return LecturerLocationModel.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'Failed to fetch location data',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
