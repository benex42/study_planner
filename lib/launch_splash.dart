import 'package:flutter/material.dart';

/// Branded screen shown once while StudyHub is opening.
///
/// This is kept separate from the network loading overlay so a slow request
/// never replays the launch experience.
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _displayDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onFinished();
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final animation = disableAnimations
        ? const AlwaysStoppedAnimation<double>(1)
        : _controller;

    return Semantics(
      label: 'Opening StudyHub',
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final progress = animation.value;
          final pulse = Curves.easeInOut.transform(
            (progress / .4).clamp(0.0, 1.0),
          );
          final scaleUp = const Interval(
            .4,
            .58,
            curve: Curves.easeOutBack,
          ).transform(progress);
          final reveal = const Interval(
            .58,
            1,
            curve: Cubic(.3, 0, .2, 1),
          ).transform(progress);
          final logoFade = const Interval(
            .12,
            .5,
            curve: Curves.easeInCubic,
          ).transform(reveal);

          return Stack(
            fit: StackFit.expand,
            children: [
              ClipPath(
                clipper: _SplashRevealClipper(reveal),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? const [
                              Color(0xFF101820),
                              Color(0xFF172532),
                              Color(0xFF111B25),
                            ]
                          : const [
                              Color(0xFFE7F3FF),
                              Color(0xFFF9FBFF),
                              Color(0xFFEFF7FF),
                            ],
                      stops: const [0, .54, 1],
                    ),
                  ),
                  child: Center(
                    child: Transform.scale(
                      scale:
                          .96 +
                          (.04 * pulse) +
                          (.55 * scaleUp) +
                          (.75 * reveal),
                      child: Opacity(
                        opacity: (.92 + (.08 * pulse)) * (1 - logoFade),
                        child: Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1889E0)
                                : const Color(0xFF0768BB),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? const Color(0x501889E0)
                                    : const Color(0x350768BB),
                                blurRadius: 26,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: Colors.white,
                            size: 53,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SplashRevealClipper extends CustomClipper<Path> {
  const _SplashRevealClipper(this.progress);

  final double progress;

  @override
  Path getClip(Size size) {
    final path = Path()..addRect(Offset.zero & size);
    if (progress == 0) return path;

    final maxRadius = size.longestSide * 1.6;
    // The hole begins beneath the enlarged logo and grows out from its center,
    // keeping the handoff from the scale-up into the reveal continuous.
    final radius = maxRadius * progress;
    path
      ..fillType = PathFillType.evenOdd
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: radius,
        ),
      );
    return path;
  }

  @override
  bool shouldReclip(_SplashRevealClipper oldClipper) =>
      oldClipper.progress != progress;
}
