import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'auth_widgets.dart';
import 'floating_tab_bar.dart';
import 'network_loading.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({
    super.key,
    this.themeMode = ThemeMode.system,
    this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _acceptedTerms = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      _showMessage('Please agree to the Terms of Service and Privacy Policy.');
      return;
    }
    try {
      await NetworkLoadingScope.of(context).track(
        AuthScope.of(context).signUp(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        ),
      );
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/dashboard', (route) => false);
    } on AuthException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to create your account. Please try again.');
      }
    }
  }

  Future<void> _continueWithGoogle() =>
      _completeSocialSignIn(AuthScope.of(context).signInWithGoogle);

  Future<void> _continueWithApple() =>
      _completeSocialSignIn(AuthScope.of(context).signInWithApple);

  Future<void> _completeSocialSignIn(Future<void> Function() signIn) async {
    try {
      await NetworkLoadingScope.of(context).track(signIn());
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/dashboard', (route) => false);
    } on AuthException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to complete sign-in. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).height < 690;
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
                        const AuthBrandHeader(subtitle: 'Create your account'),
                        SizedBox(height: isCompact ? 28 : 40),
                        _SignUpCard(
                          formKey: _formKey,
                          nameController: _nameController,
                          emailController: _emailController,
                          passwordController: _passwordController,
                          confirmPasswordController: _confirmPasswordController,
                          acceptedTerms: _acceptedTerms,
                          obscurePassword: _obscurePassword,
                          onAcceptedTermsChanged: (value) {
                            setState(() => _acceptedTerms = value ?? false);
                          },
                          onPasswordVisibilityChanged: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                          onSignUp: _createAccount,
                          onGoogle: _continueWithGoogle,
                          onApple: _continueWithApple,
                          onLogIn: () => Navigator.of(context).pop(),
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
    return FrostedGlassSurface(
      padding: const EdgeInsets.fromLTRB(33, 35, 33, 32),
      blurSigma: 10,
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
            TextFormField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              decoration: _signUpInputDecoration(labelText: 'Full Name'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter your full name';
                }
                return null;
              },
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: _signUpInputDecoration(labelText: 'Email Address'),
              validator: (value) {
                if (value == null || !value.contains('@')) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: passwordController,
              obscureText: obscurePassword,
              autofillHints: const [AutofillHints.newPassword],
              decoration: _signUpInputDecoration(
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
                if (value == null || value.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: confirmPasswordController,
              obscureText: obscurePassword,
              autofillHints: const [AutofillHints.newPassword],
              decoration: _signUpInputDecoration(
                labelText: 'Confirm Password',
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
            const AuthSocialDivider(),
            const SizedBox(height: 31),
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

  InputDecoration _signUpInputDecoration({
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
