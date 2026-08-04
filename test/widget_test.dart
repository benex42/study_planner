import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_planner/network_loading.dart';
import 'package:study_planner/main.dart';
import 'package:study_planner/schedule_page.dart';
import 'package:study_planner/floating_tab_bar.dart';

Future<void> finishAppLaunch(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 2200));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the splash only while a tracked request is pending', (
    WidgetTester tester,
  ) async {
    final controller = NetworkActivityController();
    final response = Completer<void>();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: NetworkLoadingScope(
          controller: controller,
          child: const NetworkLoadingOverlay(child: Placeholder()),
        ),
      ),
    );

    controller.track(response.future);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    response.complete();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  test('clears the loading state when a tracked request fails', () async {
    final controller = NetworkActivityController();
    addTearDown(controller.dispose);

    final request = controller.track<void>(
      Future<void>.error(StateError('Backend unavailable')),
    );

    expect(controller.isLoading, isTrue);
    await expectLater(request, throwsStateError);
    expect(controller.isLoading, isFalse);
  });

  testWidgets('renders the StudyHub login page', (WidgetTester tester) async {
    await tester.pumpWidget(const StudyHubApp());
    expect(find.bySemanticsLabel('Opening StudyHub'), findsOneWidget);
    await finishAppLaunch(tester);

    expect(find.text('StudyHub'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);
    expect(find.text('Apple'), findsOneWidget);
  });

  testWidgets('changes theme preferences from Settings', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const StudyHubApp());
    await finishAppLaunch(tester);

    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Theme preference: System Default'));
    await tester.pumpAndSettle();

    expect(find.text('Light'), findsWidgets);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('System Default'), findsWidgets);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Theme preference: Dark'), findsOneWidget);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      const Color(0xFF11161D),
    );

    await tester.tap(find.byTooltip('Theme preference: Dark'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('System Default'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Theme preference: System Default'), findsOneWidget);
  });

  testWidgets('opens the create-account page from Sign Up', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const StudyHubApp());
    await finishAppLaunch(tester);

    final signUp = find.text('Sign Up');
    await tester.ensureVisible(signUp);
    await tester.tap(signUp);
    await tester.pumpAndSettle();

    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
    expect(find.textContaining('Terms of Service'), findsOneWidget);

    final logIn = find.text('Log In');
    await tester.ensureVisible(logIn);
    await tester.tap(logIn);
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('requires matching passwords when creating an account', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const StudyHubApp());
    await finishAppLaunch(tester);

    final signUp = find.text('Sign Up');
    await tester.ensureVisible(signUp);
    await tester.tap(signUp);
    await tester.pumpAndSettle();

    final confirmationField = find.byType(TextFormField).at(3);
    await tester.ensureVisible(confirmationField);
    await tester.enterText(confirmationField, 'different');

    final createAccount = find.text('Sign Up');
    await tester.ensureVisible(createAccount);
    await tester.tap(createAccount);
    await tester.pump();

    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('opens the dashboard after creating an account', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const StudyHubApp());
    await finishAppLaunch(tester);

    final signUpPrompt = find.text('Sign Up');
    await tester.ensureVisible(signUpPrompt);
    await tester.tap(signUpPrompt);
    await tester.pumpAndSettle();

    final termsCheckbox = find.byType(Checkbox);
    await tester.ensureVisible(termsCheckbox);
    await tester.tap(termsCheckbox);
    await tester.pumpAndSettle();
    final createAccount = find.text('Sign Up');
    await tester.ensureVisible(createAccount);
    await tester.tap(createAccount);
    await tester.pumpAndSettle();

    expect(find.text('Let’s become\nmore Productive, Aaron'), findsOneWidget);
  });

  testWidgets('renders the dashboard overview', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardPage()));

    expect(find.text('Let’s become\nmore Productive, Aaron'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1750));
    expect(find.text('Let’s become\nmore Productive, Aaron'), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(find.text("Today's Progress"), findsOneWidget);
    expect(find.text('Upcoming Study\nSessions'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Priority Tasks'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Priority Tasks'), findsOneWidget);
  });

  testWidgets('opens tasks from the progress card', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardPage()));

    await tester.tap(find.text('View Tasks'));
    await tester.pumpAndSettle();

    expect(find.text('Total Tasks'), findsOneWidget);
    expect(find.byType(FloatingTabBar), findsOneWidget);
  });

  testWidgets('opens Schedule from the upcoming sessions card', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardPage()));

    await tester.tap(find.text('View\nCalendar'));
    await tester.pumpAndSettle();

    expect(find.text('Schedule in your\ncalendar 🗓️'), findsOneWidget);
    expect(find.byType(FloatingTabBar), findsOneWidget);
  });

  testWidgets('renders the weekly schedule', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SchedulePage()));

    expect(find.text('Schedule in your\ncalendar 🗓️'), findsOneWidget);
    expect(find.text('Mathematics'), findsWidgets);
    expect(find.text('Comp Sci'), findsWidgets);
    expect(find.byTooltip('Add study session'), findsOneWidget);
  });

  testWidgets('fits the weekly schedule on a narrow mobile screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: SchedulePage()));

    expect(find.text('Schedule in your\ncalendar 🗓️'), findsOneWidget);
    final today = DateUtils.dateOnly(DateTime.now());
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    expect(find.text('${weekStart.day}'), findsOneWidget);
    expect(find.byTooltip('Add study session'), findsOneWidget);
  });

  testWidgets('keeps one navigation bar when selecting Schedule', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardPage()));

    await tester.tap(find.text('Schedule'));
    await tester.pumpAndSettle();

    expect(find.text('Schedule in your\ncalendar 🗓️'), findsOneWidget);
    expect(find.byType(FloatingTabBar), findsOneWidget);
  });
}
