import 'package:flutter/material.dart';

/// A polished launch handoff that dissolves naturally into the first screen.
class LaunchSplash extends StatefulWidget {
  const LaunchSplash({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<LaunchSplash> createState() => _LaunchSplashState();
}

class _LaunchSplashState extends State<LaunchSplash>
    with SingleTickerProviderStateMixin {
  static const _displayDuration = Duration(milliseconds: 1750);

  late final AnimationController _controller;
  bool _hasStarted = false;
  bool _hasFinished = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _displayDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _finish();
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasStarted) return;

    _hasStarted = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
      return;
    }
    _controller.forward();
  }

  void _finish() {
    if (_hasFinished || !mounted) return;
    _hasFinished = true;
    widget.onFinished();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final animation = MediaQuery.disableAnimationsOf(context)
        ? const AlwaysStoppedAnimation<double>(1)
        : _controller;

    return Semantics(
      label: 'Opening StudyHub',
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final progress = animation.value;
          final logoEntrance = const Interval(
            .08,
            .52,
            curve: Curves.easeOutBack,
          ).transform(progress);
          final haloExpansion = const Interval(
            .12,
            .58,
            curve: Cubic(.16, 1, .3, 1),
          ).transform(progress);
          final wordmarkEntrance = const Interval(
            .27,
            .62,
            curve: Cubic(.16, 1, .3, 1),
          ).transform(progress);
          final highlightPass = const Interval(
            .48,
            .72,
            curve: Curves.easeInOut,
          ).transform(progress);
          final dissolve = const Interval(
            .78,
            1,
            // Apple's standard ease curve: a restrained start with no abrupt
            // change in velocity as the login screen comes into view.
            curve: Cubic(.25, .1, .25, 1),
          ).transform(progress);
          final accent = isDark
              ? const Color(0xFF5BB7F2)
              : const Color(0xFF0877CF);

          return Opacity(
            opacity: 1 - dissolve,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isDark
                          ? const [Color(0xFF152331), Color(0xFF101820)]
                          : const [Color(0xFFEAF4FF), Color(0xFFF8F9FE)],
                    ),
                  ),
                ),
                Positioned(
                  top: -145,
                  right: -125,
                  child: Opacity(
                    opacity: .16 * (1 - dissolve),
                    child: Transform.scale(
                      scale: .88 + (.12 * haloExpansion),
                      child: Container(
                        width: 330,
                        height: 330,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              accent.withValues(alpha: .62),
                              accent.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Transform.translate(
                    offset: Offset(0, 12 * (1 - logoEntrance)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 156,
                          height: 156,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Transform.scale(
                                scale: .72 + (.58 * haloExpansion),
                                child: Opacity(
                                  opacity: .26 * (1 - haloExpansion),
                                  child: Container(
                                    width: 104,
                                    height: 104,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(32),
                                      border: Border.all(
                                        color: accent.withValues(alpha: .8),
                                        width: 1.2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Transform.scale(
                                scale: .78 + (.22 * logoEntrance),
                                child: Opacity(
                                  opacity: logoEntrance
                                      .clamp(0.0, 1.0)
                                      .toDouble(),
                                  child: _SplashAppIcon(
                                    highlightProgress: highlightPass,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Transform.translate(
                          offset: Offset(0, 9 * (1 - wordmarkEntrance)),
                          child: Opacity(opacity: wordmarkEntrance),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SplashAppIcon extends StatelessWidget {
  const _SplashAppIcon({required this.highlightProgress});

  final double highlightProgress;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .2),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: SizedBox(
          width: 104,
          height: 104,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/studyhub_app_icon.png',
                fit: BoxFit.cover,
              ),
              if (highlightProgress > 0)
                Align(
                  alignment: Alignment(-1.7 + (3.4 * highlightProgress), 0),
                  child: Opacity(
                    opacity: .22 * (1 - (2 * highlightProgress - 1).abs()),
                    child: Transform.rotate(
                      angle: -.35,
                      child: Container(
                        width: 22,
                        height: 150,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Color(0x99FFFFFF),
                              Colors.transparent,
                            ],
                          ),
                        ),
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
