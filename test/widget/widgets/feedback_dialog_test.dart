import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payfxglobal/widgets/feedback_dialog.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('FeedbackDialog Widget Tests', () {
    testWidgets('Displays Share Your Feedback title and 5 star rating buttons', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          FeedbackDialog(
            onSubmit: (rating, comment) {},
          ),
        ),
      );

      expect(find.text('Share Your Feedback'), findsOneWidget);
      expect(find.text('How was your experience with PayFX Global?'), findsOneWidget);
      expect(find.byIcon(Icons.star_border), findsNWidgets(5));
      expect(find.text('Maybe Later'), findsOneWidget);
      expect(find.text('Submit'), findsOneWidget);
    });

    testWidgets('Selects star rating, accepts comment, and calls onSubmit', (tester) async {
      int submittedRating = 0;
      String submittedComment = '';

      await tester.pumpWidget(
        createTestWidget(
          FeedbackDialog(
            onSubmit: (rating, comment) {
              submittedRating = rating;
              submittedComment = comment;
            },
          ),
        ),
      );

      // Tap 4th star (rating = 4)
      final stars = find.byIcon(Icons.star_border);
      await tester.tap(stars.at(3));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star), findsNWidgets(4));
      expect(find.byIcon(Icons.star_border), findsNWidgets(1));

      // Enter comment
      await tester.enterText(find.byType(TextField), 'Great service and quick transfers!');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(submittedRating, 4);
      expect(submittedComment, 'Great service and quick transfers!');
    });

    testWidgets('Closes dialog when Maybe Later is tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => FeedbackDialog(
                      onSubmit: (_, __) {},
                    ),
                  );
                },
                child: const Text('Open Feedback'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Feedback'));
      await tester.pumpAndSettle();

      expect(find.text('Share Your Feedback'), findsOneWidget);

      await tester.tap(find.text('Maybe Later'));
      await tester.pumpAndSettle();

      expect(find.text('Share Your Feedback'), findsNothing);
    });
  });
}
