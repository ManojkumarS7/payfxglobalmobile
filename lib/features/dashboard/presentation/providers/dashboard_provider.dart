import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payfxglobal/features/dashboard/service/dashboard_api_service.dart';

final dashboardServiceProvider = Provider<DashboardService>((ref) {
  return DashboardService();
});

final dashboardDataProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final service = ref.watch(dashboardServiceProvider);
  return await service.getDashboardData();
});
