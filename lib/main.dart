import 'package:flutter/material.dart';

import 'focus_page.dart';
import 'floating_tab_bar.dart';
import 'launch_splash.dart';
import 'network_loading.dart';
import 'schedule_page.dart';
import 'study_hub_app_bar.dart';
import 'task_page.dart';

part 'sign_up_page.dart';
part 'dashboard_page.dart';

void main() {
  runApp(const StudyHubApp());
}

class StudyHubApp extends StatefulWidget {
  const StudyHubApp({super.key});

  @override
  State<StudyHubApp> createState() => _StudyHubAppState();
}

class _StudyHubAppState extends State<StudyHubApp> {
  ThemeMode _themeMode = ThemeMode.system;
  final NetworkActivityController _networkActivity =
      NetworkActivityController();

  @override
  void dispose() {
    _networkActivity.dispose();
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
      builder: (context, child) => NetworkLoadingScope(
        controller: _networkActivity,
        child: NetworkLoadingOverlay(child: child ?? const SizedBox.shrink()),
      ),
      routes: {
        '/login': (_) =>
            LoginPage(themeMode: _themeMode, onThemeModeChanged: _setThemeMode),
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
    final loginPage = LoginPage(
      key: const ValueKey('login-page'),
      themeMode: widget.themeMode,
      onThemeModeChanged: widget.onThemeModeChanged,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(ignoring: !_hasFinishedLaunching, child: loginPage),
        if (!_hasFinishedLaunching)
          LaunchSplash(
            key: const ValueKey('launch-splash'),
            onFinished: () {
              if (mounted) setState(() => _hasFinishedLaunching = true);
            },
          ),
      ],
    );
  }
}

// Kept as an alias for the default Flutter test entry point.
class MyApp extends StudyHubApp {
  const MyApp({super.key});
}

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    this.themeMode = ThemeMode.system,
    this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController(
    text: 'aaron.rivers@university.edu',
  );
  final _passwordController = TextEditingController(text: 'password');
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _logIn() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await NetworkLoadingScope.of(context).track(_authenticate());
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => DashboardPage(
            themeMode: widget.themeMode,
            onThemeModeChanged: widget.onThemeModeChanged,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to sign in. Please try again.');
      }
    }
  }

  Future<void> _authenticate() async {
    // Replace this with the app's authentication/API call. Keeping this
    // asynchronous mirrors a backend request and makes the loading lifecycle
    // explicit for the current demo flow.
    await Future<void>.delayed(const Duration(milliseconds: 700));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.height < 690;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF111923)
          : const Color(0xFFF4F7FD),
      body: SafeArea(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? const [Color(0xFF152331), Color(0xFF101820)]
                  : const [Color(0xFFEAF4FF), Color(0xFFF8F9FE)],
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: isCompact ? 16 : 26,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _BrandHeader(),
                        SizedBox(height: isCompact ? 28 : 40),
                        _LoginCard(
                          formKey: _formKey,
                          emailController: _emailController,
                          passwordController: _passwordController,
                          obscurePassword: _obscurePassword,
                          onPasswordVisibilityChanged: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                          onLogin: _logIn,
                          onForgotPassword: () =>
                              _showMessage('Password recovery is on its way.'),
                          onGoogle: () =>
                              _showMessage('Continue with Google selected.'),
                          onApple: () =>
                              _showMessage('Continue with Apple selected.'),
                        ),
                        SizedBox(height: isCompact ? 27 : 34),
                        _SignUpPrompt(
                          onSignUp: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => SignUpPage(
                                  themeMode: widget.themeMode,
                                  onThemeModeChanged: widget.onThemeModeChanged,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({this.subtitle = 'Welcome back'});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            color: const Color(0xFF0768BB),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.school_rounded,
            color: Colors.white,
            size: 39,
          ),
        ),
        const SizedBox(height: 17),
        Text(
          'StudyHub',
          style: const TextStyle(
            color: Color(0xFF0861B1),
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.1,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          subtitle,
          style: TextStyle(
            color: isDark ? const Color(0xFFD7E4F0) : const Color(0xFF3F4653),
            fontSize: 19,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onPasswordVisibilityChanged,
    required this.onLogin,
    required this.onForgotPassword,
    required this.onGoogle,
    required this.onApple,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onPasswordVisibilityChanged;
  final VoidCallback onLogin;
  final VoidCallback onForgotPassword;
  final VoidCallback onGoogle;
  final VoidCallback onApple;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(33, 35, 33, 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2632) : Colors.white,
        borderRadius: appSurfaceBorderRadius,
        border: Border.all(
          color: isDark ? const Color(0xFF3B4B5C) : const Color(0xFFE1E5EB),
          width: .5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x40000000) : const Color(0x12000000),
            blurRadius: 20,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _FieldLabel('Email'),
            const SizedBox(height: 8),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: _inputDecoration(
                context,
                hintText: 'you@university.edu',
                prefixIcon: Icons.mail_outline_rounded,
              ),
              validator: (value) {
                if (value == null || !value.contains('@')) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const _FieldLabel('Password'),
                const Spacer(),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: onForgotPassword,
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Color(0xFF0062B5),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: passwordController,
              obscureText: obscurePassword,
              autofillHints: const [AutofillHints.password],
              decoration: _inputDecoration(
                context,
                hintText: 'Enter your password',
                prefixIcon: Icons.lock_outline_rounded,
                suffix: IconButton(
                  onPressed: onPasswordVisibilityChanged,
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 25),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: onLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0768BA),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: const Text('Log In'),
              ),
            ),
            const SizedBox(height: 31),
            const _SocialDivider(),
            const SizedBox(height: 31),
            _SocialButton(
              label: 'Google',
              logo: const _GoogleMark(),
              onPressed: onGoogle,
            ),
            const SizedBox(height: 13),
            _SocialButton(
              label: 'Apple',
              logo: Icon(
                Icons.apple,
                color: isDark ? Colors.white : const Color(0xFF1C1C1C),
                size: 21,
              ),
              onPressed: onApple,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hintText,
    required IconData prefixIcon,
    Widget? suffix,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(
        color: isDark ? const Color(0xFF495B6D) : const Color(0xFFB8C3D5),
      ),
    );
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: isDark ? const Color(0xFF9AAABA) : const Color(0xFF697487),
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: isDark ? const Color(0xFFAEBECD) : const Color(0xFF717D8F),
        size: 24,
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: isDark ? const Color(0xFF121C26) : const Color(0xFFF8F9FB),
      contentPadding: const EdgeInsets.symmetric(vertical: 15),
      isDense: true,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: Color(0xFF0768BA), width: 1.5),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(color: Color(0xFFB3261E)),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(color: Color(0xFFB3261E), width: 1.5),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      label,
      style: TextStyle(
        color: isDark ? const Color(0xFFDDE7F0) : const Color(0xFF3E4655),
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _SocialDivider extends StatelessWidget {
  const _SocialDivider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? const Color(0xFF46576A) : const Color(0xFFC4CDDB);
    return Row(
      children: [
        Expanded(child: Divider(color: color, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR CONTINUE WITH',
            style: TextStyle(
              color: isDark ? const Color(0xFFAEBECD) : const Color(0xFF707A8B),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: .6,
            ),
          ),
        ),
        Expanded(child: Divider(color: color, thickness: 1)),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.logo,
    required this.onPressed,
  });
  final String label;
  final Widget logo;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark
              ? const Color(0xFFF2F6FA)
              : const Color(0xFF20242C),
          side: BorderSide(
            color: isDark ? const Color(0xFF4B5E72) : const Color(0xFFB7C3D7),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [logo, const SizedBox(width: 7), Text(label)],
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/google_logo.png',
      width: 21,
      height: 21,
      filterQuality: FilterQuality.high,
      excludeFromSemantics: true,
      isAntiAlias: true,
      fit: BoxFit.contain,
    );
  }
}

class _SignUpPrompt extends StatelessWidget {
  const _SignUpPrompt({required this.onSignUp});
  final VoidCallback onSignUp;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          "Don't have an account?",
          style: TextStyle(
            color: isDark ? const Color(0xFFD3DFEA) : const Color(0xFF434B58),
            fontSize: 16,
          ),
        ),
        const SizedBox(width: 7, height: 23),
        GestureDetector(
          onTap: onSignUp,
          child: const Text(
            'Sign Up',
            style: TextStyle(
              color: Color(0xFF0064BA),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _SignUpCard extends StatelessWidget {
  const _SignUpCard({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.acceptedTerms,
    required this.obscurePassword,
    required this.onAcceptedTermsChanged,
    required this.onPasswordVisibilityChanged,
    required this.onSignUp,
    required this.onGoogle,
    required this.onApple,
    required this.onLogIn,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool acceptedTerms;
  final bool obscurePassword;
  final ValueChanged<bool?> onAcceptedTermsChanged;
  final VoidCallback onPasswordVisibilityChanged;
  final VoidCallback onSignUp;
  final VoidCallback onGoogle;
  final VoidCallback onApple;
  final VoidCallback onLogIn;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(33, 35, 33, 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2632) : Colors.white,
        borderRadius: appSurfaceBorderRadius,
        border: Border.all(
          color: isDark ? const Color(0xFF3B4B5C) : const Color(0xFFE1E5EB),
          width: .5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x40000000) : const Color(0x12000000),
            blurRadius: 20,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Create Account',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF20242A),
                fontSize: 29,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start your journey toward academic\nexcellence today.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? const Color(0xFFC9D5E0)
                    : const Color(0xFF454D5B),
                fontSize: 16,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 38),
            const _FieldLabel('Full Name'),
            const SizedBox(height: 8),
            TextFormField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              decoration: _signUpInputDecoration(
                context,
                hintText: 'Your name',
                prefixIcon: Icons.person_outline_rounded,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter your full name';
                }
                return null;
              },
            ),
            const SizedBox(height: 22),
            const _FieldLabel('Email Address'),
            const SizedBox(height: 8),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: _signUpInputDecoration(
                context,
                hintText: 'you@university.edu',
                prefixIcon: Icons.mail_outline_rounded,
              ),
              validator: (value) {
                if (value == null || !value.contains('@')) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 22),
            const _FieldLabel('Password'),
            const SizedBox(height: 8),
            TextFormField(
              controller: passwordController,
              obscureText: obscurePassword,
              autofillHints: const [AutofillHints.newPassword],
              decoration: _signUpInputDecoration(
                context,
                hintText: 'Create a password',
                prefixIcon: Icons.lock_outline_rounded,
                suffix: IconButton(
                  onPressed: onPasswordVisibilityChanged,
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 22),
            const _FieldLabel('Confirm Password'),
            const SizedBox(height: 8),
            TextFormField(
              controller: confirmPasswordController,
              obscureText: obscurePassword,
              autofillHints: const [AutofillHints.newPassword],
              decoration: _signUpInputDecoration(
                context,
                hintText: 'Confirm your password',
                prefixIcon: Icons.lock_outline_rounded,
                suffix: IconButton(
                  onPressed: onPasswordVisibilityChanged,
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Confirm your password';
                }
                if (value != passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _TermsCheckbox(
              value: acceptedTerms,
              onChanged: onAcceptedTermsChanged,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: onSignUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0768BA),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Sign Up'),
                    SizedBox(width: 10),
                    Icon(Icons.arrow_forward_rounded, size: 25),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 31),
            const _SocialDivider(),
            const SizedBox(height: 31),
            _SocialButton(
              label: 'Google',
              logo: const _GoogleMark(),
              onPressed: onGoogle,
            ),
            const SizedBox(height: 13),
            _SocialButton(
              label: 'Apple',
              logo: Icon(
                Icons.apple,
                color: isDark ? Colors.white : const Color(0xFF1C1C1C),
                size: 21,
              ),
              onPressed: onApple,
            ),
            const SizedBox(height: 29),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Already have an account?',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFD3DFEA)
                        : const Color(0xFF454D5B),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 7, height: 24),
                GestureDetector(
                  onTap: onLogIn,
                  child: const Text(
                    'Log In',
                    style: TextStyle(
                      color: Color(0xFF0064BA),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _signUpInputDecoration(
    BuildContext context, {
    required String hintText,
    required IconData prefixIcon,
    Widget? suffix,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(
        color: isDark ? const Color(0xFF495B6D) : const Color(0xFFB8C3D5),
      ),
    );
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: isDark ? const Color(0xFF9AAABA) : const Color(0xFF697487),
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: isDark ? const Color(0xFFAEBECD) : const Color(0xFF717D8F),
        size: 24,
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: isDark ? const Color(0xFF121C26) : const Color(0xFFF8F9FB),
      contentPadding: const EdgeInsets.symmetric(vertical: 15),
      isDense: true,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: Color(0xFF0768BA), width: 1.5),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(color: Color(0xFFB3261E)),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(color: Color(0xFFB3261E), width: 1.5),
      ),
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: SizedBox(
            width: 25,
            height: 25,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF0768BA),
              side: BorderSide(
                color: isDark
                    ? const Color(0xFF90A4B8)
                    : const Color(0xFFBAC5D7),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: TextStyle(
                color: isDark
                    ? const Color(0xFFD3DFEA)
                    : const Color(0xFF343D4B),
                fontSize: 16,
                height: 1.25,
              ),
              children: [
                TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(
                    color: Color(0xFF0064BA),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: ' and\n'),
                TextSpan(
                  text: 'Privacy Policy.',
                  style: TextStyle(
                    color: Color(0xFF0064BA),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
