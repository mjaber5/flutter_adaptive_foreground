# adaptive_foreground

[![pub.dev](https://img.shields.io/pub/v/adaptive_foreground.svg)](https://pub.dev/packages/adaptive_foreground)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-≥3.27-blue.svg)](https://flutter.dev)

Adaptive foreground color and glassy navigation bar for Flutter. Includes:
1. **`AppAdaptiveForeground`**: Automatically selects the highest-contrast foreground color — **black or white** — based on the luminance of the rendered background.
2. **`AdaptiveNavBar`**: A pixel-perfect, pure Flutter replica of Apple App Store's adaptive bottom navigation bar system. It reads the content scrolling beneath it, adapting its surface blur, label tint, and active highlight pills dynamically.

<p align="center">
  <img src="https://raw.githubusercontent.com/mjaber5/flutter_adaptive_foreground/main/assets/demo.gif" alt="adaptive_foreground demo" width="320"/>
</p>

---

## Features

| Feature | Details |
|---|---|
| **Luminance Backdrop Sampling** | Periodically captures low-res snapshots (0.1 scale) of a `RepaintBoundary` to calculate exact average colors and luminance behind the bar, preventing performance drop. |
| **Surface Adaptation** | Dynamically shifts frosted glass overlays (dark tint, light tint, or warm blend) depending on background HSL values. |
| **Contrast & Tint Flipping** | Automatically flips active/inactive label weights and color contrasts for maximum WCAG readability. |
| **Vibrancy & Frosted Glass** | Pure Flutter layout utilising `BackdropFilter` and `ImageFilter.blur(sigmaX: 20, sigmaY: 20)` overlay with micro-thin adaptive borders. |
| **Status-bar Sync** | Automatically syncs `SystemUiOverlayStyle` brightness flags. |
| **Debounced Sampling** | Limits sampling interval to 100ms+ and runs smooth 250ms curve transitions to prevent visual flickers. |

---

## Installation

```yaml
dependencies:
  adaptive_foreground: ^0.0.2
```

```dart
import 'package:adaptive_foreground/flutter_adaptive_foreground.dart';
```

---

## Quick start

Wrap your app root inside a `RepaintBoundary` with a `GlobalKey`, then pass
that key to `AppAdaptiveForeground` for live pixel sampling:

```dart
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
        child: const MyApp(),
      ),
    ),
  );
}
```

Read the resolved color anywhere below in the tree:

```dart
final foreground = AppAdaptiveForeground.of(context);        // Color
final background = AppAdaptiveForeground.backgroundColorOf(context); // Color
final style      = AppAdaptiveForeground.systemStyleOf(context);     // SystemUiOverlayStyle
```

### 2 — `AdaptiveNavBar` Quick Start

To use the Apple App Store style navigation bar, arrange your screen with a `Stack` where the scrollable list is in the background and the `AdaptiveNavBar` sits at the bottom:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      children: [
        // Ensure scrollable content is wrapped in a RepaintBoundary
        RepaintBoundary(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(height: 500, color: Colors.black),
                Container(height: 500, color: Colors.white),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: AdaptiveNavBar(
            items: const [
              AdaptiveNavBarItem(icon: Icons.today, label: 'Today'),
              AdaptiveNavBarItem(icon: Icons.rocket_launch, label: 'Games'),
              AdaptiveNavBarItem(icon: Icons.layers, label: 'Apps'),
              AdaptiveNavBarItem(icon: Icons.sports_esports, label: 'Arcade'),
              AdaptiveNavBarItem(icon: Icons.search, label: 'Search'),
            ],
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            accentColor: Colors.blue,
          ),
        ),
      ],
    ),
  );
}
```

---

## Adaptive Behavior Rules

| Backdrop State | Sampled Value | Frosted Surface Material | Inactive Labels / Symbols | Active Item Highlight |
|---|---|---|---|---|
| **Dark content** | Luminance < 0.5 | Translucent dark overlay `(Opacity 15% black)` | Translucent white `(Opacity 50%)` | Filled accent color + Subtle dark pill background |
| **Light content** | Luminance ≥ 0.5 | Translucent white overlay `(Opacity 15% white)` | Translucent black `(Opacity 50%)` | Filled accent color + Subtle light pill background |
| **Warm content** | Warm hue range | Translucent warm overlay `(Opacity 15% warm)` | Translucent black `(Opacity 50%)` | Filled accent color + Subtle light pill background |
| **Neutral gray** | Saturation = 0.0 | Neutral gray blur layer | Slate black `(Opacity 50%)` | Filled accent color + Subtle light pill background |

---

## Strategies

### 1 — `backgroundColorHint` (instant)

Best when you know the background color at build time (e.g. a solid `Scaffold`
background):

```dart
AppAdaptiveForeground(
  backgroundColorHint: Colors.deepPurple,
  child: const MyPage(),
)
```

### 2 — `samplingKey` + `enableBackdropSampling` (live)

Best for dynamic backgrounds (images, gradients, hero animations). Wrap the
outermost widget in a `RepaintBoundary` and pass its key:

```dart
final GlobalKey rootRepaintKey = GlobalKey();

RepaintBoundary(
  key: rootRepaintKey,
  child: AppAdaptiveForeground(
    enableBackdropSampling: true,
    samplingKey: rootRepaintKey,
    updateStatusBar: true,
    child: const MyApp(),
  ),
)
```

---

## API reference

### `AppAdaptiveForeground`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `child` | `Widget` | required | Widget subtree to wrap. |
| `backgroundColorHint` | `Color?` | `null` | Known background color for instant luminance calculation. |
| `samplingKey` | `GlobalKey?` | `null` | Key of a `RepaintBoundary` to sample pixels from. |
| `enableBackdropSampling` | `bool` | `false` | Enables periodic pixel sampling. |
| `samplingInterval` | `Duration` | `150 ms` | Sampling frequency. |
| `darkColor` | `Color` | `Colors.black` | Foreground for bright backgrounds. |
| `lightColor` | `Color` | `Colors.white` | Foreground for dark backgrounds. |
| `threshold` | `double` | `0.5` | Luminance threshold for dark/light switching. |
| `hysteresis` | `double` | `0.08` | Dead zone around `threshold` that prevents oscillation. Switch to bright only when luminance > `threshold + hysteresis`; switch to dark only when luminance < `threshold - hysteresis`. |
| `sampleLocalArea` | `bool` | `true` | Sample only the widget's own area vs. the top strip (status-bar region). |
| `updateStatusBar` | `bool` | `false` | Write the resolved style to `SystemUiOverlayStyle`. |
| `systemOverlayStyle` | `SystemUiOverlayStyle?` | `null` | Manual override for the resolved overlay style. |

#### Static accessors

```dart
// Resolved foreground color (black or white)
Color color = AppAdaptiveForeground.of(context);

// Resolved semi-transparent background tint
Color bg = AppAdaptiveForeground.backgroundColorOf(context);

// Resolved SystemUiOverlayStyle
SystemUiOverlayStyle style = AppAdaptiveForeground.systemStyleOf(context);
```

---

### `AdaptiveNavBar`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `items` | `List<AdaptiveNavBarItem>` | required | List of tabs to display in the navigation bar. |
| `currentIndex` | `int` | required | Index of the active tab. |
| `onTap` | `ValueChanged<int>` | required | Triggered when a tab gets tapped. |
| `accentColor` | `Color` | `Colors.blue` | Highlights the active item's icon, text, and active badge. |
| `blurSigma` | `double` | `20.0` | Background Gaussian frosted blur standard deviation strength. |
| `adaptationThreshold` | `double` | `0.5` | Threshold mapping between light/dark backdrops. |
| `animationDuration` | `Duration` | `250 ms` | Duration for smooth cross-fading color shifts. |
| `onDebugUpdate` | `Function?` | `null` | Invoked with real-time statistics (luminance, avg color, brightness, opacity) for debug overlays. |

---

### `AdaptiveNavBarItem`

Contains tab data models:
- **`icon`** (`IconData`): Tab icon graphics.
- **`label`** (`String`): Text label drawn under the icon.

---

### `AppButtonIosAndroid`

A circular action button that adapts to the current platform.

```dart
AppButtonIosAndroid(
  symbol: 'square.and.arrow.up',   // SF Symbol — iOS only
  icon: Icons.share_outlined,       // Material icon — Android
  color: AppAdaptiveForeground.of(context),
  onPressed: _share,
)
```

| Parameter | Type | Description |
|---|---|---|
| `symbol` | `String?` | SF Symbol name (**required on iOS**). |
| `icon` | `IconData?` | Material icon (used on Android & other platforms). |
| `onPressed` | `VoidCallback?` | Tap callback. Pass `null` to disable. |
| `color` | `Color?` | Tint / foreground color. |
| `isOutline` | `bool` | Renders an outline variant on Android. |
| `buttonSize` | `double?` | Custom size (defaults to `AppDimensions.iconXL - 6`). |

---

## System UI configuration

A recommended `_configureSystemUI` for apps using this package:

```dart
Future<void> _configureSystemUI() async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final overlays = defaultTargetPlatform == TargetPlatform.android
      ? const <SystemUiOverlay>[SystemUiOverlay.top]
      : SystemUiOverlay.values;

  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: overlays,
  );
}
```

---

## Example app

See the fully-worked example in [`example/lib/main.dart`](example/lib/main.dart).

To run it:

```bash
cd example
flutter create --project-name adaptive_foreground_example . # adds platform folders
flutter run
```

---

## License

[MIT](LICENSE) © 2026 Mohammed Jaber

---

## Author

**Mohammed Jaber**

[![GitHub](https://img.shields.io/badge/GitHub-mjaber5-181717?logo=github)](https://github.com/mjaber5)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Mohammad%20Jaber-0077B5?logo=linkedin)](https://www.linkedin.com/in/mohammad-jaber-profile/)
[![Email](https://img.shields.io/badge/Email-mhammdjbr555%40gmail.com-EA4335?logo=gmail)](mailto:mhammdjbr555@gmail.com)
