import 'dart:async';
import 'package:flutter/material.dart';
import 'adaptive_nav_bar_item.dart';
import 'adaptive_theme.dart';
import 'blur_surface.dart';
import 'brightness_sampler.dart';
import 'tint_controller.dart';

/// A pure-Flutter pixel-perfect replica of the Apple App Store's adaptive bottom navigation bar.
///
/// Features dynamic glassmorphism blurs, automatic active/inactive label tint flipping,
/// dynamic background-matching accent color active indicators, and debounced pixel-sampling.
class AdaptiveNavBar extends StatefulWidget {
  /// The list of items to display as tabs.
  final List<AdaptiveNavBarItem> items;

  /// The index of the currently active/selected tab.
  final int currentIndex;

  /// Callback invoked when a tab is tapped.
  final ValueChanged<int> onTap;

  /// The brand color used for active icon highlight and text (defaults to [Colors.blue]).
  final Color accentColor;

  /// The standard deviation of the Gaussian blur applied to the backdrop (defaults to 20.0).
  final double blurSigma;

  /// The luminance switch point boundary (defaults to 0.5).
  final double adaptationThreshold;

  /// The duration of the color-tint shifting animation transition (defaults to 250ms).
  final Duration animationDuration;

  /// Optional callback invoked when backdrop pixels are sampled.
  ///
  /// Passes real-time statistics (luminance, average color, current brightness state, and tint opacity)
  /// for rendering toggleable debug dashboards.
  final void Function(
    double luminance,
    Color avgColor,
    Brightness brightness,
    double tintOpacity,
  )? onDebugUpdate;

  /// Creates a pixel-perfect [AdaptiveNavBar].
  const AdaptiveNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.accentColor = Colors.blue,
    this.blurSigma = 20.0,
    this.adaptationThreshold = 0.5,
    this.animationDuration = const Duration(milliseconds: 250),
    this.onDebugUpdate,
  });

  @override
  State<AdaptiveNavBar> createState() => _AdaptiveNavBarState();
}

class _AdaptiveNavBarState extends State<AdaptiveNavBar> {
  late final BrightnessSampler _sampler;
  AdaptiveTheme? _currentTheme;
  Color _avgColor = Colors.white;
  double _luminance = 1.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sampler = BrightnessSampler(
      threshold: widget.adaptationThreshold,
    );
    _startSampling();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_currentTheme == null) {
      final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
      _avgColor = isDarkTheme ? Colors.black : Colors.white;
      _luminance = isDarkTheme ? 0.0 : 1.0;
      _currentTheme = AdaptiveTheme.resolve(
        _avgColor,
        _luminance,
        threshold: widget.adaptationThreshold,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startSampling() {
    _timer?.cancel();
    // Run periodically at a 120ms interval to handle both debouncing (> 100ms) and dynamic updates
    _timer = Timer.periodic(const Duration(milliseconds: 120), (_) => _doSample());
  }

  Future<void> _doSample() async {
    if (!mounted) return;
    final result = await _sampler.sample(context, bottomHeight: 80.0);
    if (result != null && mounted) {
      final nextTheme = AdaptiveTheme.resolve(
        result.avgColor,
        result.luminance,
        threshold: widget.adaptationThreshold,
      );

      setState(() {
        _avgColor = result.avgColor;
        _luminance = result.luminance;
        _currentTheme = nextTheme;
      });

      if (widget.onDebugUpdate != null) {
        widget.onDebugUpdate!(
          _luminance,
          _avgColor,
          nextTheme.brightness,
          nextTheme.tintColor.a,
        );
      }
    }
  }

  Widget _buildTabItem({
    required int index,
    required AdaptiveNavBarItem item,
    required TintController controller,
  }) {
    final isActive = index == widget.currentIndex;
    final itemColor = controller.getItemColor(isActive: isActive);

    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Subtle adaptively colored pill container highlighting the active tab
              AnimatedContainer(
                duration: widget.animationDuration,
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? controller.getPillColor() : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  item.icon,
                  color: itemColor,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              // Text label with semibold weight for active, regular weight for inactive
              AnimatedDefaultTextStyle(
                duration: widget.animationDuration,
                curve: Curves.easeInOut,
                style: TextStyle(
                  color: itemColor,
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  letterSpacing: -0.2,
                ),
                child: Text(item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _currentTheme ??
        AdaptiveTheme.resolve(
          _avgColor,
          _luminance,
          threshold: widget.adaptationThreshold,
        );
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    // Smoothly animate each theme property over the specified animationDuration
    return TweenAnimationBuilder<Color?>(
      duration: widget.animationDuration,
      curve: Curves.easeInOut,
      tween: ColorTween(end: theme.tintColor),
      builder: (context, tintColor, _) {
        return TweenAnimationBuilder<Color?>(
          duration: widget.animationDuration,
          curve: Curves.easeInOut,
          tween: ColorTween(end: theme.inactiveColor),
          builder: (context, inactiveColor, _) {
            return TweenAnimationBuilder<Color?>(
              duration: widget.animationDuration,
              curve: Curves.easeInOut,
              tween: ColorTween(end: theme.activePillColor),
              builder: (context, pillColor, _) {
                return TweenAnimationBuilder<Color?>(
                  duration: widget.animationDuration,
                  curve: Curves.easeInOut,
                  tween: ColorTween(end: theme.topBorderColor),
                  builder: (context, topBorderColor, _) {
                    final animatedTheme = AdaptiveTheme(
                      brightness: theme.brightness,
                      tintColor: tintColor ?? theme.tintColor,
                      inactiveColor: inactiveColor ?? theme.inactiveColor,
                      activePillColor: pillColor ?? theme.activePillColor,
                      topBorderColor: topBorderColor ?? theme.topBorderColor,
                    );

                    final controller = TintController(
                      accentColor: widget.accentColor,
                      theme: animatedTheme,
                    );

                    return BlurSurface(
                      blurSigma: widget.blurSigma,
                      tintColor: animatedTheme.tintColor,
                      topBorderColor: animatedTheme.topBorderColor,
                      child: SafeArea(
                        top: false,
                        bottom: false,
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: 8.0,
                            bottom: 8.0 + bottomPadding,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: List.generate(
                              widget.items.length,
                              (i) => _buildTabItem(
                                index: i,
                                item: widget.items[i],
                                controller: controller,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
