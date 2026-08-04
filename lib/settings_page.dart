import 'package:flutter/material.dart';

import 'floating_tab_bar.dart';

/// The account and app-preferences area of StudyHub.
class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    this.themeMode = ThemeMode.system,
    this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late ThemeMode _selectedThemeMode;

  @override
  void initState() {
    super.initState();
    _selectedThemeMode = widget.themeMode;
  }

  void _setThemeMode(ThemeMode themeMode) {
    setState(() => _selectedThemeMode = themeMode);
    widget.onThemeModeChanged?.call(themeMode);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1B222C) : Colors.white;
    final background = isDark
        ? const Color(0xFF11161D)
        : const Color(0xFFF9FAFC);
    final primary = isDark ? Colors.white : const Color(0xFF24272D);
    final secondary = isDark
        ? const Color(0xFFAEB9C8)
        : const Color(0xFF5D6674);
    final divider = isDark ? const Color(0xFF35404F) : const Color(0xFFD1D8E2);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _SettingsHeader(
              onBack: () => Navigator.of(context).maybePop(),
              isDark: isDark,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 26),
                children: [
                  _ProfileCard(
                    surface: surface,
                    primary: primary,
                    secondary: secondary,
                  ),
                  const SizedBox(height: 18),
                  _SettingsSection(
                    title: 'ACCOUNT',
                    surface: surface,
                    primary: primary,
                    secondary: secondary,
                    divider: divider,
                    children: [
                      _SettingsRow(
                        icon: Icons.person_outline_rounded,
                        label: 'Profile Information',
                        onTap: () =>
                            _showMessage('Profile Information selected.'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 17),
                  _SettingsSection(
                    title: 'APP PREFERENCES',
                    surface: surface,
                    primary: primary,
                    secondary: secondary,
                    divider: divider,
                    children: [
                      _SettingsRow(
                        icon: Icons.notifications_none_rounded,
                        label: 'Notifications',
                        onTap: () => _showMessage('Notifications selected.'),
                      ),
                      _SettingsRow(
                        icon: Icons.palette_outlined,
                        label: 'Appearance',
                        showChevron: false,
                        trailing: _ThemePicker(
                          themeMode: _selectedThemeMode,
                          onChanged: _setThemeMode,
                        ),
                        onTap: null,
                      ),
                      _SettingsRow(
                        icon: Icons.language_rounded,
                        label: 'Language',
                        trailing: Text(
                          'English',
                          style: TextStyle(color: secondary, fontSize: 12),
                        ),
                        onTap: () => _showMessage('Language selected.'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 17),
                  _SettingsSection(
                    title: 'STUDY SETTINGS',
                    surface: surface,
                    primary: primary,
                    secondary: secondary,
                    divider: divider,
                    children: [
                      _SettingsRow(
                        icon: Icons.timer_outlined,
                        label: 'Focus Mode Settings',
                        onTap: () =>
                            _showMessage('Focus Mode Settings selected.'),
                      ),
                      _SettingsRow(
                        icon: Icons.track_changes_rounded,
                        label: 'Study Goals',
                        onTap: () => _showMessage('Study Goals selected.'),
                      ),
                      _SettingsRow(
                        icon: Icons.book_outlined,
                        label: 'Subjects & Courses',
                        onTap: () =>
                            _showMessage('Subjects & Courses selected.'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 17),
                  _SettingsSection(
                    title: 'SUPPORT',
                    surface: surface,
                    primary: primary,
                    secondary: secondary,
                    divider: divider,
                    children: [
                      _SettingsRow(
                        icon: Icons.help_outline_rounded,
                        label: 'Help Center',
                        onTap: () => _showMessage('Help Center selected.'),
                      ),
                      _SettingsRow(
                        icon: Icons.privacy_tip_outlined,
                        label: 'Privacy Policy',
                        onTap: () => _showMessage('Privacy Policy selected.'),
                      ),
                      _SettingsRow(
                        icon: Icons.info_outline_rounded,
                        label: 'About StudyHub',
                        onTap: () =>
                            _showMessage('StudyHub Version 2.4.0 (Build 1082)'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 17),
                  SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/login', (route) => false),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Logout'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD82828),
                        backgroundColor: const Color(0xFFFFD7D4),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 13),
                  Text(
                    'StudyHub Version 2.4.0 (Build 1082)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: secondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.onBack, required this.isDark});

  final VoidCallback onBack;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Stack(
        children: [
          Positioned(
            // The icon glyph aligns with the 22px content margin used by the
            // profile card and settings sections.
            left: 8,
            top: 2,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
              color: isDark ? const Color(0xFF8DCAFF) : const Color(0xFF1268B4),
              tooltip: 'Back',
            ),
          ),
          Positioned.fill(
            child: Center(
              child: Text(
                'Settings',
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF8DCAFF)
                      : const Color(0xFF0666B8),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.surface,
    required this.primary,
    required this.secondary,
  });

  final Color surface;
  final Color primary;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 108,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: appSurfaceBorderRadius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFB68968), Color(0xFF4B3028)],
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Color(0xFFF5DED0),
              size: 47,
            ),
          ),
          const SizedBox(width: 17),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aaron Rivers',
                  style: TextStyle(
                    color: primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'aaron.rivers@university.edu',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: secondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.surface,
    required this.primary,
    required this.secondary,
    required this.divider,
    required this.children,
  });

  final String title;
  final Color surface;
  final Color primary;
  final Color secondary;
  final Color divider;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 6),
          child: Text(
            title,
            style: TextStyle(
              color: secondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: .45,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: appSurfaceBorderRadius,
            border: Border.all(color: divider, width: .5),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.showChevron = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? const Color(0xFFF2F5F9) : const Color(0xFF34383F);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 58,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11),
          child: Row(
            children: [
              Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF273442)
                      : const Color(0xFFF0F3F6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: const Color(0xFF2675BA), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: primary, fontSize: 14),
                ),
              ),
              if (trailing != null) ...[trailing!, const SizedBox(width: 6)],
              if (showChevron)
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark
                      ? const Color(0x66F2F5F9)
                      : const Color(0x6634383F),
                  size: 21,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemePicker extends StatelessWidget {
  const _ThemePicker({required this.themeMode, required this.onChanged});

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopupMenuButton<ThemeMode>(
      tooltip: 'Theme preference: ${_themeLabel(themeMode)}',
      onSelected: onChanged,
      itemBuilder: (context) => ThemeMode.values
          .map(
            (mode) => PopupMenuItem<ThemeMode>(
              value: mode,
              child: Row(
                children: [
                  Icon(
                    mode == ThemeMode.light
                        ? Icons.light_mode_outlined
                        : mode == ThemeMode.dark
                        ? Icons.dark_mode_outlined
                        : Icons.brightness_auto_outlined,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(_themeLabel(mode)),
                  const Spacer(),
                  if (mode == themeMode)
                    const Icon(Icons.check_rounded, size: 18),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF11161D) : const Color(0xFFE8EBEF),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              themeMode == ThemeMode.light
                  ? Icons.light_mode_outlined
                  : themeMode == ThemeMode.dark
                  ? Icons.dark_mode_outlined
                  : Icons.brightness_auto_outlined,
              size: 14,
              color: const Color(0xFF1467B3),
            ),
            const SizedBox(width: 4),
            Text(
              _themeLabel(themeMode),
              style: const TextStyle(
                color: Color(0xFF1467B3),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _themeLabel(ThemeMode mode) => switch (mode) {
  ThemeMode.light => 'Light',
  ThemeMode.dark => 'Dark',
  ThemeMode.system => 'System Default',
};
