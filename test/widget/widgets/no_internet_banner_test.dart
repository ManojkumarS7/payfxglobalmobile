import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payfxglobal/widgets/no_internet_banner.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('NoInternetScreen Widget Tests', () {
    testWidgets('Renders connection lost message and retry button', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          NoInternetScreen(
            onRetry: () {},
          ),
        ),
      );

      expect(find.text("We're Losing You"), findsOneWidget);
      expect(
        find.text("Connection lost.\nPlease check your internet connection and try again."),
        findsOneWidget,
      );
      expect(find.text("Retry Connection"), findsOneWidget);
    });

    testWidgets('Triggers onRetry callback when Retry Connection button is tapped', (tester) async {
      bool retryTapped = false;

      await tester.pumpWidget(
        createTestWidget(
          NoInternetScreen(
            onRetry: () {
              retryTapped = true;
            },
          ),
        ),
      );

      await tester.tap(find.text("Retry Connection"));
      expect(retryTapped, true);
    });
  });
}
