import 'package:adaptive_foreground/flutter_adaptive_foreground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdaptiveNavBar Widget Tests', () {
    final testItems = [
      const AdaptiveNavBarItem(icon: Icons.today, label: 'Today'),
      const AdaptiveNavBarItem(icon: Icons.rocket_launch, label: 'Games'),
      const AdaptiveNavBarItem(icon: Icons.layers, label: 'Apps'),
    ];

    testWidgets('renders all items with correct labels and icons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(
              child: Stack(
                children: [
                  const SizedBox(height: 500),
                  AdaptiveNavBar(
                    items: testItems,
                    currentIndex: 0,
                    onTap: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify all labels are displayed
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Games'), findsOneWidget);
      expect(find.text('Apps'), findsOneWidget);

      // Verify icons are present
      expect(find.byIcon(Icons.today), findsOneWidget);
      expect(find.byIcon(Icons.rocket_launch), findsOneWidget);
      expect(find.byIcon(Icons.layers), findsOneWidget);
    });

    testWidgets('tap triggers onTap callback with correct index', (tester) async {
      int? tappedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(
              child: Stack(
                children: [
                  const SizedBox(height: 500),
                  AdaptiveNavBar(
                    items: testItems,
                    currentIndex: 0,
                    onTap: (index) {
                      tappedIndex = index;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Tap on the second item ('Games')
      await tester.tap(find.text('Games'));
      await tester.pump();

      expect(tappedIndex, equals(1));
    });

    testWidgets('active tab uses accentColor and semibold weight', (tester) async {
      const activeColor = Colors.orange;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(
              child: Stack(
                children: [
                  const SizedBox(height: 500),
                  AdaptiveNavBar(
                    items: testItems,
                    currentIndex: 1, // 'Games' is active
                    accentColor: activeColor,
                    onTap: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Resolve the text style for the active label 'Games'
      final activeTextWidget = tester.widget<AnimatedDefaultTextStyle>(
        find.descendant(
          of: find.ancestor(
            of: find.text('Games'),
            matching: find.byType(GestureDetector),
          ),
          matching: find.byType(AnimatedDefaultTextStyle),
        ).first,
      );

      expect(activeTextWidget.style.color, equals(activeColor));
      expect(activeTextWidget.style.fontWeight, equals(FontWeight.w600));

      // Resolve the text style for the inactive label 'Today'
      final inactiveTextWidget = tester.widget<AnimatedDefaultTextStyle>(
        find.descendant(
          of: find.ancestor(
            of: find.text('Today'),
            matching: find.byType(GestureDetector),
          ),
          matching: find.byType(AnimatedDefaultTextStyle),
        ).first,
      );

      expect(inactiveTextWidget.style.fontWeight, equals(FontWeight.w400));
    });
  });

  group('AdaptiveTheme Color Mappings', () {
    test('resolves correct properties for dark background', () {
      final theme = AdaptiveTheme.resolve(const Color(0xFF1A1A2E), 0.05);

      expect(theme.brightness, equals(Brightness.dark));
      expect(theme.tintColor, equals(Colors.black.withValues(alpha: 0.15)));
      expect(theme.inactiveColor, equals(Colors.white.withValues(alpha: 0.5)));
      expect(theme.activePillColor, equals(Colors.white.withValues(alpha: 0.1)));
    });

    test('resolves correct properties for light neutral background', () {
      final theme = AdaptiveTheme.resolve(Colors.white, 1.0);

      expect(theme.brightness, equals(Brightness.light));
      expect(theme.tintColor, equals(Colors.white.withValues(alpha: 0.15)));
      expect(theme.inactiveColor, equals(Colors.black.withValues(alpha: 0.5)));
      expect(theme.activePillColor, equals(Colors.black.withValues(alpha: 0.05)));
    });

    test('resolves warm peach overlay for warm background colors', () {
      // Saturated bright warm color (orange/red)
      const warmColor = Color(0xFFFFB74D);
      final theme = AdaptiveTheme.resolve(warmColor, warmColor.computeLuminance());

      expect(theme.brightness, equals(Brightness.light));
      expect(theme.tintColor, equals(warmColor.withValues(alpha: 0.15)));
    });
  });
}
