import 'package:flutter/material.dart';

/// Keeps a count of pending backend requests so overlapping requests do not
/// dismiss the loading screen prematurely.
class NetworkActivityController extends ChangeNotifier {
  int _pendingRequests = 0;

  bool get isLoading => _pendingRequests > 0;

  /// Runs [request] while marking the application as loading.
  ///
  /// The loading state is always cleared, including when [request] throws.
  Future<T> track<T>(Future<T> request) async {
    _pendingRequests++;
    notifyListeners();

    try {
      return await request;
    } finally {
      _pendingRequests--;
      notifyListeners();
    }
  }
}

/// Makes the app-wide [NetworkActivityController] available to feature code.
class NetworkLoadingScope extends InheritedNotifier<NetworkActivityController> {
  const NetworkLoadingScope({
    super.key,
    required NetworkActivityController controller,
    required super.child,
  }) : super(notifier: controller);

  static NetworkActivityController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<NetworkLoadingScope>();
    assert(scope != null, 'NetworkLoadingScope is missing above this widget.');
    return scope!.notifier!;
  }
}

/// Covers the current page only while one or more tracked requests are pending.
class NetworkLoadingOverlay extends StatelessWidget {
  const NetworkLoadingOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final controller = NetworkLoadingScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            child,
            if (controller.isLoading) const _NetworkLoadingSplash(),
          ],
        );
      },
    );
  }
}

class _NetworkLoadingSplash extends StatelessWidget {
  const _NetworkLoadingSplash();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brandColor = isDark
        ? const Color(0xFF1889E0)
        : const Color(0xFF0768BB);

    return AbsorbPointer(
      child: Semantics(
        label: 'Loading application',
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? const [Color(0xFF101820), Color(0xFF11161D)]
                  : const [Color(0xFFF0F7FF), Color(0xFFF9FBFF)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: .82, end: 1),
                  duration: const Duration(milliseconds: 550),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: brandColor,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: brandColor.withValues(
                            alpha: isDark ? .34 : .2,
                          ),
                          blurRadius: 22,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    color: brandColor,
                  ),
                ),
                const SizedBox(height: 16),
              
              ],
            ),
          ),
        ),
      ),
    );
  }
}
