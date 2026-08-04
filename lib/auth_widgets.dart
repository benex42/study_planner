import 'package:flutter/material.dart';

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key, this.subtitle = 'Welcome back'});

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

class AuthSocialDivider extends StatelessWidget {
  const AuthSocialDivider({super.key});

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

class AuthSocialButton extends StatelessWidget {
  const AuthSocialButton({
    super.key,
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

class AuthGoogleMark extends StatelessWidget {
  const AuthGoogleMark({super.key});

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
