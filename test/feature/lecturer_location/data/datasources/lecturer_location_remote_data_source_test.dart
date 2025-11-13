import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mydosen/core/network/api_endpoints.dart';
import 'package:mydosen/features/lecturer_location/data/datasources/lecturer_location_remote_data_source.dart';
import 'package:mydosen/features/lecturer_location/data/models/lecturer_location_model.dart';

class MockPrimaryApiClient extends Mock implements PrimaryApiClient {}

void main() {
  late MockPrimaryApiClient mockApiClient;
  late LecturerLocationRemoteDataSourceImpl dataSource;

  setUp(() {
    mockApiClient = MockPrimaryApiClient();
    dataSource = LecturerLocationRemoteDataSourceImpl(apiClient: mockApiClient);
  });

  test('returns LecturerLocationModel when response is 200', () async {
    final sampleJson = {
      'location': 'Kampus Indralaya',
      'status': 'OK',
      'updatedAt': '202401010000'
    };

    final response = Response(
      requestOptions: RequestOptions(path: '/dimana.php'),
      data: sampleJson,
      statusCode: 200,
    );

    when(() => mockApiClient.get('/dimana.php'))
        .thenAnswer((_) async => response);

    final result = await dataSource.getLecturerLocation();

    expect(result, isA<LecturerLocationModel>());
    expect(result.location, equals(sampleJson['location']));
  });

  test('throws DioException on non-200', () async {
    final response = Response(
      requestOptions: RequestOptions(path: '/dimana.php'),
      data: {'error': 'bad'},
      statusCode: 500,
    );

    when(() => mockApiClient.get('/dimana.php'))
        .thenAnswer((_) async => response);

    expect(
        () => dataSource.getLecturerLocation(), throwsA(isA<DioException>()));
  });

  test('propagates DioException thrown by client', () async {
    when(() => mockApiClient.get('/dimana.php')).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/dimana.php')));
    expect(
        () => dataSource.getLecturerLocation(), throwsA(isA<DioException>()));
  });
}
