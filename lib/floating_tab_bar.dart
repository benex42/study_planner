import 'dart:ui';

import 'package:flutter/material.dart';

/// Shared curve for the floating navigation and all elevated page cards.
const appSurfaceBorderRadius = BorderRadius.all(Radius.circular(28));

/// A translucent, softly blurred surface used for floating UI elements.
class FrostedGlassSurface extends StatelessWidget {
  const FrostedGlassSurface({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = appSurfaceBorderRadius,
    this.blurSigma = 18,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius borderRadius;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? .32 : .14),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [Color(0xB31E2935), Color(0x99131B25)]
                    : const [Color(0xB3FFFFFF), Color(0x99EAF3FF)],
              ),
              border: Border.all(
                color: isDark
                    ? const Color(0x4DFFFFFF)
                    : const Color(0x73FFFFFF),
                width: .5,
              ),
            ),
            child: padding == null
                ? child
                : Padding(padding: padding!, child: child),
          ),
        ),
      ),
    );
  }
}

class FloatingTabItem {
  const FloatingTabItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// An iOS-inspired tab bar that floats over page content with a frosted finish.
class FloatingTabBar extends StatelessWidget {
  const FloatingTabBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<FloatingTabItem> items;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark
        ? const Color(0xFFB5C0CD)
        : const Color(0xFF667085);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: SizedBox(
        height: 68,
        child: FrostedGlassSurface(
          child: Row(
            children: [
              for (var index = 0; index < items.length; index++)
                Expanded(
                  child: _FloatingTab(
                    item: items[index],
                    selected: index == selectedIndex,
                    foreground: foreground,
                    onTap: () => onDestinationSelected(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingTab extends StatelessWidget {
  const _FloatingTab({
    required this.item,
    required this.selected,
    required this.foreground,
    required this.onTap,
  });

  final FloatingTabItem item;
  final bool selected;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const selectedColor = Color(0xFF007AFF);
    final color = selected ? selectedColor : foreground;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: Tooltip(
        message: item.label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.only(top: 9, bottom: 7),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selected ? item.selectedIcon : item.icon,
                    color: color,
                    size: 22,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
