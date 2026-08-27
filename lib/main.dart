import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'focus_page.dart';
import 'floating_tab_bar.dart';
import 'login_page.dart';
import 'sign_up_page.dart' as signup;
import 'launch_splash.dart';
import 'network_loading.dart';
import 'schedule_page.dart';
import 'study_hub_app_bar.dart';
import 'study_session_repository.dart';
import 'task_page.dart';
import 'task_repository.dart';

part 'dashboard_page.dart';

void main() {
  runApp(const StudyHubApp());
}

class StudyHubApp extends StatefulWidget {
  const StudyHubApp({super.key, this.authController});

  final AuthController? authController;

  @override
  State<StudyHubApp> createState() => _StudyHubAppState();
}

class _StudyHubAppState extends State<StudyHubApp> {
  ThemeMode _themeMode = ThemeMode.system;
  final NetworkActivityController _networkActivity =
      NetworkActivityController();
  late final AuthController _authController;
  late final bool _ownsAuthController;

  @override
  void initState() {
    super.initState();
    _ownsAuthController = widget.authController == null;
    _authController = widget.authController ?? AuthController();
    _authController.initialize();
  }

  @override
  void dispose() {
    _networkActivity.dispose();
    if (_ownsAuthController) _authController.dispose();
    super.dispose();
  }

  void _setThemeMode(ThemeMode themeMode) =>
      setState(() => _themeMode = themeMode);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyHub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0565B8)),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF469BE3),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: _themeMode,
      builder: (context, child) => AuthScope(
        controller: _authController,
        child: NetworkLoadingScope(
          controller: _networkActivity,
          child: NetworkLoadingOverlay(child: child ?? const SizedBox.shrink()),
        ),
      ),
      routes: {
        '/login': (_) =>
            LoginPage(themeMode: _themeMode, onThemeModeChanged: _setThemeMode),
        '/sign-up': (_) => signup.SignUpPage(
          themeMode: _themeMode,
          onThemeModeChanged: _setThemeMode,
        ),
        '/dashboard': (_) => DashboardPage(
          themeMode: _themeMode,
          onThemeModeChanged: _setThemeMode,
        ),
      },
      home: _AppLaunchGate(
        themeMode: _themeMode,
        onThemeModeChanged: _setThemeMode,
      ),
    );
  }
}

class _AppLaunchGate extends StatefulWidget {
  const _AppLaunchGate({required this.themeMode, this.onThemeModeChanged});

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;

  @override
  State<_AppLaunchGate> createState() => _AppLaunchGateState();
}

class _AppLaunchGateState extends State<_AppLaunchGate> {
  bool _hasFinishedLaunching = false;

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    if (!_hasFinishedLaunching) {
      return LaunchSplash(
        key: const ValueKey('launch-splash'),
        onFinished: () {
          if (mounted) setState(() => _hasFinishedLaunching = true);
        },
      );
    }
    if (auth.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (auth.isAuthenticated) {
      return DashboardPage(
        themeMode: widget.themeMode,
        onThemeModeChanged: widget.onThemeModeChanged,
      );
    }
    return LoginPage(
      key: const ValueKey('login-page'),
      themeMode: widget.themeMode,
      onThemeModeChanged: widget.onThemeModeChanged,
    );
  }
}

// Kept as an alias for the default Flutter test entry point.
class MyApp extends StudyHubApp {
  const MyApp({super.key});
}
