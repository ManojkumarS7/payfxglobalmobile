import 'package:flutter_test/flutter_test.dart';
import 'package:payfxglobal/features/dashboard/service/dashboard_api_service.dart';

void main() {
  group('Dashboard API Tests', () {
    test('DashboardService instance is created successfully', () {
      final service = DashboardService();
      expect(service, isNotNull);
    });
  });
}
