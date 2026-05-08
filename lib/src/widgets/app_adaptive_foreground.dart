import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// A widget that provides an adaptive foreground color (Black/White)
/// based on background luminance.
///
/// Supports two strategies:
/// 1. [backgroundColorHint]: Direct luminance calculation (Fast).
/// 2. [samplingKey]: Backdrop sampling via [RepaintBoundary] (Advanced/Throttled).
class AppAdaptiveForeground extends StatefulWidget {
  final Widget child;
  final Color? backgroundColorHint;
  final GlobalKey? samplingKey;
  final bool enableBackdropSampling;
  final Duration samplingInterval;
  final Color darkColor;
  final Color lightColor;
  final double threshold;

  /// Dead zone on either side of [threshold] that prevents oscillation when
  /// the sampled luminance hovers near the switch point.
  ///
  /// Switch to bright (dark fg) only when luminance > threshold + hysteresis.
  /// Switch to dark  (light fg) only when luminance < threshold - hysteresis.
  ///
  /// Defaults to `0.08`, which is wide enough to absorb the luminance
  /// contribution of white status-bar icons captured in the sampled pixels
  /// without making the switch feel sluggish.
  final double hysteresis;

  const AppAdaptiveForeground({
    super.key,
    required this.child,
    this.backgroundColorHint,
    this.samplingKey,
    this.enableBackdropSampling = false,
    this.samplingInterval = const Duration(milliseconds: 150),
    this.darkColor = Colors.black,
    this.lightColor = Colors.white,
    this.threshold = 0.5,
    this.hysteresis = 0.08,
    this.sampleLocalArea = true,
    this.updateStatusBar = false,
    this.systemOverlayStyle,
  });

  final bool sampleLocalArea;
  final bool updateStatusBar;
  final SystemUiOverlayStyle? systemOverlayStyle;

  /// Access the current adaptive foreground color from descendants
  static Color of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<_AdaptiveColorScope>()
            ?.foregroundColor ??
        Colors.white;
  }

  /// Access the current adaptive background color from descendants
  static Color backgroundColorOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<_AdaptiveColorScope>()
            ?.backgroundColor ??
        Colors.black.withValues(alpha: 0.1);
  }

  /// Access the current system overlay style from descendants
  static SystemUiOverlayStyle systemStyleOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<_AdaptiveColorScope>()
            ?.systemStyle ??
        SystemUiOverlayStyle.light;
  }

  @override
  State<AppAdaptiveForeground> createState() => _AdaptiveForegroundState();
}

class _AdaptiveForegroundState extends State<AppAdaptiveForeground> {
  Color _currentForegroundColor = Colors.white;
  Color _currentBackgroundColor = Colors.black.withValues(alpha: 0.1);
  Timer? _samplingTimer;
  bool _initialized = false;

  // Tracks the current bright/dark state for hysteresis.
  // Null = not yet decided (first sample will set it unconditionally).
  bool? _isBright;

  @override
  void initState() {
    super.initState();
    // We defer color initialization to didChangeDependencies to access Theme
    if (widget.enableBackdropSampling) {
      _startSampling();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initializeColors();
      _initialized = true;
    }
  }

  void _initializeColors() {
    if (widget.backgroundColorHint != null) {
      _updateColorFromHint();
      return;
    }

    // Default to Theme contrast if no hint (safe fallback).
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;

    // Light theme (white BG) → dark icons; dark theme (dark BG) → light icons.
    _isBright = !isDarkTheme;
    _currentForegroundColor =
        _isBright! ? widget.darkColor : widget.lightColor;
    _currentBackgroundColor = _isBright!
        ? Colors.black.withValues(alpha: 0.2)
        : Colors.white.withValues(alpha: 0.25);

    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(AppAdaptiveForeground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.backgroundColorHint != oldWidget.backgroundColorHint) {
      _isBright = null; // reset so next call decides unconditionally
      _updateColorFromHint();
    }

    if (widget.enableBackdropSampling != oldWidget.enableBackdropSampling) {
      if (widget.enableBackdropSampling) {
        _startSampling();
      } else {
        _stopSampling();
      }
    }
  }

  @override
  void dispose() {
    _stopSampling();
    super.dispose();
  }

  void _updateColors(double luminance) {
    // Hysteresis: require luminance to cross (threshold ± hysteresis) before
    // switching states. This prevents oscillation when the sampled region
    // contains rendered overlay icons (e.g. white status-bar icons on a
    // mid-range background colour) that shift the average luminance near the
    // threshold and would otherwise cause an infinite flip-flop loop.
    final bool newIsBright;
    if (_isBright == null) {
      // First sample — decide unconditionally.
      newIsBright = luminance > widget.threshold;
    } else if (_isBright!) {
      // Currently bright → stay bright unless luminance drops well below threshold.
      newIsBright = luminance >= (widget.threshold - widget.hysteresis);
    } else {
      // Currently dark → stay dark unless luminance rises well above threshold.
      newIsBright = luminance > (widget.threshold + widget.hysteresis);
    }

    if (newIsBright == _isBright) return; // no state change needed

    _isBright = newIsBright;
    final targetForeground =
        newIsBright ? widget.darkColor : widget.lightColor;
    final targetBackground = newIsBright
        ? Colors.black.withValues(alpha: 0.2)
        : Colors.white.withValues(alpha: 0.25);

    if (mounted) {
      setState(() {
        _currentForegroundColor = targetForeground;
        _currentBackgroundColor = targetBackground;
      });
    }
  }

  void _updateColorFromHint() {
    if (widget.backgroundColorHint != null) {
      final luminance = widget.backgroundColorHint!.computeLuminance();
      _updateColors(luminance);
    }
  }

  void _startSampling() {
    _samplingTimer?.cancel();
    // Immediate first sample
    WidgetsBinding.instance.addPostFrameCallback((_) => _sampleBackdrop());
    _samplingTimer = Timer.periodic(
      widget.samplingInterval,
      (_) => _sampleBackdrop(),
    );
  }

  void _stopSampling() {
    _samplingTimer?.cancel();
    _samplingTimer = null;
  }

  Future<void> _sampleBackdrop() async {
    if (widget.samplingKey == null || !mounted) return;

    try {
      final boundary =
          widget.samplingKey!.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      final localBox = context.findRenderObject() as RenderBox?;

      if (boundary == null) return;
      if (boundary.debugNeedsPaint) return;

      if (localBox == null || !localBox.attached || !localBox.hasSize) {
        return;
      }

      // Find position of this widget relative to the sampling boundary
      final globalOffset = localBox.localToGlobal(Offset.zero);
      final boundaryGlobalOffset = boundary.localToGlobal(Offset.zero);
      final localOffset = globalOffset - boundaryGlobalOffset;
      final localSize = localBox.size;

      // Sample image with low resolution
      final image = await boundary.toImage(pixelRatio: 0.1);

      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );

      if (!mounted) {
        image.dispose();
        return;
      }

      if (byteData != null) {
        const scale = 0.1;

        int left = (localOffset.dx * scale).toInt().clamp(0, image.width - 1);
        int top = (localOffset.dy * scale).toInt().clamp(0, image.height - 1);
        int width = (localSize.width * scale).toInt().clamp(
          1,
          image.width - left,
        );
        int height = (localSize.height * scale).toInt().clamp(
          1,
          image.height - top,
        );

        // If not sampling local area OR if we are updating status bar,
        // we should sample from the very top to ensure we hit the status bar area.
        if (!widget.sampleLocalArea || widget.updateStatusBar) {
          left = 0;
          width = image.width;
          height = (image.height * 0.15).toInt().clamp(1, image.height);
          top = 0;
        }

        int r = 0, g = 0, b = 0, count = 0;
        final bytesPerRow = image.width * 4;

        // Fallback color (Scaffold background) for transparent pixels
        // Safe to access context here because we checked mounted above
        final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
        final bgR = (scaffoldBg.r * 255.0).round();
        final bgG = (scaffoldBg.g * 255.0).round();
        final bgB = (scaffoldBg.b * 255.0).round();

        for (int y = top; y < top + height; y++) {
          for (int x = left; x < left + width; x++) {
            final offset = (y * bytesPerRow) + (x * 4);
            final rawR = byteData.getUint8(offset);
            final rawG = byteData.getUint8(offset + 1);
            final rawB = byteData.getUint8(offset + 2);
            final alpha = byteData.getUint8(offset + 3);

            // Simple alpha blending to handle transparent backgrounds
            final a = alpha / 255.0;

            r += (rawR * a + bgR * (1 - a)).toInt();
            g += (rawG * a + bgG * (1 - a)).toInt();
            b += (rawB * a + bgB * (1 - a)).toInt();
            count++;
          }
        }

        image.dispose();

        if (count > 0) {
          final avgR = r ~/ count;
          final avgG = g ~/ count;
          final avgB = b ~/ count;
          final luminance = (0.299 * avgR + 0.587 * avgG + 0.114 * avgB) / 255;

          _updateColors(luminance);
        }
      } else {
        image.dispose();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AppAdaptiveForeground: Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      duration: const Duration(milliseconds: 300),
      tween: ColorTween(end: _currentForegroundColor),
      builder: (context, foreground, _) {
        final fg = foreground ?? _currentForegroundColor;
        return TweenAnimationBuilder<Color?>(
          duration: const Duration(milliseconds: 300),
          tween: ColorTween(end: _currentBackgroundColor),
          builder: (context, background, _) {
            final bg = background ?? _currentBackgroundColor;

            // isDarkForeground=true  → fg is black → background is bright
            //   → need dark status-bar icons
            // isDarkForeground=false → fg is white → background is dark
            //   → need light status-bar icons
            //
            // IMPORTANT: use inline `const` so Dart canonicalises both branches
            // into the same object reference when values are unchanged.
            // _AdaptiveColorScope.updateShouldNotify uses != (reference check on
            // non-overriding classes), so non-const .copyWith() objects would
            // always be "different" and trigger endless rebuilds.
            final isDarkForeground = fg.computeLuminance() < 0.5;
            final currentStyle = isDarkForeground
                ? const SystemUiOverlayStyle(
                    statusBarColor: Colors.transparent,
                    statusBarIconBrightness: Brightness.dark,
                    statusBarBrightness: Brightness.light,
                  )
                : const SystemUiOverlayStyle(
                    statusBarColor: Colors.transparent,
                    statusBarIconBrightness: Brightness.light,
                    statusBarBrightness: Brightness.dark,
                  );

            return _AdaptiveColorScope(
              foregroundColor: fg,
              backgroundColor: bg,
              systemStyle: currentStyle,
              child: widget.updateStatusBar
                  ? AnnotatedRegion<SystemUiOverlayStyle>(
                      value: currentStyle,
                      child: widget.child,
                    )
                  : widget.child,
            );
          },
        );
      },
    );
  }
}

class _AdaptiveColorScope extends InheritedWidget {
  final Color foregroundColor;
  final Color backgroundColor;
  final SystemUiOverlayStyle systemStyle;

  const _AdaptiveColorScope({
    required this.foregroundColor,
    required this.backgroundColor,
    required this.systemStyle,
    required super.child,
  });

  @override
  bool updateShouldNotify(_AdaptiveColorScope oldWidget) {
    return foregroundColor != oldWidget.foregroundColor ||
        backgroundColor != oldWidget.backgroundColor ||
        systemStyle != oldWidget.systemStyle;
  }
}
