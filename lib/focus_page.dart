import 'dart:async';

import 'package:flutter/material.dart';

import 'floating_tab_bar.dart';
import 'study_hub_app_bar.dart';

class FocusPage extends StatefulWidget {
  const FocusPage({super.key, this.onThemeToggle, this.embedded = false});

  final VoidCallback? onThemeToggle;
  final bool embedded;

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {
  static const _focusDuration = Duration(minutes: 25);
  static const _breakDuration = Duration(minutes: 5);

  Timer? _timer;
  Duration _remaining = _focusDuration;
  bool _isRunning = false;
  bool _isBreak = false;
  bool _deepWork = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
      return;
    }
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining.inSeconds <= 1) {
        timer.cancel();
        setState(() {
          _isRunning = false;
          _remaining = _isBreak ? _breakDuration : _focusDuration;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isBreak ? 'Break finished!' : 'Focus session complete!',
            ),
          ),
        );
        return;
      }
      setState(() => _remaining -= const Duration(seconds: 1));
    });
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remaining = _isBreak ? _breakDuration : _focusDuration;
    });
  }

  void _toggleBreak() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isBreak = !_isBreak;
      _remaining = _isBreak ? _breakDuration : _focusDuration;
    });
  }

  String get _timerLabel {
    final minutes = _remaining.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = _remaining.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? Colors.white : const Color(0xFF202226);
    final secondary = isDark
        ? const Color(0xFFB4C0D0)
        : const Color(0xFF738092);
    final pageColor = isDark
        ? const Color(0xFF11161D)
        : const Color(0xFFF8FAFD);

    final content = ListView(
      // Let the dashboard navigation's rounded edge overlay cards in the
      // embedded view.
      padding: EdgeInsets.fromLTRB(16, 42, 16, widget.embedded ? 16 : 28),
      children: [
        _TimerCard(
          timerLabel: _timerLabel,
          isBreak: _isBreak,
          isRunning: _isRunning,
          primary: primary,
          onToggleTimer: _toggleTimer,
          onReset: _reset,
          onToggleBreak: _toggleBreak,
        ),
        const SizedBox(height: 43),
        _DeepWorkCard(
          isDark: isDark,
          active: _deepWork,
          onChanged: (value) => setState(() => _deepWork = value),
        ),
        const SizedBox(height: 14),
        _GoalCard(isDark: isDark),
        const SizedBox(height: 41),
        Text(
          '"The secret of getting ahead is getting\nstarted."',
          textAlign: TextAlign.center,
          style: TextStyle(color: secondary, fontSize: 16, height: 1.28),
        ),
        const SizedBox(height: 7),
        Text(
          '— Mark Twain',
          textAlign: TextAlign.center,
          style: TextStyle(color: secondary, fontSize: 12),
        ),
      ],
    );

    if (widget.embedded) return content;
    return Scaffold(
      backgroundColor: pageColor,
      body: SafeArea(
        child: Column(
          children: [
            const StudyHubAppBar(),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }
}

class _TimerCard extends StatelessWidget {
  const _TimerCard({
    required this.timerLabel,
    required this.isBreak,
    required this.isRunning,
    required this.primary,
    required this.onToggleTimer,
    required this.onReset,
    required this.onToggleBreak,
  });

  final String timerLabel;
  final bool isBreak;
  final bool isRunning;
  final Color primary;
  final VoidCallback onToggleTimer;
  final VoidCallback onReset;
  final VoidCallback onToggleBreak;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(35, 35, 35, 35),
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1D2631)
          : Colors.white,
      borderRadius: appSurfaceBorderRadius,
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F3272BC),
          blurRadius: 30,
          offset: Offset(0, 14),
        ),
      ],
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFDCEEFF),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            isBreak ? 'Break Session' : 'Focus Session',
            style: const TextStyle(
              color: Color(0xFF37627F),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          timerLabel,
          style: TextStyle(
            color: primary,
            fontSize: 83,
            height: .96,
            fontWeight: FontWeight.w800,
            letterSpacing: -4.8,
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed: onToggleTimer,
            icon: Icon(
              isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 22,
            ),
            label: Text(
              isRunning ? 'Pause' : 'Start',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0569BA),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _TimerAction(
                icon: Icons.restart_alt_rounded,
                label: 'Reset',
                onPressed: onReset,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: _TimerAction(
                icon: Icons.skip_next_rounded,
                label: isBreak ? 'Focus' : 'Break',
                onPressed: onToggleBreak,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _TimerAction extends StatelessWidget {
  const _TimerAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 43,
    child: FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: FilledButton.styleFrom(
        foregroundColor: const Color(0xFF434B57),
        backgroundColor: const Color(0xFFF0F1F4),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
    ),
  );
}

class _DeepWorkCard extends StatelessWidget {
  const _DeepWorkCard({
    required this.isDark,
    required this.active,
    required this.onChanged,
  });

  final bool isDark;
  final bool active;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 20),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1D2631) : Colors.white,
      borderRadius: appSurfaceBorderRadius,
      border: Border.all(
        color: isDark ? const Color(0xFF3A4654) : const Color(0xFFB8C4D4),
        width: .5,
      ),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Deep Work',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF202328),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Block all notifications',
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFFB5C0CE)
                      : const Color(0xFF717C8D),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: active,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: const Color(0xFF0569BA),
        ),
      ],
    ),
  );
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(21, 23, 21, 19),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1D2631) : Colors.white,
      borderRadius: appSurfaceBorderRadius,
      border: Border.all(
        color: isDark ? const Color(0xFF3A4654) : const Color(0xFFB8C4D4),
        width: .5,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'DAILY GOAL',
              style: TextStyle(
                color: isDark
                    ? const Color(0xFFD4DEEA)
                    : const Color(0xFF4E5764),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: .4,
              ),
            ),
            const Spacer(),
            const Text(
              '2/4',
              style: TextStyle(
                color: Color(0xFF0569BA),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          child: LinearProgressIndicator(
            value: .5,
            minHeight: 10,
            color: Color(0xFF0569BA),
            backgroundColor: Color(0xFFBCE0FC),
          ),
        ),
        const SizedBox(height: 15),
        Text(
          '50 minutes completed today',
          style: TextStyle(
            color: isDark ? const Color(0xFFD4DEEA) : const Color(0xFF303742),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}
