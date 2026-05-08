import 'dart:async';

import 'package:adaptive_foreground/adaptive_foreground.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Root repaint boundary key — passed to [AppAdaptiveForeground] so it can
/// sample the actual rendered pixels for luminance calculation.
final GlobalKey rootRepaintKey = GlobalKey();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureSystemUI();

  runApp(
    RepaintBoundary(
      key: rootRepaintKey,
      child: AppAdaptiveForeground(
        updateStatusBar: true,
        enableBackdropSampling: true,
        samplingKey: rootRepaintKey,
        child: const AdaptiveForegroundExampleApp(),
      ),
    ),
  );
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
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
    _PageData(color: Color(0xFF1A1A2E), label: 'Deep Navy'),
    _PageData(color: Color(0xFF0F3460), label: 'Navy Blue'),
    _PageData(color: Color(0xFFE94560), label: 'Coral Red'),
    _PageData(color: Color(0xFF2D6A4F), label: 'Forest Green'),
    _PageData(color: Color(0xFFFFD700), label: 'Gold'),
    _PageData(color: Color(0xFF00B4D8), label: 'Ocean Blue'),
    _PageData(color: Color(0xFF90E0EF), label: 'Sky Blue'),
    _PageData(color: Color(0xFFF5F5F5), label: 'Off White'),
    _PageData(color: Color(0xFFFFFFFF), label: 'Pure White'),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Read the resolved adaptive color — rebuilds whenever it changes.
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
        ],
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
  const _PageData({required this.color, required this.label});
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
                style: TextStyle(
                  color: adaptiveColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),

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
