import 'package:flutter/material.dart';

import 'auth_widgets.dart';
import 'floating_tab_bar.dart';
import 'network_loading.dart';

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
      Navigator.of(context).pushReplacementNamed('/dashboard');
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
                        const AuthBrandHeader(),
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
                            Navigator.of(context).pushNamed('/sign-up');
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
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: _inputDecoration(labelText: 'Email'),
              validator: (value) {
                if (value == null || !value.contains('@')) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: passwordController,
              obscureText: obscurePassword,
              autofillHints: const [AutofillHints.password],
              decoration: _inputDecoration(
                labelText: 'Password',
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
            const SizedBox(height: 8),
            Align(
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
            const SizedBox(height: 25),
            const AuthSocialDivider(),
            const SizedBox(height: 25),
            AuthSocialButton(
              label: 'Google',
              logo: const AuthGoogleMark(),
              onPressed: onGoogle,
            ),
            const SizedBox(height: 13),
            AuthSocialButton(
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

  InputDecoration _inputDecoration({
    required String labelText,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: labelText,
      suffixIcon: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
