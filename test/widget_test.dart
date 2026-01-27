import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_another_day/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    // Mock SharedPreferences for tests
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'GameScreen displays character stats',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      // Wait for async initialization to complete
      await tester.pumpAndSettle();

      // Should display the app title
      expect(find.text('Just Another Day'), findsOneWidget);

      // Should display character name
      expect(find.text('Player'), findsOneWidget);

      // Should display all stat labels
      expect(find.text('Strength'), findsOneWidget);
      expect(find.text('Intelligence'), findsOneWidget);
      expect(find.text('Endurance'), findsOneWidget);
      expect(find.text('Charisma'), findsOneWidget);
      expect(find.text('Agility'), findsOneWidget);

      // Should display activities section
      expect(find.text('Activities'), findsOneWidget);
      expect(find.text('Current Activity'), findsOneWidget);
    },
  );

  testWidgets(
    'GameScreen displays available activities',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      // Wait for async initialization to complete
      await tester.pumpAndSettle();

      // Should display pre-defined activities
      expect(find.text('Working'), findsOneWidget);
      expect(find.text('Studying'), findsOneWidget);
      expect(find.text('Exercising'), findsOneWidget);
      expect(find.text('Socializing'), findsOneWidget);
    },
  );

  testWidgets(
    'GameScreen can start an activity',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      // Wait for async initialization to complete
      await tester.pumpAndSettle();

      // Initially no activity
      expect(
        find.text('No activity in progress. Select an activity below.'),
        findsOneWidget,
      );

      // Find and tap the first Start button (Working activity)
      final startButtons = find.widgetWithText(ElevatedButton, 'Start');
      await tester.ensureVisible(startButtons.first);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(startButtons.first);
      await tester.pump();

      // Should now show activity progress
      expect(
        find.text('No activity in progress. Select an activity below.'),
        findsNothing,
      );
      expect(find.text('Stop Activity'), findsOneWidget);
    },
  );

  testWidgets(
    'GameScreen can stop an activity',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      // Wait for async initialization to complete
      await tester.pumpAndSettle();

      // Start an activity
      final startButtons = find.widgetWithText(ElevatedButton, 'Start');
      await tester.ensureVisible(startButtons.first);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(startButtons.first);
      await tester.pump();

      // Stop the activity
      final stopButton = find.text('Stop Activity');
      await tester.ensureVisible(stopButton);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(stopButton);
      await tester.pump();

      // Should show no activity message again
      expect(
        find.text('No activity in progress. Select an activity below.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'GameScreen has pause/resume button',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      // Wait for async initialization to complete
      await tester.pumpAndSettle();

      // Should find pause button in app bar
      final pauseButton = find.byIcon(Icons.pause);
      expect(pauseButton, findsOneWidget);

      // Tap to pause
      await tester.tap(pauseButton);
      await tester.pump();

      // Should now show play icon
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    },
  );

  testWidgets(
    'GameScreen has auto-repeat toggle',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      // Wait for async initialization to complete
      await tester.pumpAndSettle();

      expect(find.text('Auto-repeat'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    },
  );
}
