import 'dart:async';

import 'package:adaptive_foreground/adaptive_foreground.dart';
import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureSystemUI();

  runApp(const AdaptiveForegroundExampleApp());
}

Future<void> _configureSystemUI() async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  if (defaultTargetPlatform == TargetPlatform.android) {
    // Edge-to-edge: app draws behind status bar and navigation bar.
    // Required for a truly transparent status bar on Android.
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  } else {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  // Baseline transparent style — AppAdaptiveForeground will control icon brightness.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
  ));
}

// ── App ───────────────────────────────────────────────────────────────────────

class AdaptiveForegroundExampleApp extends StatelessWidget {
  const AdaptiveForegroundExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adaptive Foreground',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlueAccent),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lightBlueAccent,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const ColorPlaygroundPage(),
    );
  }
}

// ── Color Playground ──────────────────────────────────────────────────────────

/// A vertical [PageView] of solid-color backgrounds.
///
/// As the user swipes, [AppAdaptiveForeground] samples the backdrop and
/// switches the AppBar's icon and title color between black and white
/// automatically — no manual color logic needed.
class ColorPlaygroundPage extends StatefulWidget {
  const ColorPlaygroundPage({super.key});

  @override
  State<ColorPlaygroundPage> createState() => _ColorPlaygroundPageState();
}

class _ColorPlaygroundPageState extends State<ColorPlaygroundPage> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _PageData(
      color: Color(0xFF1A1A2E),
      label: 'Interactive Demo',
      description: 'Swipe vertically or tap the bottom tab bar. Watch the action buttons, status bar, and tab bar elements adapt dynamically to the screen backdrop.',
    ),
    _PageData(
      color: Color(0xFFE94560),
      label: 'Luminance & Contrast',
      description: 'Automatically calculates background color luminance. Switches contrast between dark and light foregrounds in real-time to guarantee WCAG accessibility.',
    ),
    _PageData(
      color: Color(0xFF2D6A4F),
      label: 'Glassmorphism Material',
      description: 'Utilizes high-fidelity Gaussian blurs and translucent borders. The bottom navigation bar adapts its surface opacity and inactive element tints seamlessly.',
    ),
    _PageData(
      color: Color(0xFFFFD700),
      label: 'Real-Time Performance',
      description: 'Avoids heavy snapshot loops by employing direct background color mapping. Renders smoothly at 120 FPS even when running alongside native platform views.',
    ),
    _PageData(
      color: Color(0xFFFFFFFF),
      label: 'Package Documentation',
      description: 'Complete drop-in solution for modern adaptiveness. Standardized barrel exports, customizable threshold settings, and native observer integrations.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _pages[_currentPage].color;

    return AppAdaptiveForeground(
      updateStatusBar: true,
      backgroundColorHint: activeColor,
      child: Builder(
        builder: (context) {
          final adaptiveColor = AppAdaptiveForeground.of(context);

          return Scaffold(
            backgroundColor: Colors.transparent,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              // Explicitly propagate the adaptive style so the AppBar's inner
              // AnnotatedRegion doesn't override AppAdaptiveForeground's outer one.
              systemOverlayStyle: AppAdaptiveForeground.systemStyleOf(context),
              leading: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
                child: AppButtonIosAndroid(
                  symbol: 'xmark',
                  icon: Icons.close,
                  buttonSize: AppDimensions.iconMD,
                  color: adaptiveColor,
                  onPressed: () {},
                ),
              ),
              title: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: adaptiveColor,
                      fontWeight: FontWeight.w600,
                    ),
                child: const Text('Adaptive Foreground'),
              ),
              actions: [
                AppButtonIosAndroid(
                  symbol: 'square.and.arrow.up',
                  icon: Icons.share_outlined,
                  color: adaptiveColor,
                  onPressed: () {},
                ),
                const SizedBox(width: 6),
                AppButtonIosAndroid(
                  symbol: 'info.circle',
                  icon: Icons.info_outline,
                  color: adaptiveColor,
                  onPressed: _showInfo,
                ),
                const SizedBox(width: 12),
              ],
            ),
            body: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: _pages.length,
                  itemBuilder: (_, i) => _BackgroundTile(page: _pages[i]),
                ),
                // Vertical page-dot indicator
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: _VerticalDots(
                    current: _currentPage,
                    total: _pages.length,
                    color: adaptiveColor,
                  ),
                ),
                // Apple App Store glassy bottom tab bar
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: defaultTargetPlatform == TargetPlatform.iOS
                      ? CNTabBar(
                          items: const [
                            CNTabBarItem(
                              label: 'Demo',
                              icon: CNSymbol('sparkles'),
                            ),
                            CNTabBarItem(
                              label: 'Contrast',
                              icon: CNSymbol('circle.lefthalf.filled'),
                            ),
                            CNTabBarItem(
                              label: 'Glass',
                              icon: CNSymbol('square.stack.3d.up'),
                            ),
                            CNTabBarItem(
                              label: 'Metrics',
                              icon: CNSymbol('chart.bar.xaxis'),
                            ),
                            CNTabBarItem(
                              label: 'Docs',
                              icon: CNSymbol('doc.text'),
                            ),
                          ],
                          currentIndex: _currentPage,
                          onTap: (index) {
                            setState(() => _currentPage = index);
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                          },
                        )
                      : AdaptiveNavBar(
                          items: const [
                            AdaptiveNavBarItem(icon: Icons.auto_awesome, label: 'Demo'),
                            AdaptiveNavBarItem(icon: Icons.contrast, label: 'Contrast'),
                            AdaptiveNavBarItem(icon: Icons.layers, label: 'Glass'),
                            AdaptiveNavBarItem(icon: Icons.bar_chart, label: 'Metrics'),
                            AdaptiveNavBarItem(icon: Icons.description, label: 'Docs'),
                          ],
                          currentIndex: _currentPage,
                          onTap: (index) {
                            setState(() => _currentPage = index);
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                          },
                          accentColor: Colors.blue,
                          blurSigma: 20.0,
                          adaptationThreshold: 0.5,
                          animationDuration: const Duration(milliseconds: 250),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showInfo() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _InfoSheet(),
    );
  }
}

// ── Background Tile ───────────────────────────────────────────────────────────

class _PageData {
  final Color color;
  final String label;
  final String description;
  const _PageData({required this.color, required this.label, required this.description});
}

class _BackgroundTile extends StatelessWidget {
  const _BackgroundTile({required this.page});

  final _PageData page;

  @override
  Widget build(BuildContext context) {
    final adaptiveColor = AppAdaptiveForeground.of(context);
    final luminance = page.color.computeLuminance();
    final isBright = luminance > 0.5;

    return Container(
      color: page.color,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Swipe hint
                Icon(
                  Icons.swap_vert,
                  size: 32,
                  color: adaptiveColor.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 24),

                // Color label
                Text(
                  page.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: adaptiveColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),

                // Description text related to the package and features
                Text(
                  page.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: adaptiveColor.withValues(alpha: 0.75),
                    fontSize: 14,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 28),

                // Luminance reading
                Text(
                  'Luminance  ${luminance.toStringAsFixed(3)}',
                  style: TextStyle(
                    color: adaptiveColor.withValues(alpha: 0.65),
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 24),

                // Adaptive foreground badge
                _AdaptiveBadge(
                  label: isBright ? 'Dark foreground' : 'Light foreground',
                  color: adaptiveColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdaptiveBadge extends StatelessWidget {
  const _AdaptiveBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── Vertical Dot Indicator ────────────────────────────────────────────────────

class _VerticalDots extends StatelessWidget {
  const _VerticalDots({
    required this.current,
    required this.total,
    required this.color,
  });

  final int current;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        total,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(vertical: 3),
          width: 6,
          height: i == current ? 18 : 6,
          decoration: BoxDecoration(
            color: color.withValues(alpha: i == current ? 1.0 : 0.35),
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          ),
        ),
      ),
    );
  }
}

// ── Info Sheet ────────────────────────────────────────────────────────────────

class _InfoSheet extends StatelessWidget {
  const _InfoSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'adaptive_foreground',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Swipe vertically to change the background. '
            'The AppBar title, icons, and status-bar style update '
            'automatically — no manual color management.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          const _InfoRow('Strategy', 'Backdrop sampling (RepaintBoundary)'),
          const _InfoRow('Sampling interval', '150 ms'),
          const _InfoRow('Luminance threshold', '0.5'),
          const _InfoRow('Transition duration', '300 ms'),
          const _InfoRow('Status-bar sync', 'Enabled'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(
            '$label:  ',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
