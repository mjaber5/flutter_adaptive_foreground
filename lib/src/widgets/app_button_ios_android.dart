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
    final backgroundColor = isOutline
        ? Colors.transparent
        : color ?? colorScheme.surfaceContainerHighest;
    final foregroundColor = isOutline
        ? color ?? colorScheme.primary
        : _foregroundFor(backgroundColor, colorScheme);
    final borderColor = isOutline
        ? foregroundColor.withValues(alpha: 0.35)
        : colorScheme.onSurface.withValues(alpha: 0.1);

    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: SizedBox.square(
        dimension: size,
        child: Material(
          color: backgroundColor,
          shape: CircleBorder(side: BorderSide(color: borderColor)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Icon(
              icon,
              size: AppDimensions.iconSM,
              color: foregroundColor,
            ),
          ),
        ),
      ),
    );
  }

  Color _foregroundFor(Color bg, ColorScheme colorScheme) {
    if (bg == colorScheme.primary) return colorScheme.onPrimary;
    if (bg == colorScheme.surfaceContainerHighest || bg == colorScheme.surface) {
      return colorScheme.onSurface;
    }
    return bg.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }
}
