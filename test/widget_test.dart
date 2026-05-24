import 'package:adaptive_foreground/adaptive_foreground.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppAdaptiveForeground', () {
    testWidgets('renders its child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppAdaptiveForeground(
            child: Text('hello'),
          ),
        ),
      );
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('returns dark foreground for bright backgroundColorHint',
        (tester) async {
      Color? captured;

      await tester.pumpWidget(
        MaterialApp(
          home: AppAdaptiveForeground(
            backgroundColorHint: Colors.white, // luminance = 1.0
            child: Builder(builder: (ctx) {
              captured = AppAdaptiveForeground.of(ctx);
              return const SizedBox.shrink();
            }),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(captured, equals(Colors.black));
    });

    testWidgets('returns light foreground for dark backgroundColorHint',
        (tester) async {
      Color? captured;

      await tester.pumpWidget(
        MaterialApp(
          home: AppAdaptiveForeground(
            backgroundColorHint: const Color(0xFF000000), // luminance = 0.0
            child: Builder(builder: (ctx) {
              captured = AppAdaptiveForeground.of(ctx);
              return const SizedBox.shrink();
            }),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(captured, equals(Colors.white));
    });

    testWidgets('custom threshold is respected', (tester) async {
      Color? captured;

      // Mid-grey luminance ≈ 0.216. With threshold = 0.1 it is "bright",
      // so the dark foreground (Colors.black) should be returned.
      await tester.pumpWidget(
        MaterialApp(
          home: AppAdaptiveForeground(
            backgroundColorHint: const Color(0xFF808080),
            threshold: 0.1,
            child: Builder(builder: (ctx) {
              captured = AppAdaptiveForeground.of(ctx);
              return const SizedBox.shrink();
            }),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(captured, equals(Colors.black));
    });

    testWidgets('custom darkColor and lightColor are used', (tester) async {
      Color? captured;
      const myDark = Color(0xFF333333);

      await tester.pumpWidget(
        MaterialApp(
          home: AppAdaptiveForeground(
            backgroundColorHint: Colors.white,
            darkColor: myDark,
            child: Builder(builder: (ctx) {
              captured = AppAdaptiveForeground.of(ctx);
              return const SizedBox.shrink();
            }),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(captured, equals(myDark));
    });

    testWidgets('backgroundColorOf returns a non-null color', (tester) async {
      Color? bg;

      await tester.pumpWidget(
        MaterialApp(
          home: AppAdaptiveForeground(
            backgroundColorHint: Colors.white,
            child: Builder(builder: (ctx) {
              bg = AppAdaptiveForeground.backgroundColorOf(ctx);
              return const SizedBox.shrink();
            }),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(bg, isNotNull);
    });

    testWidgets('systemStyleOf returns light style for bright background',
        (tester) async {
      SystemUiOverlayStyle? style;

      await tester.pumpWidget(
        MaterialApp(
          home: AppAdaptiveForeground(
            backgroundColorHint: Colors.white,
            child: Builder(builder: (ctx) {
              style = AppAdaptiveForeground.systemStyleOf(ctx);
              return const SizedBox.shrink();
            }),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Bright background → dark icons → SystemUiOverlayStyle.light
      expect(
        style?.statusBarIconBrightness,
        equals(Brightness.dark),
      );
    });

    testWidgets('updates when backgroundColorHint changes', (tester) async {
      Color hint = Colors.white;
      Color? captured;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (_, setState) => MaterialApp(
            home: AppAdaptiveForeground(
              backgroundColorHint: hint,
              child: Builder(builder: (ctx) {
                captured = AppAdaptiveForeground.of(ctx);
                return TextButton(
                  onPressed: () => setState(() => hint = Colors.black),
                  child: const Text('toggle'),
                );
              }),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(captured, equals(Colors.black)); // bright bg → dark fg

      await tester.tap(find.text('toggle'));
      await tester.pumpAndSettle();
      expect(captured, equals(Colors.white)); // dark bg → light fg
    });

    testWidgets('dynamic HSL-based tinted color returned for saturated backgrounds', (tester) async {
      Color? captured;

      await tester.pumpWidget(
        MaterialApp(
          home: AppAdaptiveForeground(
            backgroundColorHint: const Color(0xFF0F3460), // Navy Blue (dark background)
            child: Builder(builder: (ctx) {
              captured = AppAdaptiveForeground.of(ctx);
              return const SizedBox.shrink();
            }),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // For Navy Blue, it should return a beautiful ice-blue tinted light color
      expect(captured, isNot(equals(Colors.white)));
      expect(captured?.computeLuminance(), greaterThan(0.8));
    });
  });
}
