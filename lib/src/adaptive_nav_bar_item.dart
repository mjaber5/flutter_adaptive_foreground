import 'package:flutter/widgets.dart';

/// Represents a single item inside the [AdaptiveNavBar].
class AdaptiveNavBarItem {
  /// The icon data to display in the tab item.
  final IconData icon;

  /// The human-readable label text displayed underneath the icon.
  final String label;

  /// Creates an immutable [AdaptiveNavBarItem] specifying the [icon] and [label].
  const AdaptiveNavBarItem({
    required this.icon,
    required this.label,
  });
}
