/// Adaptive foreground color package for Flutter.
///
/// Wrap your app (or any sub-tree) with [AppAdaptiveForeground] to
/// automatically select the highest-contrast foreground color (black or white)
/// based on the luminance of the rendered background.
///
/// ```dart
/// final GlobalKey rootRepaintKey = GlobalKey();
///
/// void main() {
///   runApp(
///     RepaintBoundary(
///       key: rootRepaintKey,
///       child: AppAdaptiveForeground(
///         updateStatusBar: true,
///         enableBackdropSampling: true,
///         samplingKey: rootRepaintKey,
///         child: const MyApp(),
///       ),
///     ),
///   );
/// }
/// ```
///
/// Then read the resolved color anywhere in the tree:
/// ```dart
/// final color = AppAdaptiveForeground.of(context);
/// ```
library;

export 'src/widgets/app_adaptive_foreground.dart';
export 'src/widgets/app_button_ios_android.dart';
export 'src/widgets/app_dimensions.dart';
export 'src/widgets/app_ios_button.dart';
