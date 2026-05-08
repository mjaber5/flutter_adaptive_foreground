import 'package:adaptive_foreground/src/widgets/app_dimensions.dart';
import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/material.dart';

/// A native iOS action button backed by [CNButton.icon] from
/// the `cupertino_native` package.
///
/// Only rendered on iOS — use [AppButtonIosAndroid] for a cross-platform
/// button that automatically falls back to a Material style on Android.
class AppIosButton extends StatelessWidget {
  const AppIosButton({
    super.key,
    required this.onPressed,
    required this.symbol,
    this.color,
    this.style,
    this.size,
  });

  /// SF Symbol name (e.g. `'square.and.arrow.up'`).
  final String symbol;

  /// Called when the button is tapped. Pass `null` to disable.
  final VoidCallback? onPressed;

  /// Tint colour applied to the symbol and button glass.
  final Color? color;

  /// Visual style. Defaults to [CNButtonStyle.prominentGlass].
  final CNButtonStyle? style;

  /// Tap-target size. Defaults to `AppDimensions.iconXL - 4`.
  final double? size;

  @override
  Widget build(BuildContext context) {
    return CNButton.icon(
      size: size ?? AppDimensions.iconXL - 4,
      tint: color,
      style: style ?? CNButtonStyle.prominentGlass,
      icon: CNSymbol(symbol, size: AppDimensions.iconXS + 2),
      onPressed: onPressed,
    );
  }
}
