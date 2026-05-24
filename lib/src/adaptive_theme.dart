import 'package:flutter/material.dart';

/// Holds the adaptive visual theme properties computed for the nav bar.
///
/// Properties dynamically adjust to ensure premium visual depth and optimal
/// contrast ratios across dark, light, and warm backdrops.
class AdaptiveTheme {
  /// Whether the background behind the bar is dark or light.
  final Brightness brightness;

  /// The translucent overlay color to place on top of the frosted glass blur.
  final Color tintColor;

  /// The color for inactive tab icons and labels.
  final Color inactiveColor;

  /// The dynamic background fill color of the active tab's pill container.
  final Color activePillColor;

  /// The color of the micro-thin (0.5 pt) top divider border.
  final Color topBorderColor;

  /// Creates a theme container for the [AdaptiveNavBar].
  const AdaptiveTheme({
    required this.brightness,
    required this.tintColor,
    required this.inactiveColor,
    required this.activePillColor,
    required this.topBorderColor,
  });

  /// Factory constructor that resolves all dynamic colors based on background [avgColor] and [luminance].
  factory AdaptiveTheme.resolve(Color avgColor, double luminance, {double threshold = 0.5}) {
    final isDark = luminance < threshold;

    final Color tint;
    final Color inactive;
    final Color pill;
    final Color border;

    if (isDark) {
      // Dark Mode Surface: 15% black overlay
      tint = Colors.black.withValues(alpha: 0.15);
      inactive = Colors.white.withValues(alpha: 0.5);
      pill = Colors.white.withValues(alpha: 0.1);
      border = Colors.white.withValues(alpha: 0.12);
    } else {
      // Check for warm orange/red hues based on HSL representation
      final hsl = HSLColor.fromColor(avgColor);
      final isWarm = (hsl.hue >= 340.0 || hsl.hue <= 50.0) &&
          hsl.saturation > 0.20 &&
          hsl.lightness > 0.30;

      if (isWarm) {
        // Warm Mode Surface: blend dynamic translucent warm hue
        tint = avgColor.withValues(alpha: 0.15);
        inactive = Colors.black.withValues(alpha: 0.5);
        pill = Colors.black.withValues(alpha: 0.08);
        border = Colors.black.withValues(alpha: 0.12);
      } else {
        // Light Mode Surface: 15% white overlay
        tint = Colors.white.withValues(alpha: 0.15);
        inactive = Colors.black.withValues(alpha: 0.5);
        pill = Colors.black.withValues(alpha: 0.05);
        border = Colors.black.withValues(alpha: 0.08);
      }
    }

    return AdaptiveTheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      tintColor: tint,
      inactiveColor: inactive,
      activePillColor: pill,
      topBorderColor: border,
    );
  }
}
