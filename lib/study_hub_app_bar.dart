import 'package:flutter/material.dart';

import 'settings_page.dart';

class StudyHubAppBar extends StatelessWidget {
  const StudyHubAppBar({
    super.key,
    this.themeMode = ThemeMode.system,
    this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF11161D) : const Color(0xFFF9FAFC),
      ),
      child: Stack(
        children: [
          const Align(alignment: Alignment.center, child: _StudyHubLogo()),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SettingsPage(
                    themeMode: themeMode,
                    onThemeModeChanged: onThemeModeChanged,
                  ),
                ),
              ),
              icon: Icon(
                Icons.settings_outlined,
                color: isDark
                    ? const Color(0xFFB5C0CD)
                    : const Color(0xFF667085),
                size: 24,
              ),
              tooltip: 'Settings',
            ),
          ),
        ],
      ),
    );
  }
}

class _StudyHubLogo extends StatelessWidget {
  const _StudyHubLogo();

  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: const BoxDecoration(
      color: Color(0xFF0768BB),
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
  );
}
