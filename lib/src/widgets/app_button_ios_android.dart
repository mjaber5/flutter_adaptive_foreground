import 'dart:ui' as ui;
import 'package:adaptive_foreground/src/widgets/app_dimensions.dart';
import 'package:adaptive_foreground/src/widgets/app_ios_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A cross-platform action button that renders a native iOS [AppIosButton]
/// on iOS and a Material circular button on all other platforms.
///
/// **iOS requirements:** [symbol] and [onPressed] must not be null.
class AppButtonIosAndroid extends StatelessWidget {
  const AppButtonIosAndroid({
    super.key,
    this.onPressed,
    this.symbol,
    this.isOutline = false,
    this.icon,
    this.color,
    this.buttonSize,
  });

  /// SF Symbol name — required on iOS.
  final String? symbol;

  /// Material icon — used on Android / other platforms.
  final IconData? icon;

  /// Called when the button is tapped. Pass `null` to disable the button.
  final VoidCallback? onPressed;

  /// When `true`, renders a bordered outline style on Android.
  final bool isOutline;

  /// Tint / foreground color applied to the icon and button surface.
  final Color? color;

  /// Custom tap-target size. Defaults to `AppDimensions.iconXL - 6`.
  final double? buttonSize;

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      if (symbol == null) {
        // Fail loudly in debug; degrade gracefully in release.
        assert(false, 'AppButtonIosAndroid: symbol is required on iOS.');
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: ArgumentError(
              'AppButtonIosAndroid: symbol must not be null on iOS.',
            ),
            library: 'adaptive_foreground',
          ),
        );
        return const SizedBox.shrink();
      }
      return AppIosButton(
        onPressed: onPressed,
        symbol: symbol!,
        color: color,
        size: buttonSize ?? AppDimensions.iconXL - 6,
      );
    }

    return _AndroidActionButton(
      onPressed: onPressed,
      icon: icon,
      isOutline: isOutline,
      color: color,
      buttonSize: buttonSize,
    );
  }
}

class _AndroidActionButton extends StatelessWidget {
  const _AndroidActionButton({
    required this.onPressed,
    required this.icon,
    required this.isOutline,
    required this.color,
    required this.buttonSize,
  });

  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isOutline;
  final Color? color;
  final double? buttonSize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = buttonSize ?? AppDimensions.iconXL - 6;

    // Use the color property as the foreground color.
    // If null, fall back to the theme's onSurface color.
    final fgColor = color ?? colorScheme.onSurface;
    final isDarkBackground = fgColor.computeLuminance() > 0.5;

    // Adaptive glassy background/border properties
    final backgroundColor = isOutline
        ? Colors.transparent
        : (isDarkBackground
            ? Colors.black.withValues(alpha: 0.35)
            : Colors.white.withValues(alpha: 0.65));

    final borderColor = isOutline
        ? fgColor.withValues(alpha: 0.35)
        : (isDarkBackground
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06));

    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: SizedBox.square(
        dimension: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 0.8),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onPressed,
                  child: Center(
                    child: Icon(
                      icon,
                      size: AppDimensions.iconSM,
                      color: fgColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
