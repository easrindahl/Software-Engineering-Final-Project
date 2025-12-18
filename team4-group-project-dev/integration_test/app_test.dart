import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to/main.dart';
import 'package:team4_group_project/main.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:team4_group_project/firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:team4_group_project/providers/app_providers.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Flutter App Test', () {
    testWidgets('tap on the create event button, and verify create event page is open', (
      tester,
    ) async {

      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // load app widget with providers
      await tester.pumpWidget(
        MultiProvider(
          providers: appProviders,
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // open create event page and wait for actions to finish
      final fab = find.byKey(const ValueKey('create_event'));
      await tester.tap(fab);
      await tester.pumpAndSettle();

      // verify the test ends up on the create event page
      // by checking for text on the page 
      expect(find.text('Create Event'), findsWidgets);
      expect(find.text('Title'), findsWidgets);
      expect(find.text('Pick Date'), findsWidgets);

    });

    testWidgets('tap on the calendar icon and verify calendar page is open', (
      tester,
    ) async {

      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // load app widget with providers
      await tester.pumpWidget(
        MultiProvider(
          providers: appProviders,
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // tap calendar icon on the nav bar 
      final calendarIcon = find.byIcon(Icons.calendar_today);
      await tester.tap(calendarIcon);
      await tester.pumpAndSettle();

      // verify the test takes us to the calendar page 
      // by checking for 'calendar' text and the calendar table widget
      expect(find.text('Calendar'), findsWidgets);
      expect(find.byType(TableCalendar), findsWidgets);

    });

    testWidgets('tap on the account icon and verify account page is open', (
      tester,
    ) async {
      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // load app widget with providers
      await tester.pumpWidget(
        MultiProvider(providers: appProviders, child: const MyApp()),
      );
      await tester.pumpAndSettle();

      // tap account icon on the nav bar 
      final accountIcon = find.byIcon(Icons.person);
      await tester.tap(accountIcon);
      await tester.pumpAndSettle();

      // verify the test takes us to the account page 
      // by expecting to find 'account' text and the settings icon 
      expect(find.text('Account'), findsWidgets);
      expect(find.byIcon(Icons.settings), findsWidgets);

    });
  });
}