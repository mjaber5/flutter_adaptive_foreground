import 'package:flutter/material.dart';
import 'adaptive_theme.dart';

/// Manages and isolates color selection for individual elements on the tab bar.
///
/// Ensures inactive elements shift colors dynamically based on the active
/// [AdaptiveTheme], while selected elements preserve their brand accenting.
class TintController {
  /// The active brand accent/brand highlight color.
  final Color accentColor;

  /// The dynamic [AdaptiveTheme] providing active and inactive color hints.
  final AdaptiveTheme theme;

  /// Constructs a [TintController] bound to a specific [accentColor] and [theme].
  const TintController({
    required this.accentColor,
    required this.theme,
  });

  /// Returns the color to paint the tab elements (symbols, labels) given the item's [isActive] state.
  Color getItemColor({required bool isActive}) {
    return isActive ? accentColor : theme.inactiveColor;
  }

  /// Returns the background filling tint for the active pill selector.
  Color getPillColor() {
    return theme.activePillColor;
  }
}
