# Changelog

All notable changes to this project will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
