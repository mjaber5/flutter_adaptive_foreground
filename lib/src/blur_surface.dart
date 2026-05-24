import 'dart:ui';
import 'package:flutter/material.dart';

/// Renders a frosted-glass surface using hardware-accelerated background blurs.
///
/// Features dynamic color tints and fine border outlines overlaid on top of the
/// blurred elements to ensure sleek glassmorphism aesthetics.
class BlurSurface extends StatelessWidget {
  /// The amount of blur to apply to the content beneath the navigation bar.
  final double blurSigma;

  /// The color overlaid on top of the blurred content.
  final Color tintColor;

  /// An optional divider outline color drawn at the top edge of the surface container.
  final Color? topBorderColor;

  /// The child elements to display on top of this visual frosted surface.
  final Widget child;

  /// Constructs a [BlurSurface] containing specific styling properties.
  const BlurSurface({
    super.key,
    required this.blurSigma,
    required this.tintColor,
    required this.child,
    this.topBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: tintColor,
            border: topBorderColor != null
                ? Border(
                    top: BorderSide(
                      color: topBorderColor!,
                      width: 0.5,
                    ),
                  )
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
