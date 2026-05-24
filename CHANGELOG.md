# Changelog

All notable changes to this project will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.0.3] - 2026-05-24

### Added
- `AdaptiveNavBar` widget — a pixel-perfect, pure-Flutter replica of the Apple App Store's adaptive frosted glass bottom navigation bar.
- `CNSymbol` and `CNTabBar` integrations from `cupertino_native` inside the example application to show authentic platform tab bars on iOS.
- Dynamic `AdaptiveTheme` resolving surface blurs, inactive elements tints, dynamic active highlight pills, and micro-thin top borders.
- Isolated, low-resolution pixel sampling in `BrightnessSampler` with debouncing (> 100ms) and smooth transitions (250ms curve).
- Dedicated widget and unit test coverage in `test/adaptive_nav_bar_test.dart` asserting correct rendering, taps, and theme color maps.

### Fixed
- Relocated `AppAdaptiveForeground` context inside `ColorPlaygroundPage` using direct background color hint mapping, completely bypassing fragile screen captures and resolving Platform View compositing conflicts on iOS.
- Restored explicit `tint: color` on iOS native buttons to ensure native visual glass effects adapt dynamically to contrast state.
- Upgraded Android circular action buttons to implement high-performance `BackdropFilter` glassmorphism blurs and `AnimatedContainer` transitions matching iOS tab bar aesthetics.
- Custom-themed all example swiper pages and bottom tab items (Demo, Contrast, Glass, Metrics, Docs) to focus entirely on showcasing package features and guides.

---

## [0.0.2] - 2026-05-08

### Fixed
- Shortened `pubspec.yaml` description to satisfy the pub.dev 180-character limit.
- Added dartdoc comments to all public API fields (`AppAdaptiveForeground`,
  `AppButtonIosAndroid`, `AppIosButton`) to exceed the 20 % documentation threshold.

---

## [0.0.1] - 2026-05-08

### Added
- `AppAdaptiveForeground` widget — adaptive black/white foreground color based on
  background luminance, with smooth 300 ms `ColorTween` transitions.
- Hysteresis (`hysteresis` parameter, default `0.08`) prevents status-bar icon
  oscillation when sampled luminance hovers near the switching threshold.
- Two sampling strategies: `backgroundColorHint` (instant) and live backdrop
  sampling via a `RepaintBoundary` `samplingKey`.
- `updateStatusBar` flag to keep `SystemUiOverlayStyle` in sync automatically.
- Static accessors: `AppAdaptiveForeground.of`, `backgroundColorOf`, `systemStyleOf`.
- `AppButtonIosAndroid` — cross-platform circular action button (native iOS
  `CNButton` on iOS, Material `InkWell` circle on Android).
- `AppIosButton` — thin wrapper over `cupertino_native`'s `CNButton.icon`.
- `AppDimensions` — lightweight sizing constants (no external scaling library).
- MIT License.
