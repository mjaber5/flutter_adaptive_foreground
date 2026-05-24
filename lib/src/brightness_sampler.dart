import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Captures and computes background colors and luminance from a rendering boundary.
///
/// Ensures debouncing and utilizes low-resolution (0.1 scale) snapshots to
/// prevent frame drops and keep background tracking highly performant.
class BrightnessSampler {
  /// The luminance switch point threshold. Defaults to 0.5.
  final double threshold;

  /// The minimum delay interval required between two consecutive captures.
  final Duration minInterval;

  DateTime? _lastSampleTime;
  bool _isSampling = false;

  /// Constructs a [BrightnessSampler] with customizable [threshold] and [minInterval].
  BrightnessSampler({
    this.threshold = 0.5,
    this.minInterval = const Duration(milliseconds: 100),
  });

  /// Captures the region of the nearest [RenderRepaintBoundary] behind the given [context].
  ///
  /// The height of the bottom sampling area can be configured via [bottomHeight].
  /// Returns a [SampleResult] or `null` if debounced or capture fails.
  Future<SampleResult?> sample(BuildContext context, {double bottomHeight = 80.0}) async {
    final now = DateTime.now();
    if (_lastSampleTime != null && now.difference(_lastSampleTime!) < minInterval) {
      return null;
    }

    if (_isSampling) return null;
    _isSampling = true;
    _lastSampleTime = now;

    try {
      final boundary = context.findAncestorRenderObjectOfType<RenderRepaintBoundary>();
      final localBox = context.findRenderObject() as RenderBox?;

      if (boundary == null || localBox == null || !localBox.attached || !localBox.hasSize) {
        _isSampling = false;
        return null;
      }

      if (boundary.debugNeedsPaint) {
        _isSampling = false;
        return null;
      }

      // Compute coordinate mappings between local box and ancestor boundary
      final globalOffset = localBox.localToGlobal(Offset.zero);
      final boundaryGlobalOffset = boundary.localToGlobal(Offset.zero);
      final localOffset = globalOffset - boundaryGlobalOffset;
      final localSize = localBox.size;

      // Extract raw image representation in 10% resolution
      const double scale = 0.1;
      final image = await boundary.toImage(pixelRatio: scale);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

      if (byteData == null) {
        image.dispose();
        _isSampling = false;
        return null;
      }

      // Map local boundaries to the low-resolution scaled grid
      final left = (localOffset.dx * scale).toInt().clamp(0, image.width - 1);
      final top = (localOffset.dy * scale).toInt().clamp(0, image.height - 1);
      final width = (localSize.width * scale).toInt().clamp(1, image.width - left);
      final sampleHeight = (bottomHeight * scale).toInt().clamp(1, image.height - top);

      int r = 0, g = 0, b = 0, count = 0;
      final bytesPerRow = image.width * 4;

      for (int y = top; y < top + sampleHeight; y++) {
        for (int x = left; x < left + width; x++) {
          final offset = (y * bytesPerRow) + (x * 4);
          if (offset + 3 < byteData.lengthInBytes) {
            final rawR = byteData.getUint8(offset);
            final rawG = byteData.getUint8(offset + 1);
            final rawB = byteData.getUint8(offset + 2);
            final alpha = byteData.getUint8(offset + 3);

            final double a = alpha / 255.0;
            // Blend with white for empty/transparent canvas sections
            r += (rawR * a + 255 * (1 - a)).toInt();
            g += (rawG * a + 255 * (1 - a)).toInt();
            b += (rawB * a + 255 * (1 - a)).toInt();
            count++;
          }
        }
      }

      image.dispose();
      _isSampling = false;

      if (count > 0) {
        final avgR = r ~/ count;
        final avgG = g ~/ count;
        final avgB = b ~/ count;
        final avgColor = Color.fromARGB(255, avgR, avgG, avgB);
        final luminance = avgColor.computeLuminance();
        return SampleResult(luminance: luminance, avgColor: avgColor);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('BrightnessSampler error: $e');
      }
    }

    _isSampling = false;
    return null;
  }
}

/// Wraps the calculated average colors and luminance values.
class SampleResult {
  /// The average luminance of the sampled pixels, scaled between `0.0` and `1.0`.
  final double luminance;

  /// The average color computed from the sampled pixels.
  final Color avgColor;

  /// Immutable snapshot data for a boundary capture.
  const SampleResult({required this.luminance, required this.avgColor});
}
