
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  late Dio dio;
  late DioAdapter dioAdapter;

  setUp(() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.test.com',
      ),
    );

    dioAdapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = dioAdapter;
  });

  group('API Service Tests', () {
    test('Should return successful response - 200', () async {
      dioAdapter.onGet(
        '/users',
            (server) => server.reply(
          200,
          {
            'status': true,
            'message': 'Success',
            'data': [
              {'id': 1, 'name': 'John'}
            ],
          },
        ),
      );

      final response = await dio.get('/users');

      expect(response.statusCode, 200);
      expect(response.data['status'], true);
      expect(response.data['data'][0]['name'], 'John');
    });

    test('Should handle bad request - 400', () async {
      dioAdapter.onGet(
        '/users',
            (server) => server.reply(
          400,
          {
            'status': false,
            'message': 'Invalid request',
          },
        ),
      );

      expect(
            () => dio.get('/users'),
        throwsA(isA<DioException>()),
      );
    });
  });
}
